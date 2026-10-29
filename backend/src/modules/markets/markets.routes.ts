import { Router } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { z } from 'zod';
import prisma from '../../config/database';
import { calculateDistance, processBase64Image } from '../../utils/helpers';

const router = Router();

const marketSchema = z.object({
  name: z.string().min(2, 'Pazar adı gereklidir'),
  city: z.string().min(1, 'İl gereklidir'),
  district: z.string().min(1, 'İlçe gereklidir'),
  neighborhood: z.string().min(1, 'Semt gereklidir'),
  fullAddress: z.string().optional(),
  imageUrl: z.string().nullable().optional(),
  latitude: z.number().or(z.string().transform((v) => parseFloat(v) || 41.0082)),
  longitude: z.number().or(z.string().transform((v) => parseFloat(v) || 28.9784)),
  operatingDays: z.string().optional(),
  openTime: z.string().optional(),
  closeTime: z.string().optional(),
});

router.get('/', async (req, res) => {
  try {
    const { lat, lng, radius, city, district, all } = req.query;

    let where: any = {};
    if (all !== 'true') {
      where.isActive = true;
    }
    if (city) where.city = city;
    if (district) where.district = district;

    const rawMarkets = await prisma.market.findMany({
      where,
      include: {
        products: {
          select: { id: true, categoryId: true },
        },
        vendors: {
          where: { isActive: true },
          include: {
            vendorProducts: {
              where: { isActive: true },
              select: { productId: true, product: { select: { categoryId: true } } },
            },
          },
        },
      } as any,
      orderBy: { name: 'asc' },
    });

    const markets = (rawMarkets as any[]).map((m: any) => {
      const { products, vendors, ...rest } = m;
      const categoryIds = new Set<string>();
      let stallCount = 0;

      (products || []).forEach((p: any) => {
        categoryIds.add(p.categoryId);
      });

      (vendors || []).forEach((v: any) => {
        (v.vendorProducts || []).forEach((vp: any) => {
          stallCount++;
          if (vp.product?.categoryId) categoryIds.add(vp.product.categoryId);
        });
      });

      return {
        ...rest,
        stallCount,
        categoryCount: categoryIds.size,
      };
    });

    if (lat && lng) {
      const userLat = parseFloat(lat as string);
      const userLng = parseFloat(lng as string);
      const maxRadius = radius ? parseFloat(radius as string) : 20;

      const marketsWithDistance = markets
        .map((market) => ({
          ...market,
          distance: calculateDistance(userLat, userLng, market.latitude, market.longitude),
        }))
        .filter((market) => market.distance <= maxRadius)
        .sort((a, b) => a.distance - b.distance);

      res.json(marketsWithDistance);
      return;
    }

    res.json(markets);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const market = await prisma.market.findUnique({
      where: { id: req.params.id as string },
      include: {
        vendors: {
          where: { isActive: true },
          include: {
            vendorProducts: {
              where: { isActive: true },
              include: {
                product: {
                  include: { category: true },
                },
              },
            },
          },
        },
      },
    });

    if (!market) {
      res.status(404).json({ error: 'Pazar bulunamadı' });
      return;
    }

    res.json(market);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.post(
  '/',
  authenticate,
  requireRole('ADMIN'),
  validate(marketSchema),
  async (req, res) => {
    try {
      if (req.body.imageUrl && req.body.imageUrl.startsWith('data:image/')) {
        req.body.imageUrl = await processBase64Image(req.body.imageUrl, 'markets');
      }
      const market = await prisma.market.create({ data: req.body });
      res.status(201).json({ message: 'Pazar oluşturuldu', market });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.put(
  '/:id',
  authenticate,
  requireRole('ADMIN'),
  validate(marketSchema),
  async (req, res) => {
    try {
      if (req.body.imageUrl && req.body.imageUrl.startsWith('data:image/')) {
        req.body.imageUrl = await processBase64Image(req.body.imageUrl, 'markets');
      }
      const market = await prisma.market.update({
        where: { id: req.params.id as string },
        data: req.body,
      });
      res.json({ message: 'Pazar güncellendi', market });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.delete(
  '/:id',
  authenticate,
  requireRole('ADMIN'),
  async (req, res) => {
    try {
      const marketId = req.params.id as string;

      const vendors = await prisma.vendor.findMany({
        where: { marketId },
        select: { id: true },
      });
      const vendorIds = vendors.map((v) => v.id);

      const vendorProducts = await prisma.vendorProduct.findMany({
        where: { vendorId: { in: vendorIds } },
        select: { id: true },
      });
      const vpIds = vendorProducts.map((vp) => vp.id);

      const products = await prisma.product.findMany({
        where: { marketId } as any,
        select: { id: true },
      });
      const productIds = products.map((p) => p.id);

      const orders = await prisma.order.findMany({
        where: { marketId },
        select: { id: true },
      });
      const orderIds = orders.map((o) => o.id);

      const carts = await prisma.cart.findMany({
        where: { marketId },
        select: { id: true },
      });
      const cartIds = carts.map((c) => c.id);

      await prisma.$transaction([
        prisma.cartItem.deleteMany({
          where: {
            OR: [
              { cartId: { in: cartIds } },
              { vendorProductId: { in: vpIds } },
            ],
          },
        }),
        prisma.cart.deleteMany({ where: { marketId } }),

        prisma.orderItem.deleteMany({
          where: {
            OR: [
              { orderId: { in: orderIds } },
              { vendorProductId: { in: vpIds } },
            ],
          },
        }),
        prisma.orderStatusHistory.deleteMany({ where: { orderId: { in: orderIds } } }),
        prisma.payment.deleteMany({ where: { orderId: { in: orderIds } } }),
        prisma.rating.deleteMany({ where: { orderId: { in: orderIds } } }),
        prisma.order.deleteMany({ where: { marketId } }),

        prisma.favorite.deleteMany({ where: { productId: { in: productIds } } }),

        prisma.vendorProduct.deleteMany({ where: { vendorId: { in: vendorIds } } }),
        prisma.vendor.deleteMany({ where: { marketId } }),

        prisma.product.deleteMany({ where: { marketId } as any }),

        prisma.employeeAssignment.deleteMany({ where: { marketId } }),
        prisma.courierProfile.updateMany({
          where: { selectedMarketId: marketId },
          data: { selectedMarketId: null, isAvailable: false },
        }),

        prisma.market.delete({ where: { id: marketId } }),
      ]);

      res.json({ message: 'Pazar veritabanından tamamen silindi' });
    } catch (error: any) {
      console.error('Delete Market Error:', error);
      res.status(400).json({ error: error.message || 'Pazar silinirken bir hata oluştu' });
    }
  }
);

router.patch(
  '/:id/toggle',
  authenticate,
  requireRole('ADMIN'),
  async (req, res) => {
    try {
      const market = await prisma.market.findUnique({ where: { id: req.params.id as string } });
      if (!market) {
        res.status(404).json({ error: 'Pazar bulunamadı' });
        return;
      }
      const updated = await prisma.market.update({
        where: { id: market.id },
        data: { isActive: !market.isActive },
      });
      res.json({ message: `Pazar ${updated.isActive ? 'açıldı' : 'kapatıldı'}`, market: updated });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.get('/:id/products', async (req, res) => {
  try {
    const market = await prisma.market.findUnique({ where: { id: req.params.id as string } });
    if (!market) {
      res.status(404).json({ error: 'Pazar bulunamadı' });
      return;
    }

    const categories = await prisma.productCategory.findMany({
      orderBy: { sortOrder: 'asc' },
      include: {
        products: {
          include: {
            vendorProducts: {
              where: {
                isActive: true,
                vendor: {
                  marketId: req.params.id,
                  isActive: true,
                },
              },
              include: {
                vendor: {
                  select: { id: true, name: true },
                },
              },
              orderBy: { price: 'asc' },
            },
          },
        },
      },
    });

    const includeEmpty = req.query.includeEmpty === 'true';

    const filtered = categories
      .map((cat) => ({
        ...cat,
        products: cat.products.filter((p: any) =>
          includeEmpty
            ? (p.marketId === req.params.id || (p.vendorProducts && p.vendorProducts.length > 0))
            : (p.vendorProducts && p.vendorProducts.length > 0)
        ),
      }))
      .filter((cat) => cat.products.length > 0);

    res.json(filtered);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

export default router;

