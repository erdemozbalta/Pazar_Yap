import { Router } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { z } from 'zod';
import prisma from '../../config/database';
import { OrderStatus } from '@prisma/client';
import { calculateDistance, generateOrderNumber, calculateCourierFee } from '../../utils/helpers';
import { getPaymentProvider } from '../../services/payment';

const router = Router();

const createOrderSchema = z.object({
  addressId: z.string({ required_error: 'Teslimat adresi gereklidir' }).min(1, 'Teslimat adresi gereklidir'),
  notes: z.any().optional(),
  autoAssignCourier: z.any().optional(),
});

router.post(
  '/checkout-preview',
  authenticate,
  requireRole('CUSTOMER'),
  async (req: AuthRequest, res) => {
    try {
      const { addressId } = req.body;

      const cart = await prisma.cart.findFirst({
        where: { userId: req.user!.id, isActive: true },
        include: {
          market: true,
          items: {
            include: {
              vendorProduct: { include: { product: true } },
            },
          },
        },
      });

      if (!cart || cart.items.length === 0) {
        res.status(400).json({ error: 'Sepetiniz boş' });
        return;
      }

      let address = addressId
        ? await prisma.address.findFirst({ where: { id: addressId, userId: req.user!.id } })
        : null;

      if (!address) {
        address = await prisma.address.findFirst({
          where: { userId: req.user!.id },
          orderBy: { isDefault: 'desc' },
        });
      }

      function getItemWeightKg(item: any): number {
        const unit = (item.vendorProduct?.unit || item.vendorProduct?.product?.unit || '').toLowerCase();
        if (unit.includes('demet')) {
          return 0;
        } else if (unit.includes('paket') || unit.includes('adet')) {
          return item.quantity * 0.2;
        }
        return item.quantity;
      }

      let subtotal = 0;
      let totalWeight = 0;
      for (const item of cart.items) {
        subtotal += item.quantity * item.vendorProduct.price;
        totalWeight += getItemWeightKg(item);
      }
      subtotal = parseFloat(subtotal.toFixed(2));
      totalWeight = parseFloat(totalWeight.toFixed(2));

      let distanceKm = 0;
      if (address && cart.market.latitude && cart.market.longitude && address.latitude && address.longitude) {
        distanceKm = calculateDistance(
          cart.market.latitude,
          cart.market.longitude,
          address.latitude,
          address.longitude
        );
      } else {
        distanceKm = 2.5;
      }

      const availableCourier = await prisma.courierProfile.findFirst({
        where: {
          selectedMarketId: cart.marketId,
          isAvailable: true,
        },
        include: {
          user: { select: { id: true, firstName: true, lastName: true } },
          distanceTiers: { orderBy: { sortOrder: 'asc' } },
          weightTiers: { orderBy: { sortOrder: 'asc' } },
        },
      });

      let courierFee = 0;
      const hasAvailableCourier = !!availableCourier;

      if (availableCourier) {
        const baseFeeToUse = availableCourier.baseFee > 0 ? availableCourier.baseFee : 100;
        courierFee = calculateCourierFee(
          baseFeeToUse,
          distanceKm,
          totalWeight,
          availableCourier.distanceTiers,
          availableCourier.weightTiers
        );
        if (courierFee <= 0) courierFee = 100;
      }

      const serviceFee = parseFloat((subtotal * 0.05).toFixed(2));
      const totalAmount = parseFloat((subtotal + (hasAvailableCourier ? courierFee : 0) + serviceFee).toFixed(2));

      res.json({
        hasAvailableCourier,
        marketId: cart.marketId,
        marketName: cart.market.name,
        subtotal,
        serviceFee,
        totalWeightKg: totalWeight,
        distanceKm,
        courierFee: hasAvailableCourier ? courierFee : 0,
        totalAmount,
        courierName: availableCourier ? `${availableCourier.user.firstName} ${availableCourier.user.lastName}` : null,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.post(
  '/',
  authenticate,
  requireRole('CUSTOMER'),
  validate(createOrderSchema),
  async (req: AuthRequest, res) => {
    try {
      const { addressId, notes, autoAssignCourier } = req.body;

      const cart = await prisma.cart.findFirst({
        where: { userId: req.user!.id, isActive: true },
        include: {
          market: true,
          items: {
            include: {
              vendorProduct: {
                include: { product: true },
              },
            },
          },
        },
      });

      if (!cart || cart.items.length === 0) {
        res.status(400).json({ error: 'Sepetiniz boş' });
        return;
      }

      let address = await prisma.address.findFirst({
        where: { id: addressId, userId: req.user!.id },
      });
      if (!address) {
        address = await prisma.address.findFirst({
          where: { userId: req.user!.id },
          orderBy: { isDefault: 'desc' },
        });
      }
      if (!address) {
        res.status(400).json({ error: 'Lütfen hesabınıza geçerli bir teslimat adresi ekleyiniz.' });
        return;
      }

      let subtotal = 0;
      let totalWeight = 0;
      const orderItems = cart.items.map((item) => {
        const itemTotal = item.quantity * item.vendorProduct.price;
        subtotal += itemTotal;
        const unit = (item.vendorProduct?.unit || item.vendorProduct?.product?.unit || '').toLowerCase();
        if (unit.includes('demet')) {

        } else if (unit.includes('paket') || unit.includes('adet')) {
          totalWeight += item.quantity * 0.2;
        } else {
          totalWeight += item.quantity;
        }
        return {
          vendorProductId: item.vendorProductId,
          quantity: item.quantity,
          unitPrice: item.vendorProduct.price,
          totalPrice: parseFloat(itemTotal.toFixed(2)),
          note: item.note ?? null,
        };
      });

      const distanceKm = calculateDistance(
        cart.market.latitude,
        cart.market.longitude,
        address.latitude,
        address.longitude
      );

      const availableCourier = await prisma.courierProfile.findFirst({
        where: {
          selectedMarketId: cart.marketId,
          isAvailable: true,
        },
        include: {
          user: { select: { id: true, firstName: true, lastName: true } },
          distanceTiers: { orderBy: { sortOrder: 'asc' } },
          weightTiers: { orderBy: { sortOrder: 'asc' } },
        },
      });

      if (!availableCourier) {
        res.status(400).json({ error: 'Şu an bu pazarda sipariş alabilecek aktif bir kurye bulunmamaktadır.' });
        return;
      }

      const baseFeeToUse = availableCourier.baseFee > 0 ? availableCourier.baseFee : 100;
      let courierFee = calculateCourierFee(
        baseFeeToUse,
        distanceKm,
        totalWeight,
        availableCourier.distanceTiers,
        availableCourier.weightTiers
      );
      if (courierFee <= 0) courierFee = 100;

      const courierId = availableCourier.user.id;
      const initialStatus: OrderStatus = 'PAYMENT_PENDING';

      subtotal = parseFloat(subtotal.toFixed(2));
      const serviceFee = parseFloat((subtotal * 0.05).toFixed(2));
      const totalAmount = parseFloat((subtotal + courierFee + serviceFee).toFixed(2));

      const order = await prisma.$transaction(async (tx) => {
        const newOrder = await tx.order.create({
          data: {
            orderNumber: generateOrderNumber(),
            customerId: req.user!.id,
            courierId,
            marketId: cart.marketId,
            addressId,
            status: initialStatus,
            subtotal,
            courierFee,
            serviceFee,
            totalAmount,
            totalWeight: parseFloat(totalWeight.toFixed(2)),
            distanceKm,
            notes: notes ? (autoAssignCourier === false ? `[Otomatik Atama Kapalı] ${notes}` : notes) : (autoAssignCourier === false ? '[Otomatik Atama Kapalı]' : null),
            items: {
              create: orderItems,
            },
          },
          include: {
            items: {
              include: {
                vendorProduct: {
                  include: {
                    product: true,
                    vendor: { select: { id: true, name: true } },
                  },
                },
              },
            },
            market: { select: { id: true, name: true } },
            address: true,
          },
        });

        await tx.orderStatusHistory.create({
          data: {
            orderId: newOrder.id,
            toStatus: initialStatus,
            note: 'Sipariş oluşturuldu',
          },
        });

        await tx.cart.update({
          where: { id: cart.id },
          data: { isActive: false },
        });

        return newOrder;
      });

      await prisma.notification.create({
        data: {
          userId: req.user!.id,
          title: 'Sipariş Oluşturuldu',
          message: `${order.orderNumber} numaralı siparişiniz oluşturuldu. ${availableCourier ? 'Ödeme bekleniyor.' : 'Kurye aranıyor...'}`,
          type: 'order_update',
          data: JSON.stringify({ orderId: order.id }),
        },
      });

      res.status(201).json({
        message: 'Sipariş oluşturuldu',
        order,
        courierFee,
        totalAmount,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

const paymentSchema = z.object({
  orderId: z.string().uuid(),
  cardNumber: z.string().min(16).max(19),
  expireMonth: z.string().length(2),
  expireYear: z.string().min(2).max(4),
  cvc: z.string().min(3).max(4),
  cardHolderName: z.string().min(2),
});

router.post(
  '/pay',
  authenticate,
  requireRole('CUSTOMER'),
  validate(paymentSchema),
  async (req: AuthRequest, res) => {
    try {
      const { orderId, cardNumber, expireMonth, expireYear, cvc, cardHolderName } = req.body;

      const order = await prisma.order.findFirst({
        where: { id: orderId, customerId: req.user!.id },
      });

      if (!order) {
        res.status(404).json({ error: 'Sipariş bulunamadı' });
        return;
      }

      if (order.status !== 'PAYMENT_PENDING' && order.status !== 'SEARCHING_COURIER') {
        res.status(400).json({ error: 'Bu sipariş için ödeme yapılamaz' });
        return;
      }

      const paymentProvider = getPaymentProvider();
      const paymentResult = await paymentProvider.createPayment(
        order.totalAmount,
        'TRY',
        { cardNumber, expireMonth, expireYear, cvc, cardHolderName },
        { orderId: order.id, orderNumber: order.orderNumber }
      );

      await prisma.payment.create({
        data: {
          orderId: order.id,
          amount: order.totalAmount,
          status: paymentResult.success ? 'COMPLETED' : 'FAILED',
          providerRef: paymentResult.providerRef,
          providerName: paymentProvider.name,
          completedAt: paymentResult.success ? new Date() : null,
          errorMessage: paymentResult.success ? null : paymentResult.message,
        },
      });

      if (!paymentResult.success) {
        res.status(400).json({
          error: 'Ödeme başarısız',
          message: paymentResult.message,
        });
        return;
      }

      const newStatus: OrderStatus = order.courierId ? 'COURIER_ASSIGNED' : 'SEARCHING_COURIER';

      await prisma.$transaction(async (tx) => {
        await tx.order.update({
          where: { id: order.id },
          data: { status: newStatus },
        });

        await tx.orderStatusHistory.create({
          data: {
            orderId: order.id,
            fromStatus: order.status,
            toStatus: newStatus,
            note: 'Ödeme onaylandı',
          },
        });
      });

      if (order.courierId) {
        await prisma.notification.create({
          data: {
            userId: order.courierId,
            title: 'Yeni Sipariş',
            message: `${order.orderNumber} numaralı yeni bir sipariş atandı!`,
            type: 'order_update',
            data: JSON.stringify({ orderId: order.id }),
          },
        });
      }

      await prisma.notification.create({
        data: {
          userId: req.user!.id,
          title: 'Ödeme Onaylandı',
          message: `${order.orderNumber} numaralı siparişinizin ödemesi onaylandı.`,
          type: 'order_update',
          data: JSON.stringify({ orderId: order.id }),
        },
      });

      res.json({
        message: 'Ödeme başarılı',
        paymentId: paymentResult.paymentId,
        orderStatus: newStatus,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.get(
  '/courier/pending',
  authenticate,
  requireRole('COURIER'),
  async (req: AuthRequest, res) => {
    try {
      const profile = await prisma.courierProfile.findUnique({
        where: { userId: req.user!.id },
      });

      if (!profile || !profile.isAvailable) {
        res.json({ orders: [] });
        return;
      }

      const orders = await prisma.order.findMany({
        where: {
          OR: [
            { courierId: req.user!.id, status: { in: ['COURIER_ASSIGNED', 'SHOPPING_IN_PROGRESS', 'ON_THE_WAY'] } },
            { marketId: profile.selectedMarketId || '', status: 'SEARCHING_COURIER', courierId: null },
          ],
        },
        include: {
          customer: { select: { id: true, firstName: true, lastName: true, phone: true } },
          market: { select: { id: true, name: true } },
          address: true,
          items: {
            include: {
              vendorProduct: {
                include: {
                  product: true,
                  vendor: { select: { id: true, name: true } },
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      res.json({ orders });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.post(
  '/:id/accept',
  authenticate,
  requireRole('COURIER'),
  async (req: AuthRequest, res) => {
    try {
      const order = await prisma.order.findUnique({ where: { id: req.params.id as string } });

      if (!order || order.status !== 'SEARCHING_COURIER') {
        res.status(400).json({ error: 'Bu sipariş kabul edilemez' });
        return;
      }

      const profile = await prisma.courierProfile.findUnique({
        where: { userId: req.user!.id },
        include: {
          distanceTiers: true,
          weightTiers: true,
        },
      });

      if (!profile) {
        res.status(400).json({ error: 'Kurye profili bulunamadı' });
        return;
      }

      const courierFee = calculateCourierFee(
        profile.baseFee,
        order.distanceKm || 0,
        order.totalWeight,
        profile.distanceTiers,
        profile.weightTiers
      );

      await prisma.$transaction(async (tx) => {
        await tx.order.update({
          where: { id: order.id },
          data: {
            courierId: req.user!.id,
            courierFee,
            totalAmount: parseFloat((order.subtotal + courierFee).toFixed(2)),
            status: 'COURIER_ASSIGNED',
          },
        });

        await tx.orderStatusHistory.create({
          data: {
            orderId: order.id,
            fromStatus: order.status,
            toStatus: 'COURIER_ASSIGNED',
            note: `Kurye atandı`,
          },
        });
      });

      await prisma.notification.create({
        data: {
          userId: order.customerId,
          title: 'Kurye Atandı',
          message: `${order.orderNumber} numaralı siparişinize kurye atandı!`,
          type: 'order_update',
          data: JSON.stringify({ orderId: order.id }),
        },
      });

      res.json({ message: 'Sipariş kabul edildi' });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.post(
  '/:id/start-shopping',
  authenticate,
  requireRole('COURIER'),
  async (req: AuthRequest, res) => {
    try {
      const order = await prisma.order.findFirst({
        where: { id: req.params.id as string, courierId: req.user!.id, status: 'COURIER_ASSIGNED' },
      });
      if (!order) {
        res.status(400).json({ error: 'Geçersiz işlem' });
        return;
      }

      await prisma.$transaction(async (tx) => {
        await tx.order.update({
          where: { id: order.id },
          data: { status: 'SHOPPING_IN_PROGRESS' },
        });
        await tx.orderStatusHistory.create({
          data: {
            orderId: order.id,
            fromStatus: 'COURIER_ASSIGNED',
            toStatus: 'SHOPPING_IN_PROGRESS',
            note: 'Alışveriş başladı',
          },
        });
      });

      res.json({ message: 'Alışveriş başladı' });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.put(
  '/:id/items/:itemId/collect',
  authenticate,
  requireRole('COURIER'),
  async (req: AuthRequest, res) => {
    try {
      const order = await prisma.order.findFirst({
        where: {
          id: req.params.id as string,
          courierId: req.user!.id,
          status: { in: ['COURIER_ASSIGNED', 'SHOPPING_IN_PROGRESS'] },
        },
      });
      if (!order) {
        res.status(400).json({ error: 'Geçersiz işlem veya sipariş duruma uygun değil' });
        return;
      }

      const existingItem = await prisma.orderItem.findUnique({
        where: { id: req.params.itemId as string },
      });
      if (!existingItem) {
        res.status(400).json({ error: 'Ürün bulunamadı' });
        return;
      }

      const newCollectedState = !existingItem.isCollected;

      await prisma.$transaction(async (tx) => {
        await tx.orderItem.update({
          where: { id: req.params.itemId as string },
          data: { isCollected: newCollectedState },
        });

        if (order.status === 'COURIER_ASSIGNED') {
          await tx.order.update({
            where: { id: order.id },
            data: { status: 'SHOPPING_IN_PROGRESS' },
          });
          await tx.orderStatusHistory.create({
            data: {
              orderId: order.id,
              fromStatus: 'COURIER_ASSIGNED',
              toStatus: 'SHOPPING_IN_PROGRESS',
              note: 'Ürün toplanmaya başlandı',
            },
          });
        }
      });

      res.json({ message: 'Ürün toplama durumu güncellendi', isCollected: newCollectedState });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.post(
  '/:id/on-the-way',
  authenticate,
  requireRole('COURIER'),
  async (req: AuthRequest, res) => {
    try {
      const order = await prisma.order.findFirst({
        where: {
          id: req.params.id as string,
          courierId: req.user!.id,
          status: { in: ['SHOPPING_IN_PROGRESS', 'COURIER_ASSIGNED'] },
        },
        include: { items: true },
      });
      if (!order) {
        res.status(400).json({ error: 'Geçersiz işlem veya sipariş aktif durumda değil' });
        return;
      }

      const uncollected = order.items.filter((i) => !i.isCollected);
      if (uncollected.length > 0) {
        res.status(400).json({
          error: `${uncollected.length} ürün henüz toplanmadı`,
        });
        return;
      }

      await prisma.$transaction(async (tx) => {
        await tx.order.update({
          where: { id: order.id },
          data: { status: 'ON_THE_WAY' },
        });
        await tx.orderStatusHistory.create({
          data: {
            orderId: order.id,
            fromStatus: order.status,
            toStatus: 'ON_THE_WAY',
            note: 'Kurye yola çıktı',
          },
        });
      });

      await prisma.notification.create({
        data: {
          userId: order.customerId,
          title: 'Kurye Yola Çıktı! 🚀',
          message: `${order.orderNumber} numaralı siparişiniz yolda!`,
          type: 'order_update',
          data: JSON.stringify({ orderId: order.id }),
        },
      });

      res.json({ message: 'Yola çıkıldı, müşteri bilgilendirildi' });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.post(
  '/:id/deliver',
  authenticate,
  requireRole('COURIER'),
  async (req: AuthRequest, res) => {
    try {
      const order = await prisma.order.findFirst({
        where: {
          id: req.params.id as string,
          courierId: req.user!.id,
          status: { in: ['ON_THE_WAY', 'SHOPPING_IN_PROGRESS', 'COURIER_ASSIGNED'] },
        },
      });
      if (!order) {
        res.status(400).json({ error: 'Geçersiz işlem veya sipariş zaten tamamlanmış' });
        return;
      }

      await prisma.$transaction(async (tx) => {
        await tx.order.update({
          where: { id: order.id },
          data: { status: 'DELIVERED', deliveredAt: new Date() },
        });
        await tx.orderStatusHistory.create({
          data: {
            orderId: order.id,
            fromStatus: order.status,
            toStatus: 'DELIVERED',
            note: 'Teslimat tamamlandı',
          },
        });

        await tx.courierProfile.update({
          where: { userId: req.user!.id },
          data: {
            totalEarnings: { increment: order.courierFee },
            totalDeliveries: { increment: 1 },
          },
        });
      });

      await prisma.notification.create({
        data: {
          userId: order.customerId,
          title: 'Teslim Edildi ✅',
          message: `${order.orderNumber} numaralı siparişiniz teslim edildi. Afiyet olsun!`,
          type: 'order_update',
          data: JSON.stringify({ orderId: order.id }),
        },
      });

      res.json({ message: 'Teslimat tamamlandı' });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.post(
  '/:id/cancel',
  authenticate,
  async (req: AuthRequest, res) => {
    try {
      const whereCondition: any = { id: req.params.id as string };
      if (req.user!.role !== 'ADMIN') {
        whereCondition.OR = [
          { customerId: req.user!.id },
          { courierId: req.user!.id },
        ];
      }

      const order = await prisma.order.findFirst({ where: whereCondition });

      if (!order) {
        res.status(404).json({ error: 'Sipariş bulunamadı' });
        return;
      }

      const cancellableStatuses: OrderStatus[] = [
        'PAYMENT_PENDING',
        'SEARCHING_COURIER',
        'COURIER_ASSIGNED',
        'SHOPPING_IN_PROGRESS',
      ];

      if (!cancellableStatuses.includes(order.status)) {
        res.status(400).json({ error: 'Bu aşamada sipariş iptal edilemez' });
        return;
      }

      await prisma.$transaction(async (tx) => {
        await tx.order.update({
          where: { id: order.id },
          data: { status: 'CANCELLED' },
        });
        await tx.orderStatusHistory.create({
          data: {
            orderId: order.id,
            fromStatus: order.status,
            toStatus: 'CANCELLED',
            note: `${req.user!.role === 'CUSTOMER' ? 'Müşteri' : 'Kurye'} tarafından iptal edildi`,
          },
        });

        const payment = await tx.payment.findUnique({ where: { orderId: order.id } });
        if (payment && payment.status === 'COMPLETED') {
          const provider = getPaymentProvider();
          await provider.refundPayment(payment.providerRef || '');
          await tx.payment.update({
            where: { id: payment.id },
            data: { status: 'REFUNDED' },
          });
        }
      });

      res.json({ message: 'Sipariş iptal edildi' });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.get('/', authenticate, async (req: AuthRequest, res) => {
  try {
    const { status, page = '1', limit = '10' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);

    let where: any = {};
    if (req.user!.role === 'CUSTOMER') {
      where.customerId = req.user!.id;
    } else if (req.user!.role === 'COURIER') {
      where.courierId = req.user!.id;
    }
    if (status) where.status = status;

    const [orders, total] = await Promise.all([
      prisma.order.findMany({
        where,
        include: {
          market: { select: { id: true, name: true } },
          items: {
            include: {
              vendorProduct: {
                include: {
                  product: { select: { id: true, name: true, unit: true } },
                  vendor: { select: { id: true, name: true } },
                },
              },
            },
          },
          address: true,
          payment: { select: { id: true, status: true, amount: true } },
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

router.get('/:id', authenticate, async (req: AuthRequest, res) => {
  try {
    const order = await prisma.order.findUnique({
      where: { id: req.params.id as string },
      include: {
        customer: { select: { id: true, firstName: true, lastName: true, phone: true } },
        courier: { select: { id: true, firstName: true, lastName: true, phone: true } },
        market: true,
        address: true,
        items: {
          include: {
            vendorProduct: {
              include: {
                product: true,
                vendor: { select: { id: true, name: true } },
              },
            },
          },
        },
        statusHistory: { orderBy: { createdAt: 'asc' } },
        payment: true,
        ratings: true,
      },
    });

    if (!order) {
      res.status(404).json({ error: 'Sipariş bulunamadı' });
      return;
    }

    if (
      req.user!.role !== 'ADMIN' &&
      order.customerId !== req.user!.id &&
      order.courierId !== req.user!.id
    ) {
      res.status(403).json({ error: 'Bu siparişe erişim yetkiniz yok' });
      return;
    }

    res.json(order);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

const ratingSchema = z.object({
  orderId: z.string().uuid(),
  rateeId: z.string().uuid(),
  score: z.number().int().min(1).max(5),
  comment: z.string().optional(),
});

router.post('/rate', authenticate, validate(ratingSchema), async (req: AuthRequest, res) => {
  try {
    const { orderId, rateeId, score, comment } = req.body;

    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order || order.status !== 'DELIVERED') {
      res.status(400).json({ error: 'Sadece teslim edilmiş siparişler değerlendirilebilir' });
      return;
    }

    const rating = await prisma.rating.create({
      data: {
        orderId,
        raterId: req.user!.id,
        rateeId,
        score,
        comment,
      },
    });

    const avgResult = await prisma.rating.aggregate({
      where: { rateeId },
      _avg: { score: true },
    });

    if (avgResult._avg.score) {
      await prisma.courierProfile.updateMany({
        where: { userId: rateeId },
        data: { averageRating: parseFloat(avgResult._avg.score.toFixed(2)) },
      });
    }

    res.status(201).json({ message: 'Değerlendirme kaydedildi', rating });
  } catch (error: any) {
    if ((error as any).code === 'P2002') {
      res.status(409).json({ error: 'Bu siparişi zaten değerlendirdiniz' });
      return;
    }
    res.status(400).json({ error: error.message });
  }
});

export default router;

