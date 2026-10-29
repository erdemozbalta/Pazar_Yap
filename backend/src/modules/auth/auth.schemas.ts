import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email('Geçerli bir e-posta adresi giriniz'),
  phone: z.string().regex(/^\+90\d{10}$/, 'Telefon numarası +90XXXXXXXXXX formatında olmalıdır'),
  password: z.string().min(8, 'Şifre en az 8 karakter olmalıdır')
    .regex(/[A-Z]/, 'Şifre en az bir büyük harf içermelidir')
    .regex(/[a-z]/, 'Şifre en az bir küçük harf içermelidir')
    .regex(/[0-9]/, 'Şifre en az bir rakam içermelidir'),
  firstName: z.string().min(2, 'Ad en az 2 karakter olmalıdır'),
  lastName: z.string().min(2, 'Soyad en az 2 karakter olmalıdır'),
  dateOfBirth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Doğum tarihi YYYY-MM-DD formatında olmalıdır').optional(),
  role: z.enum(['CUSTOMER', 'COURIER']).default('CUSTOMER'),
});

export const loginSchema = z.object({
  email: z.string().email('Geçerli bir e-posta adresi giriniz'),
  password: z.string().min(1, 'Şifre gereklidir'),
});

export const adminLoginSchema = z.object({
  email: z.string().email('Geçerli bir e-posta adresi giriniz'),
  password: z.string().min(1, 'Şifre gereklidir'),
  pin: z.string().length(6, 'PIN 6 haneli olmalıdır'),
});

export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token gereklidir'),
});

export const sendVerificationSchema = z.object({
  target: z.string().min(1, 'Hedef gereklidir'),
  channel: z.enum(['sms', 'email']),
});

export const verifyCodeSchema = z.object({
  target: z.string().min(1, 'Hedef gereklidir'),
  code: z.string().length(6, 'Kod 6 haneli olmalıdır'),
  channel: z.enum(['sms', 'email']),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email('Geçerli bir e-posta adresi giriniz'),
});

export const resetPasswordSchema = z.object({
  email: z.string().email('Geçerli bir e-posta adresi giriniz'),
  code: z.string().length(6, 'Kod 6 haneli olmalıdır'),
  newPassword: z.string().min(8, 'Şifre en az 8 karakter olmalıdır')
    .regex(/[A-Z]/, 'Şifre en az bir büyük harf içermelidir')
    .regex(/[a-z]/, 'Şifre en az bir küçük harf içermelidir')
    .regex(/[0-9]/, 'Şifre en az bir rakam içermelidir'),
});

