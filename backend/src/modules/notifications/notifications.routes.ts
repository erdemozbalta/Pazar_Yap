import { Router } from 'express';
import { authenticate, AuthRequest } from '../../middleware/auth';
import prisma from '../../config/database';

const router = Router();

router.get('/', authenticate, async (req: AuthRequest, res) => {
  try {
    const { unreadOnly, page = '1', limit = '20' } = req.query;
    const skip = (parseInt(page as string) - 1) * parseInt(limit as string);

    let where: any = { userId: req.user!.id };
    if (unreadOnly === 'true') where.isRead = false;

    const [notifications, total, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: parseInt(limit as string),
      }),
      prisma.notification.count({ where }),
      prisma.notification.count({ where: { userId: req.user!.id, isRead: false } }),
    ]);

    res.json({
      notifications,
      unreadCount,
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

router.put('/:id/read', authenticate, async (req: AuthRequest, res) => {
  try {
    await prisma.notification.updateMany({
      where: { id: req.params.id as string, userId: req.user!.id },
      data: { isRead: true },
    });
    res.json({ message: 'Okundu olarak işaretlendi' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/read-all', authenticate, async (req: AuthRequest, res) => {
  try {
    await prisma.notification.updateMany({
      where: { userId: req.user!.id, isRead: false },
      data: { isRead: true },
    });
    res.json({ message: 'Tüm bildirimler okundu olarak işaretlendi' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

export default router;

