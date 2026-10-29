import { Router } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { z } from 'zod';
import prisma from '../../config/database';

const router = Router();

router.get('/profile', authenticate, async (req: AuthRequest, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.id },
      select: {
        id: true,
        email: true,
        phone: true,
        firstName: true,
        lastName: true,
        dateOfBirth: true,
        role: true,
        emailVerified: true,
        phoneVerified: true,
        createdAt: true,
        addresses: true,
        courierProfile: {
          include: {
            distanceTiers: { orderBy: { sortOrder: 'asc' } },
            weightTiers: { orderBy: { sortOrder: 'asc' } },
          },
        },
      },
    });
    res.json(user);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

const updateProfileSchema = z.object({
  firstName: z.string().min(2).optional(),
  lastName: z.string().min(2).optional(),
  dateOfBirth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

router.put('/profile', authenticate, validate(updateProfileSchema), async (req: AuthRequest, res) => {
  try {
    const updateData: any = {};
    if (req.body.firstName) updateData.firstName = req.body.firstName;
    if (req.body.lastName) updateData.lastName = req.body.lastName;
    if (req.body.dateOfBirth) updateData.dateOfBirth = new Date(req.body.dateOfBirth);

    const user = await prisma.user.update({
      where: { id: req.user!.id },
      data: updateData,
      select: {
        id: true,
        email: true,
        phone: true,
        firstName: true,
        lastName: true,
        dateOfBirth: true,
        role: true,
      },
    });
    res.json({ message: 'Profil güncellendi', user });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

const addressSchema = z.object({
  title: z.string().min(1, 'Adres başlığı gereklidir'),
  fullAddress: z.string().min(5, 'Adres gereklidir'),
  city: z.string().min(1, 'İl gereklidir'),
  district: z.string().min(1, 'İlçe gereklidir'),
  neighborhood: z.string().optional(),
  latitude: z.number(),
  longitude: z.number(),
  isDefault: z.boolean().optional(),
});

router.get('/addresses', authenticate, async (req: AuthRequest, res) => {
  try {
    const addresses = await prisma.address.findMany({
      where: { userId: req.user!.id },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
    res.json({ addresses });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/addresses', authenticate, validate(addressSchema), async (req: AuthRequest, res) => {
  try {

    if (req.body.isDefault) {
      await prisma.address.updateMany({
        where: { userId: req.user!.id },
        data: { isDefault: false },
      });
    }

    const addressCount = await prisma.address.count({ where: { userId: req.user!.id } });

    const address = await prisma.address.create({
      data: {
        ...req.body,
        userId: req.user!.id,
        isDefault: req.body.isDefault || addressCount === 0,
      },
    });
    res.status(201).json({ message: 'Adres eklendi', address });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/addresses/:id', authenticate, validate(addressSchema), async (req: AuthRequest, res) => {
  try {
    const address = await prisma.address.findFirst({
      where: { id: req.params.id as string, userId: req.user!.id },
    });
    if (!address) {
      res.status(404).json({ error: 'Adres bulunamadı' });
      return;
    }

    if (req.body.isDefault) {
      await prisma.address.updateMany({
        where: { userId: req.user!.id },
        data: { isDefault: false },
      });
    }

    const updated = await prisma.address.update({
      where: { id: req.params.id as string },
      data: req.body,
    });
    res.json({ message: 'Adres güncellendi', address: updated });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/addresses/:id', authenticate, async (req: AuthRequest, res) => {
  try {
    const address = await prisma.address.findFirst({
      where: { id: req.params.id as string, userId: req.user!.id },
    });
    if (!address) {
      res.status(404).json({ error: 'Adres bulunamadı' });
      return;
    }

    await prisma.address.delete({ where: { id: req.params.id as string } });
    res.json({ message: 'Adres silindi' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

export default router;

