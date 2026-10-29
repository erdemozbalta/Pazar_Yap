import { Router } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { z } from 'zod';
import prisma from '../../config/database';

const router = Router();

router.get('/profile', authenticate, requireRole('COURIER'), async (req: AuthRequest, res) => {
  try {
    let profile = await prisma.courierProfile.findUnique({
      where: { userId: req.user!.id },
      include: {
        selectedMarket: true,
        distanceTiers: { orderBy: { sortOrder: 'asc' } },
        weightTiers: { orderBy: { sortOrder: 'asc' } },
      },
    });
    if (!profile) {
      profile = await prisma.courierProfile.create({
        data: { userId: req.user!.id, isAvailable: false, selectedMarketId: null },
        include: {
          selectedMarket: true,
          distanceTiers: { orderBy: { sortOrder: 'asc' } },
          weightTiers: { orderBy: { sortOrder: 'asc' } },
        },
      });
    }

    if (profile && (!profile.selectedMarketId || !profile.selectedMarket) && profile.isAvailable) {
      profile = await prisma.courierProfile.update({
        where: { userId: req.user!.id },
        data: { isAvailable: false, selectedMarketId: null },
        include: {
          selectedMarket: true,
          distanceTiers: { orderBy: { sortOrder: 'asc' } },
          weightTiers: { orderBy: { sortOrder: 'asc' } },
        },
      });
    }

    res.json(profile);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.put(
  '/availability',
  authenticate,
  requireRole('COURIER'),
  async (req: AuthRequest, res) => {
    try {
      const { isAvailable, selectedMarketId, currentLatitude, currentLongitude } = req.body;

      const existingProfile = await prisma.courierProfile.findUnique({
        where: { userId: req.user!.id },
      });

      let finalMarketId = selectedMarketId !== undefined
        ? (selectedMarketId ? String(selectedMarketId) : null)
        : (existingProfile?.selectedMarketId ?? null);

      let finalIsAvailable = isAvailable !== undefined
        ? (isAvailable === true || isAvailable === 'true')
        : (existingProfile?.isAvailable ?? false);

      if (!finalMarketId) {
        finalIsAvailable = false;
      }

      if (isAvailable === false || isAvailable === 'false') {
        finalIsAvailable = false;
        finalMarketId = null;
      }

      const updateData: any = {
        isAvailable: finalIsAvailable,
        selectedMarketId: finalMarketId,
      };

      if (currentLatitude !== undefined) updateData.currentLatitude = currentLatitude ? Number(currentLatitude) : null;
      if (currentLongitude !== undefined) updateData.currentLongitude = currentLongitude ? Number(currentLongitude) : null;

      const profile = await prisma.courierProfile.upsert({
        where: { userId: req.user!.id },
        update: updateData,
        create: {
          userId: req.user!.id,
          isAvailable: finalIsAvailable,
          selectedMarketId: finalMarketId,
        },
        include: { selectedMarket: true },
      });

      res.json({
        message: profile.isAvailable ? 'Müsait olarak işaretlendi' : 'Müsait değil olarak işaretlendi',
        profile,
      });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.get('/available-count', authenticate, async (req, res) => {
  try {
    const { marketId } = req.query;

    const countForMarket = marketId
      ? await prisma.courierProfile.count({
          where: {
            isAvailable: true,
            selectedMarketId: marketId as string,
          },
        })
      : 0;

    const totalActive = await prisma.courierProfile.count({
      where: { isAvailable: true },
    });

    res.json({ count: countForMarket, totalActive, countForMarket });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/available-orders', authenticate, requireRole('COURIER'), async (req, res) => {
  try {
    const { marketId } = req.query;
    if (!marketId) {
      res.json([]);
      return;
    }

    const orders = await prisma.order.findMany({
      where: {
        marketId: marketId as string,
        courierId: null,
        status: { in: ['SEARCHING_COURIER', 'PAYMENT_PENDING'] },
      },
      include: {
        market: { select: { name: true, district: true } },
        address: true,
        customer: { select: { firstName: true, lastName: true, phone: true } },
        items: {
          include: {
            vendorProduct: {
              include: {
                product: { select: { name: true, unit: true } },
                vendor: { select: { name: true } },
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(orders);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/active-order', authenticate, requireRole('COURIER'), async (req: AuthRequest, res) => {
  try {
    const activeOrder = await prisma.order.findFirst({
      where: {
        courierId: req.user!.id,
        status: { in: ['COURIER_ASSIGNED', 'SHOPPING_IN_PROGRESS', 'ON_THE_WAY'] },
      },
      include: {
        market: { select: { name: true, district: true, fullAddress: true } },
        address: true,
        customer: { select: { firstName: true, lastName: true, phone: true } },
        items: {
          include: {
            vendorProduct: {
              include: {
                product: { select: { name: true, unit: true } },
                vendor: { select: { name: true } },
              },
            },
          },
        },
      },
    });

    res.json(activeOrder);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

const pricingSchema = z.object({
  baseFee: z.number().min(0, 'Taban ücret 0 veya üzeri olmalıdır'),
  distanceTiers: z.array(z.object({
    minKm: z.number().min(0),
    maxKm: z.number().positive('Maksimum km 0\'dan büyük olmalıdır'),
    percentageIncrease: z.number().min(0),
    increaseType: z.enum(['PERCENTAGE', 'FIXED_TL']).default('PERCENTAGE'),
    sortOrder: z.number().default(0),
  })),
  weightTiers: z.array(z.object({
    minKg: z.number().min(0),
    maxKg: z.number().positive('Maksimum kg 0\'dan büyük olmalıdır'),
    percentageIncrease: z.number().min(0),
    increaseType: z.enum(['PERCENTAGE', 'FIXED_TL']).default('PERCENTAGE'),
    sortOrder: z.number().default(0),
  })),
});

router.put(
  '/pricing',
  authenticate,
  requireRole('COURIER'),
  validate(pricingSchema),
  async (req: AuthRequest, res) => {
    try {
      const { baseFee, distanceTiers, weightTiers } = req.body;

      const profile = await prisma.courierProfile.findUnique({
        where: { userId: req.user!.id },
      });

      if (!profile) {
        res.status(404).json({ error: 'Kurye profili bulunamadı' });
        return;
      }

      const validateTiers = (tiers: any[], unitName: string, minProp: string, maxProp: string) => {
        for (let i = 0; i < tiers.length; i++) {
          const t = tiers[i];
          if (t[maxProp] <= t[minProp]) {
            throw new Error(`${unitName} ${i + 1}. kademede Maksimum değer (${t[maxProp]}), Minimum değerden (${t[minProp]}) büyük olmalıdır!`);
          }
        }

        const sorted = [...tiers].sort((a: any, b: any) => (a[minProp] - b[minProp]));
        for (let i = 1; i < sorted.length; i++) {
          const prev = sorted[i - 1] as any;
          const curr = sorted[i] as any;
          if (curr[minProp] < prev[maxProp]) {
            throw new Error(`${unitName} Kademe Çakışması: ${curr[minProp]} değeri, önceki kademenin Max değeri olan ${prev[maxProp]} değerinden büyük veya eşit olmalıdır!`);
          }
        }
      };

      validateTiers(distanceTiers, 'Mesafe', 'minKm', 'maxKm');
      validateTiers(weightTiers, 'Ağırlık', 'minKg', 'maxKg');

      await prisma.$transaction(async (tx) => {

        await tx.courierProfile.update({
          where: { id: profile.id },
          data: { baseFee },
        });

        await tx.courierDistanceTier.deleteMany({
          where: { courierProfileId: profile.id },
        });
        await tx.courierWeightTier.deleteMany({
          where: { courierProfileId: profile.id },
        });

        if (distanceTiers.length > 0) {
          await tx.courierDistanceTier.createMany({
            data: distanceTiers.map((t: any, i: number) => ({
              courierProfileId: profile.id,
              minKm: t.minKm,
              maxKm: t.maxKm,
              percentageIncrease: t.percentageIncrease,
              increaseType: t.increaseType ?? 'PERCENTAGE',
              sortOrder: t.sortOrder ?? i,
            })),
          });
        }

        if (weightTiers.length > 0) {
          await tx.courierWeightTier.createMany({
            data: weightTiers.map((t: any, i: number) => ({
              courierProfileId: profile.id,
              minKg: t.minKg,
              maxKg: t.maxKg,
              percentageIncrease: t.percentageIncrease,
              increaseType: t.increaseType ?? 'PERCENTAGE',
              sortOrder: t.sortOrder ?? i,
            })),
          });
        }
      });

      const updated = await prisma.courierProfile.findUnique({
        where: { id: profile.id },
        include: {
          distanceTiers: { orderBy: { sortOrder: 'asc' } },
          weightTiers: { orderBy: { sortOrder: 'asc' } },
        },
      });

      res.json({ message: 'Ücretlendirme güncellendi', profile: updated });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.get('/earnings', authenticate, requireRole('COURIER'), async (req: AuthRequest, res) => {
  try {
    const { startDate, endDate } = req.query;

    let dateFilter: any = {};
    if (startDate) dateFilter.gte = new Date(startDate as string);
    if (endDate) dateFilter.lte = new Date(endDate as string);

    const orders = await prisma.order.findMany({
      where: {
        courierId: req.user!.id,
        status: 'DELIVERED',
        ...(Object.keys(dateFilter).length > 0 && { deliveredAt: dateFilter }),
      },
      select: {
        id: true,
        orderNumber: true,
        courierFee: true,
        deliveredAt: true,
        createdAt: true,
        totalWeight: true,
        distanceKm: true,
        market: { select: { name: true } },
        customer: { select: { firstName: true, lastName: true } },
        items: { select: { id: true } },
      },
      orderBy: { deliveredAt: 'desc' },
    });

    const totalEarnings = orders.reduce((sum, o) => sum + o.courierFee, 0);
    const profile = await prisma.courierProfile.findUnique({
      where: { userId: req.user!.id },
      select: { totalEarnings: true, totalDeliveries: true, averageRating: true },
    });

    res.json({
      summary: {
        totalEarnings: parseFloat(totalEarnings.toFixed(2)),
        totalDeliveries: orders.length,
        averageRating: profile?.averageRating || 0,
        allTimeTotalEarnings: profile?.totalEarnings || 0,
        allTimeTotalDeliveries: profile?.totalDeliveries || 0,
      },
      orders,
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

export default router;

