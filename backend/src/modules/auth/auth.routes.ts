import { Router } from 'express';
import { authService } from './auth.service';
import { validate } from '../../middleware/validate';
import { authenticate, AuthRequest } from '../../middleware/auth';
import {
  registerSchema,
  loginSchema,
  adminLoginSchema,
  refreshTokenSchema,
  sendVerificationSchema,
  verifyCodeSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from './auth.schemas';

const router = Router();

router.post('/register', validate(registerSchema), async (req, res) => {
  try {
    const result = await authService.register(req.body);
    res.status(201).json({
      message: 'Kayıt başarılı',
      ...result,
    });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/login', validate(loginSchema), async (req, res) => {
  try {
    const result = await authService.login(req.body.email, req.body.password);
    res.json({
      message: 'Giriş başarılı',
      ...result,
    });
  } catch (error: any) {
    res.status(401).json({ error: error.message });
  }
});

router.post('/admin/login', validate(adminLoginSchema), async (req, res) => {
  try {
    const result = await authService.adminLogin(
      req.body.email,
      req.body.password,
      req.body.pin
    );
    res.json({
      message: 'Admin girişi başarılı',
      ...result,
    });
  } catch (error: any) {
    res.status(401).json({ error: error.message });
  }
});

router.post('/employee/login', validate(loginSchema), async (req, res) => {
  try {
    const result = await authService.employeeLogin(req.body.email, req.body.password);
    res.json({
      message: 'Çalışan girişi başarılı',
      ...result,
    });
  } catch (error: any) {
    res.status(401).json({ error: error.message });
  }
});

router.post('/refresh', validate(refreshTokenSchema), async (req, res) => {
  try {
    const result = await authService.refreshToken(req.body.refreshToken);
    res.json(result);
  } catch (error: any) {
    res.status(401).json({ error: error.message });
  }
});

router.post('/logout', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await authService.logout(refreshToken);
    }
    res.json({ message: 'Çıkış yapıldı' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.post(
  '/verification/send',
  authenticate,
  validate(sendVerificationSchema),
  async (req: AuthRequest, res) => {
    try {
      const result = await authService.sendVerificationCode(
        req.user!.id,
        req.body.target,
        req.body.channel
      );
      res.json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.post(
  '/verification/verify',
  authenticate,
  validate(verifyCodeSchema),
  async (req: AuthRequest, res) => {
    try {
      const result = await authService.verifyCode(
        req.user!.id,
        req.body.target,
        req.body.code,
        req.body.channel
      );
      res.json(result);
    } catch (error: any) {
      res.status(400).json({ error: error.message });
    }
  }
);

router.post('/forgot-password', validate(forgotPasswordSchema), async (req, res) => {
  try {
    const result = await authService.forgotPassword(req.body.email);
    res.json(result);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/reset-password', validate(resetPasswordSchema), async (req, res) => {
  try {
    const result = await authService.resetPassword(
      req.body.email,
      req.body.code,
      req.body.newPassword
    );
    res.json(result);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.post('/change-password', authenticate, async (req: AuthRequest, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      res.status(400).json({ error: 'Mevcut şifre ve yeni şifre gereklidir' });
      return;
    }
    const result = await authService.changePassword(req.user!.id, currentPassword, newPassword);
    res.json(result);
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

export default router;

