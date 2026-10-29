import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';

export const validate = (schema: ZodSchema, source: 'body' | 'query' | 'params' = 'body') => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      const data = schema.parse(req[source]);
      req[source] = data;
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        const formattedErrors = error.errors.map((err) => ({
          field: err.path.join('.'),
          message: err.message,
        }));
        const firstMsg = formattedErrors.map(e => e.message).join(', ');
        res.status(400).json({
          error: `Doğrulama hatası: ${firstMsg}`,
          details: formattedErrors,
        });
        return;
      }
      next(error);
    }
  };
};

