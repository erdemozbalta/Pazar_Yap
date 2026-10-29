import { Request, Response, NextFunction } from 'express';

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  console.error('❌ Hata:', err.message);
  console.error(err.stack);

  if ((err as any).code === 'P2002') {
    res.status(409).json({
      error: 'Bu kayıt zaten mevcut',
      details: (err as any).meta?.target,
    });
    return;
  }

  if ((err as any).code === 'P2025') {
    res.status(404).json({
      error: 'Kayıt bulunamadı',
    });
    return;
  }

  res.status(500).json({
    error: 'Sunucu hatası',
    ...(process.env.NODE_ENV === 'development' && { details: err.message }),
  });
};

export const notFoundHandler = (_req: Request, res: Response): void => {
  res.status(404).json({ error: 'Endpoint bulunamadı' });
};

