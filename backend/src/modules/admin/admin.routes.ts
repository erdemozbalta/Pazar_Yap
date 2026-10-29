import { Router } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import prisma from '../../config/database';

const router = Router();
const SALT_ROUNDS = 12;

router.use(authenticate, requireRole('ADMIN'));

router.get('/stats', async (_req, res) => {
  try {
    const [
      totalCustomers,
      totalCouriers,
      totalEmployees,
      totalOrders,
      deliveredOrders,
      totalMarkets,
      activeOrders,
    ] = await Promise.all([
      prisma.user.count({ where: { role: 'CUSTOMER' } }),
      prisma.user.count({ where: { role: 'COURIER' } }),
      prisma.user.count({ where: { role: 'EMPLOYEE' } }),
      prisma.order.count(),
      prisma.order.count({ where: { status: 'DELIVERED' } }),
      prisma.market.count(),
      prisma.order.count({
        where: {
          status: {
            in: ['PAYMENT_PENDING', 'SEARCHING_COURIER', 'COURIER_ASSIGNED', 'SHOPPING_IN_PROGRESS', 'ON_THE_WAY'],
          },
        },
      }),
    ]);

    const revenue = await prisma.payment.aggregate({
      where: { status: 'COMPLETED' },
      _sum: { amount: true },
    });

    const topProducts = await prisma.orderItem.groupBy({
      by: ['vendorProductId'],
      _sum: { quantity: true },
      orderBy: { _sum: { quantity: 'desc' } },
      take: 10,
    });

    const recentOrders = await prisma.order.findMany({
      take: 10,
      orderBy: { createdAt: 'desc' },
      include: {
        customer: { select: { firstName: true, lastName: true } },
        market: { select: { name: true } },
      },
    });

    res.json({
      overview: {
        totalCustomers,
        totalCouriers,
        totalEmployees,
        totalOrders,
        deliveredOrders,
        totalMarkets,
        activeOrders,
        totalRevenue: revenue._sum.amount || 0,
      },
      topProducts,
      recentOrders,
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/users', async (req, res) => {
  try {
    const { role, search, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);

    let where: any = {};
    if (role && typeof role === 'string' && role.trim().length > 0) {
      where.role = role.trim();
    }
    if (search) {
      where.OR = [
        { firstName: { contains: search } },
        { lastName: { contains: search } },
        { email: { contains: search } },
        { phone: { contains: search } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          phone: true,
          firstName: true,
          lastName: true,
          role: true,
          isActive: true,
          phoneVerified: true,
          emailVerified: true,
          createdAt: true,
          createdByAdmin: {
            select: { firstName: true, lastName: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit as string),
      }),
      prisma.user.count({ where }),
    ]);

    res.json({
      users,
      pagination: {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        total,
        totalPages: Math.ceil(total / parseInt(limit as string)),
      },
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/users/:id/toggle', async (req: AuthRequest, res) => {
  try {
    if (req.user!.id === (req.params.id as string)) {
      res.status(400).json({ error: 'Kendi admin hesabınızı devre dışı bırakamazsınız' });
      return;
    }
    const user = await prisma.user.findUnique({ where: { id: req.params.id as string } });
    if (!user) {
      res.status(404).json({ error: 'Kullanıcı bulunamadı' });
      return;
    }

    const updated = await prisma.user.update({
      where: { id: req.params.id as string },
      data: { isActive: !user.isActive },
      select: { id: true, firstName: true, lastName: true, isActive: true },
    });

    res.json({
      message: updated.isActive ? 'Hesap aktifleştirildi' : 'Hesap devre dışı bırakıldı',
      user: updated,
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/users/:id', async (req: AuthRequest, res) => {
  try {
    const userId = req.params.id as string;
    if (req.user!.id === userId) {
      res.status(400).json({ error: 'Kendi admin hesabınızı silemezsiniz' });
      return;
    }
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      res.status(404).json({ error: 'Kullanıcı bulunamadı' });
      return;
    }

    try {
      await prisma.$transaction([
        prisma.courierProfile.deleteMany({ where: { userId } }),
        prisma.notification.deleteMany({ where: { userId } }),
        prisma.address.deleteMany({ where: { userId } }),
        prisma.user.delete({ where: { id: userId } }),
      ]);
    } catch (_err) {
      await prisma.user.update({
        where: { id: userId },
        data: { isActive: false },
      });
    }

    res.json({ message: 'Kullanıcı/Çalışan başarıyla silindi' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

const createStaffSchema = z.object({
  email: z.string().email('Geçerli bir e-posta giriniz'),
  phone: z.string().min(10, 'Telefon en az 10 karakter olmalıdır'),
  password: z.string().min(8, 'Şifre en az 8 karakter olmalıdır'),
  firstName: z.string().min(2, 'Ad en az 2 karakter olmalıdır'),
  lastName: z.string().min(2, 'Soyad en az 2 karakter olmalıdır'),
  role: z.enum(['EMPLOYEE', 'ADMIN']),
  pin: z.string().length(6).nullable().optional().or(z.literal('')),
});

router.post('/staff', validate(createStaffSchema), async (req: AuthRequest, res) => {
  try {
    const { email, phone, password, firstName, lastName, role, pin } = req.body;

    if (role === 'ADMIN' && !pin) {
      res.status(400).json({ error: 'Admin hesabı için PIN gereklidir' });
      return;
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    let adminPinHash: string | null = null;
    if (pin) {
      adminPinHash = await bcrypt.hash(pin, SALT_ROUNDS);
    }

    const user = await prisma.user.create({
      data: {
        email,
        phone: phone.startsWith('+90') ? phone : `+90${phone.replace(/\D/g, '')}`,
        passwordHash,
        firstName,
        lastName,
        role,
        adminPinHash,
        createdByAdminId: req.user!.id,
        isActive: true,
        phoneVerified: 'VERIFIED',
        emailVerified: 'VERIFIED',
      },
      select: {
        id: true,
        email: true,
        phone: true,
        firstName: true,
        lastName: true,
        role: true,
        createdAt: true,
      },
    });

    res.status(201).json({
      message: `${role === 'ADMIN' ? 'Admin' : 'Çalışan'} hesabı oluşturuldu`,
      user,
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

const assignmentSchema = z.object({
  employeeId: z.string().min(1),
  marketId: z.string().min(1),
});

router.post('/assignments', validate(assignmentSchema), async (req: AuthRequest, res) => {
  try {
    const assignment = await prisma.employeeAssignment.create({
      data: {
        employeeId: req.body.employeeId,
        marketId: req.body.marketId,
        assignedById: req.user!.id,
      },
      include: {
        employee: { select: { firstName: true, lastName: true } },
        market: { select: { name: true } },
      },
    });
    res.status(201).json({ message: 'Çalışan atandı', assignment });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/orders', async (req, res) => {
  try {
    const { status, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);

    let where: any = {};
    if (status) where.status = status;

    const [orders, total] = await Promise.all([
      prisma.order.findMany({
        where,
        include: {
          customer: { select: { firstName: true, lastName: true, phone: true } },
          courier: { select: { firstName: true, lastName: true, phone: true } },
          market: { select: { name: true } },
          payment: { select: { status: true, amount: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit as string),
      }),
      prisma.order.count({ where }),
    ]);

    res.json({
      orders,
      pagination: {
        page: parseInt(page as string),
        limit: parseInt(limit as string),
        total,
        totalPages: Math.ceil(total / parseInt(limit as string)),
      },
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/payments', async (req, res) => {
  try {
    const { status, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);

    let where: any = {};
    if (status) where.status = status;

    const [payments, total] = await Promise.all([
      prisma.payment.findMany({
        where,
        include: {
          order: {
            select: {
              orderNumber: true,
              customer: { select: { firstName: true, lastName: true } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit as string),
      }),
      prisma.payment.count({ where }),
    ]);

    res.json({ payments, pagination: { page: parseInt(page as string), limit: parseInt(limit as string), total, totalPages: Math.ceil(total / parseInt(limit as string)) } });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

export default router;

