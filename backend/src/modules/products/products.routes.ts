import { Router } from 'express';
import { authenticate, requireRole, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { z } from 'zod';
import prisma from '../../config/database';
import multer from 'multer';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import { getStorageProvider } from '../../services/storage';
import { processBase64Image } from '../../utils/helpers';

const router = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Sadece JPEG, PNG ve WebP formatları desteklenir'));
    }
  },
});

const categorySchema = z.object({
  name: z.string().min(1, 'Kategori adı gereklidir'),
  icon: z.string().optional(),
  sortOrder: z.number().optional(),
});

router.get('/categories', async (_req, res) => {
  try {
    let categories = await prisma.productCategory.findMany({
      orderBy: { sortOrder: 'asc' },
      include: { _count: { select: { products: true } } },
    });

    if (categories.length === 0) {
      const defaultCategories = [
        { name: 'Meyve', icon: '🍎', sortOrder: 1 },
        { name: 'Sebze', icon: '🥦', sortOrder: 2 },
        { name: 'Yeşillik', icon: '🌿', sortOrder: 3 },
        { name: 'Peynir & Süt Ürünleri', icon: '🧀', sortOrder: 4 },
        { name: 'Unlu Mamüller', icon: '🥖', sortOrder: 5 },
        { name: 'Kahvaltılık & Reçel & Bal', icon: '🍯', sortOrder: 6 },
        { name: 'Zeytin & Şarküteri', icon: '🫒', sortOrder: 7 },
        { name: 'Kuruyemiş & Bakliyat', icon: '🥜', sortOrder: 8 },
        { name: 'Baharat', icon: '🌶️', sortOrder: 9 },
        { name: 'Et & Kasap', icon: '🥩', sortOrder: 10 },
        { name: 'Balık & Deniz Ürünleri', icon: '🐟', sortOrder: 11 },
      ];

      for (const cat of defaultCategories) {
        await prisma.productCategory.create({ data: cat }).catch(() => {});
      }

      categories = await prisma.productCategory.findMany({
        orderBy: { sortOrder: 'asc' },
        include: { _count: { select: { products: true } } },
      });
    }

    res.json(categories);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.post(
  '/categories',
  authenticate,
  requireRole('ADMIN'),
  validate(categorySchema),
  async (req, res) => {
    try {
      const category = await prisma.productCategory.create({ data: req.body });
      res.status(201).json({ message: 'Kategori oluşturuldu', category });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

const productSchema = z.object({
  categoryId: z.string().uuid(),
  name: z.string().min(1, 'Ürün adı gereklidir'),
  unit: z.string().default('kg'),
  imageUrl: z.string().nullable().optional(),
  marketId: z.string().uuid().nullable().optional(),
});

router.get('/', async (req, res) => {
  try {
    const { categoryId, search } = req.query;
    let where: any = {};
    if (categoryId) where.categoryId = categoryId;
    if (search) where.name = { contains: search };

    const products = await prisma.product.findMany({
      where,
      include: { category: true },
      orderBy: { name: 'asc' },
    });
    res.json(products);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const { marketId } = req.query;

    const product = await prisma.product.findUnique({
      where: { id: req.params.id as string },
      include: {
        category: true,
        vendorProducts: {
          where: {
            isActive: true,
            ...(marketId && {
              vendor: { marketId: marketId as string, isActive: true },
            }),
          },
          include: {
            vendor: {
              select: { id: true, name: true, marketId: true },
            },
          },
          orderBy: { price: 'asc' },
        },
      },
    });

    if (!product) {
      res.status(404).json({ error: 'Ürün bulunamadı' });
      return;
    }

    res.json(product);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

function toTurkishTitleCase(str: string): string {
  if (!str) return str;
  return str
    .trim()
    .split(/\s+/)
    .map((word) => {
      if (!word) return '';
      const first = word.charAt(0);
      const rest = word.slice(1).toLowerCase();
      let upper = first.toUpperCase();
      if (first === 'i' || first === 'İ') upper = 'İ';
      if (first === 'ı' || first === 'I') upper = 'I';
      return upper + rest;
    })
    .join(' ');
}

router.post(
  '/',
  authenticate,
  requireRole('ADMIN', 'EMPLOYEE'),
  validate(productSchema),
  async (req, res) => {
    try {
      const data = {
        ...req.body,
        name: toTurkishTitleCase(req.body.name),
      };
      if (data.imageUrl && data.imageUrl.startsWith('data:image/')) {
        data.imageUrl = await processBase64Image(data.imageUrl, 'products');
      }
      const product = await prisma.product.create({
        data,
        include: { category: true },
      });
      res.status(201).json({ message: 'Ürün oluşturuldu', product });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.put(
  '/:id',
  authenticate,
  requireRole('ADMIN', 'EMPLOYEE'),
  async (req, res) => {
    try {
      const data: any = { ...req.body };
      if (data.name) data.name = toTurkishTitleCase(data.name);
      if (data.imageUrl && data.imageUrl.startsWith('data:image/')) {
        data.imageUrl = await processBase64Image(data.imageUrl, 'products');
      }
      const product = await prisma.product.update({
        where: { id: req.params.id as string },
        data,
        include: { category: true },
      });
      res.json({ message: 'Ürün güncellendi', product });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

const vendorSchema = z.object({
  marketId: z.string().uuid(),
  name: z.string().min(1, 'Satıcı adı gereklidir'),
  description: z.string().optional(),
});

router.get('/vendors/:marketId', async (req, res) => {
  try {
    const vendors = await prisma.vendor.findMany({
      where: { marketId: req.params.marketId, isActive: true },
      include: {
        _count: { select: { vendorProducts: true } },
      },
    });
    res.json(vendors);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.post(
  '/vendors',
  authenticate,
  requireRole('ADMIN', 'EMPLOYEE'),
  validate(vendorSchema),
  async (req, res) => {
    try {
      const vendor = await prisma.vendor.create({ data: req.body });
      res.status(201).json({ message: 'Satıcı oluşturuldu', vendor });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.post(
  '/vendor-products',
  authenticate,
  requireRole('ADMIN', 'EMPLOYEE'),
  upload.single('photo'),
  async (req: AuthRequest, res) => {
    try {
      let { vendorId, marketId, vendorName, productId, price, unit, qualityRating, stallLocation, photoUrl: bodyPhotoUrl } = req.body;
      let photoUrl: string | undefined = bodyPhotoUrl;

      if (req.file) {
        const storage = getStorageProvider();
        const ext = path.extname(req.file.originalname);
        const filename = `products/${uuidv4()}${ext}`;
        photoUrl = await storage.saveFile(req.file.buffer, filename, req.file.mimetype);
      } else if (bodyPhotoUrl && bodyPhotoUrl.startsWith('data:image/')) {
        photoUrl = (await processBase64Image(bodyPhotoUrl, 'products')) || bodyPhotoUrl;
      }

      const finalVendorName = (vendorName && vendorName.trim()) ? vendorName.trim() : (stallLocation ? `Tezgah (${stallLocation})` : 'Pazar Tezgahı');
      const selectedUnit = (unit && unit.trim()) ? unit.trim() : 'kg';

      if (productId && selectedUnit) {
        await prisma.product.update({
          where: { id: productId },
          data: { unit: selectedUnit },
        }).catch(() => {});
      }

      if (!vendorId && marketId) {
        let vendor = await prisma.vendor.findFirst({
          where: {
            marketId,
            name: finalVendorName,
          },
        });
        if (!vendor) {
          vendor = await prisma.vendor.create({
            data: { marketId, name: finalVendorName },
          });
        }
        vendorId = vendor.id;
      }

      if (!vendorId) {
        res.status(400).json({ error: 'Satıcı / Pazar bilgisi gereklidir' });
        return;
      }

      const rating = qualityRating ? parseFloat(qualityRating as string) : 5.0;

      const existingVp = await prisma.vendorProduct.findUnique({
        where: {
          vendorId_productId: { vendorId, productId },
        },
      });

      const finalPhotoUrl = photoUrl !== undefined ? photoUrl : (existingVp?.photoUrl || bodyPhotoUrl || null);

      const vendorProduct = await prisma.vendorProduct.upsert({
        where: {
          vendorId_productId: { vendorId, productId },
        },
        update: {
          price: parseFloat(price),
          photoUrl: finalPhotoUrl,
          qualityRating: rating,
          stallLocation: stallLocation || null,
          employeeId: req.user!.id,
          isActive: true,
        } as any,
        create: {
          vendorId,
          productId,
          price: parseFloat(price),
          photoUrl: finalPhotoUrl,
          qualityRating: rating,
          stallLocation: stallLocation || null,
          employeeId: req.user!.id,
          isActive: true,
        } as any,
        include: {
          vendor: { select: { id: true, name: true } },
          product: { select: { id: true, name: true, unit: true } },
        },
      });

      res.status(201).json({ message: 'Ürün-fiyat kaydı oluşturuldu', vendorProduct });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.put(
  '/vendor-products/:id',
  authenticate,
  requireRole('ADMIN', 'EMPLOYEE'),
  upload.single('photo'),
  async (req: AuthRequest, res) => {
    try {
      const existing = await prisma.vendorProduct.findUnique({
        where: { id: req.params.id as string },
      });
      if (!existing) {
        res.status(404).json({ error: 'Kayıt bulunamadı' });
        return;
      }

      const updateData: any = {};
      if (req.body.price) updateData.price = parseFloat(req.body.price);
      if (req.body.unit) {
        await prisma.product.update({
          where: { id: existing.productId },
          data: { unit: req.body.unit.trim() },
        }).catch(() => {});
      }
      if (req.body.stallLocation !== undefined) updateData.stallLocation = req.body.stallLocation;
      if (req.body.qualityRating) updateData.qualityRating = parseFloat(req.body.qualityRating);

      if (req.file) {
        const storage = getStorageProvider();
        if (existing.photoUrl) {
          await storage.deleteFile(existing.photoUrl);
        }
        const ext = path.extname(req.file.originalname);
        const filename = `products/${uuidv4()}${ext}`;
        updateData.photoUrl = await storage.saveFile(req.file.buffer, filename, req.file.mimetype);
      } else if (req.body.photoUrl && req.body.photoUrl.startsWith('data:image/')) {
        updateData.photoUrl = await processBase64Image(req.body.photoUrl, 'products');
      } else if (req.body.photoUrl !== undefined) {
        updateData.photoUrl = req.body.photoUrl;
      }

      const updated = await prisma.vendorProduct.update({
        where: { id: req.params.id as string },
        data: updateData,
        include: {
          vendor: { select: { id: true, name: true } },
          product: { select: { id: true, name: true, unit: true } },
        },
      });

      res.json({ message: 'Ürün-fiyat güncellendi', vendorProduct: updated });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.delete(
  '/vendor-products/:id',
  authenticate,
  requireRole('ADMIN', 'EMPLOYEE'),
  async (req, res) => {
    try {
      await prisma.vendorProduct.update({
        where: { id: req.params.id as string },
        data: { isActive: false },
      });
      res.json({ message: 'Tezgah kaydı kaldırıldı' });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.delete(
  '/:id',
  authenticate,
  requireRole('ADMIN', 'EMPLOYEE'),
  async (req, res) => {
    try {
      await prisma.vendorProduct.deleteMany({
        where: { productId: req.params.id as string },
      });
      await prisma.product.delete({
        where: { id: req.params.id as string },
      });
      res.json({ message: 'Ürün silindi' });
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.get('/favorites/list', authenticate, async (req: AuthRequest, res) => {
  try {
    const favorites = await prisma.favorite.findMany({
      where: { userId: req.user!.id },
      include: {
        product: {
          include: { category: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(favorites);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/favorites/:productId', authenticate, async (req: AuthRequest, res) => {
  try {
    const favorite = await prisma.favorite.create({
      data: {
        userId: req.user!.id,
        productId: req.params.productId as string,
      },
    });
    res.status(201).json({ message: 'Favorilere eklendi', favorite });
  } catch (error: any) {
    if ((error as any).code === 'P2002') {
      res.status(409).json({ error: 'Bu ürün zaten favorilerinizde' });
      return;
    }
    res.status(400).json({ error: error.message });
  }
});

router.delete('/favorites/:productId', authenticate, async (req: AuthRequest, res) => {
  try {
    await prisma.favorite.deleteMany({
      where: {
        userId: req.user!.id,
        productId: req.params.productId as string,
      },
    });
    res.json({ message: 'Favorilerden kaldırıldı' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

export default router;

