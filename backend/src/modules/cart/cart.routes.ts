import { Router } from 'express';
import { authenticate, AuthRequest } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { z } from 'zod';
import prisma from '../../config/database';

const router = Router();

router.get('/', authenticate, async (req: AuthRequest, res) => {
  try {
    const cart = await prisma.cart.findFirst({
      where: { userId: req.user!.id, isActive: true },
      include: {
        market: { select: { id: true, name: true, latitude: true, longitude: true } },
        items: {
          include: {
            vendorProduct: {
              include: {
                product: { select: { id: true, name: true, unit: true, imageUrl: true } },
                vendor: {
                  select: {
                    id: true,
                    name: true,
                    market: { select: { id: true, name: true, city: true, district: true } },
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!cart) {
      res.json({ cart: null, items: [], subtotal: 0 });
      return;
    }

    const subtotal = cart.items.reduce(
      (sum, item) => sum + item.quantity * item.vendorProduct.price,
      0
    );

    res.json({
      cart: {
        id: cart.id,
        market: cart.market,
      },
      items: cart.items,
      subtotal: parseFloat(subtotal.toFixed(2)),
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

const addItemSchema = z.object({
  marketId: z.string().uuid(),
  vendorProductId: z.string().uuid(),
  quantity: z.number().positive('Miktar 0\'dan büyük olmalıdır'),
  note: z.string().optional(),
  clearExistingCart: z.boolean().optional(),
});

router.post('/items', authenticate, validate(addItemSchema), async (req: AuthRequest, res) => {
  try {
    const { marketId, vendorProductId, quantity, note, clearExistingCart } = req.body;

    let cart = await prisma.cart.findFirst({
      where: { userId: req.user!.id, isActive: true },
      include: {
        market: { select: { id: true, name: true } },
        items: true,
      },
    });

    if (cart && cart.marketId !== marketId && cart.items.length > 0) {
      if (clearExistingCart !== true) {
        res.status(409).json({
          error: `Sepetinizde farklı bir pazardan (${cart.market?.name || 'Başka Pazar'}) ürünler var.`,
          marketIdMismatch: true,
          existingMarketName: cart.market?.name || 'Başka Pazar',
        });
        return;
      }

      await prisma.cartItem.deleteMany({ where: { cartId: cart.id } });
      cart = await prisma.cart.update({
        where: { id: cart.id },
        data: { marketId },
        include: {
          market: { select: { id: true, name: true } },
          items: true,
        },
      });
    }

    if (!cart) {
      cart = await prisma.cart.create({
        data: {
          userId: req.user!.id,
          marketId,
        },
        include: {
          market: { select: { id: true, name: true } },
          items: true,
        },
      });
    }

    const existingItem = await prisma.cartItem.findUnique({
      where: {
        cartId_vendorProductId: {
          cartId: cart.id,
          vendorProductId,
        },
      },
    });

    if (existingItem) {

      const updated = await prisma.cartItem.update({
        where: { id: existingItem.id },
        data: {
          quantity: existingItem.quantity + quantity,
          note: note !== undefined ? note : existingItem.note,
        },
        include: {
          vendorProduct: {
            include: {
              product: true,
              vendor: { select: { id: true, name: true } },
            },
          },
        },
      });
      res.json({ message: 'Miktar güncellendi', item: updated });
    } else {
      const item = await prisma.cartItem.create({
        data: {
          cartId: cart.id,
          vendorProductId,
          quantity,
          note: note ?? null,
        },
        include: {
          vendorProduct: {
            include: {
              product: true,
              vendor: { select: { id: true, name: true } },
            },
          },
        },
      });
      res.status(201).json({ message: 'Sepete eklendi', item });
    }
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

const updateItemSchema = z.object({
  quantity: z.number().positive('Miktar 0\'dan büyük olmalıdır').optional(),
  note: z.string().nullable().optional(),
});

router.put('/items/:id', authenticate, validate(updateItemSchema), async (req: AuthRequest, res) => {
  try {
    const item = await prisma.cartItem.findUnique({
      where: { id: req.params.id as string },
      include: { cart: true },
    });

    if (!item || item.cart.userId !== req.user!.id) {
      res.status(404).json({ error: 'Sepet öğesi bulunamadı' });
      return;
    }

    const updateData: any = {};
    if (req.body.quantity !== undefined) updateData.quantity = req.body.quantity;
    if (req.body.note !== undefined) updateData.note = req.body.note;

    const updated = await prisma.cartItem.update({
      where: { id: req.params.id as string },
      data: updateData,
    });
    res.json({ message: 'Sepet öğesi güncellendi', item: updated });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/items/:id', authenticate, async (req: AuthRequest, res) => {
  try {
    const item = await prisma.cartItem.findUnique({
      where: { id: req.params.id as string },
      include: { cart: true },
    });

    if (!item || item.cart.userId !== req.user!.id) {
      res.status(404).json({ error: 'Sepet öğesi bulunamadı' });
      return;
    }

    await prisma.cartItem.delete({ where: { id: req.params.id as string } });
    res.json({ message: 'Ürün sepetten kaldırıldı' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/', authenticate, async (req: AuthRequest, res) => {
  try {
    const cart = await prisma.cart.findFirst({
      where: { userId: req.user!.id, isActive: true },
    });

    if (cart) {
      await prisma.cartItem.deleteMany({ where: { cartId: cart.id } });
      await prisma.cart.update({
        where: { id: cart.id },
        data: { isActive: false },
      });
    }

    res.json({ message: 'Sepet temizlendi' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

export default router;

