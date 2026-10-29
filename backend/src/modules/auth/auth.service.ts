import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { UserRole } from '@prisma/client';
import prisma from '../../config/database';
import { config } from '../../config';
import { getVerificationProvider } from '../../services/verification';

const SALT_ROUNDS = 12;

export class AuthService {

  async register(data: {
    email: string;
    phone: string;
    password: string;
    firstName: string;
    lastName: string;
    dateOfBirth: string;
    role: 'CUSTOMER' | 'COURIER';
  }) {

    const existing = await prisma.user.findFirst({
      where: {
        OR: [{ email: data.email }, { phone: data.phone }],
      },
    });

    if (existing) {
      if (existing.email === data.email) {
        throw new Error('Bu e-posta adresi zaten kullanılıyor');
      }
      throw new Error('Bu telefon numarası zaten kullanılıyor');
    }

    const passwordHash = await bcrypt.hash(data.password, SALT_ROUNDS);

    const user = await prisma.user.create({
      data: {
        email: data.email,
        phone: data.phone,
        passwordHash,
        firstName: data.firstName,
        lastName: data.lastName,
        dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : null,
        role: data.role as UserRole,
      },
      select: {
        id: true,
        email: true,
        phone: true,
        firstName: true,
        lastName: true,
        role: true,
        createdAt: true,
      },
    });

    if (data.role === 'COURIER') {
      await prisma.courierProfile.create({
        data: {
          userId: user.id,
          baseFee: 100,
        },
      });
    }

    const tokens = this.generateTokens(user.id, user.email, user.role);
    await this.saveRefreshToken(user.id, tokens.refreshToken);

    return { user, ...tokens };
  }

  async login(email: string, password: string) {
    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        phone: true,
        passwordHash: true,
        firstName: true,
        lastName: true,
        role: true,
        isActive: true,
        phoneVerified: true,
        emailVerified: true,
      },
    });

    if (!user || !user.isActive) {
      throw new Error('Geçersiz e-posta veya şifre');
    }

    if (user.role === 'ADMIN' || user.role === 'EMPLOYEE') {
      throw new Error('Bu giriş yöntemi bu hesap türü için kullanılamaz');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new Error('Geçersiz e-posta veya şifre');
    }

    const tokens = this.generateTokens(user.id, user.email, user.role);
    await this.saveRefreshToken(user.id, tokens.refreshToken);

    const { passwordHash: _, ...userWithoutPassword } = user;
    return { user: userWithoutPassword, ...tokens };
  }

  async adminLogin(email: string, password: string, pin: string) {
    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        phone: true,
        passwordHash: true,
        adminPinHash: true,
        firstName: true,
        lastName: true,
        role: true,
        isActive: true,
      },
    });

    if (!user || !user.isActive) {
      throw new Error('Geçersiz e-posta adresi veya hesap aktif değil');
    }

    if (user.role !== 'ADMIN') {
      throw new Error('Bu hesap Admin yetkisine sahip değil');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new Error('Girdiğiniz şifre hatalı');
    }

    if (!user.adminPinHash) {
      throw new Error('Admin PIN kodu tanımlanmamış');
    }

    const isPinValid = await bcrypt.compare(pin, user.adminPinHash);
    if (!isPinValid) {
      throw new Error('Girdiğiniz 6 haneli PIN kodu hatalı');
    }

    const tokens = this.generateTokens(user.id, user.email, user.role);
    await this.saveRefreshToken(user.id, tokens.refreshToken);

    const { passwordHash: _, adminPinHash: __, ...userWithoutSecrets } = user;
    return { user: userWithoutSecrets, ...tokens };
  }

  async employeeLogin(email: string, password: string) {
    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        phone: true,
        passwordHash: true,
        firstName: true,
        lastName: true,
        role: true,
        isActive: true,
      },
    });

    if (!user || !user.isActive || user.role !== 'EMPLOYEE') {
      throw new Error('Geçersiz kimlik bilgileri');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new Error('Geçersiz kimlik bilgileri');
    }

    const tokens = this.generateTokens(user.id, user.email, user.role);
    await this.saveRefreshToken(user.id, tokens.refreshToken);

    const { passwordHash: _, ...userWithoutPassword } = user;
    return { user: userWithoutPassword, ...tokens };
  }

  async refreshToken(refreshToken: string) {
    const decoded = jwt.verify(refreshToken, config.jwt.refreshSecret) as {
      id: string;
      email: string;
      role: UserRole;
    };

    const storedToken = await prisma.refreshToken.findUnique({
      where: { token: refreshToken },
    });

    if (!storedToken || storedToken.revoked || storedToken.expiresAt < new Date()) {
      throw new Error('Geçersiz veya süresi dolmuş refresh token');
    }

    const userExists = await prisma.user.findUnique({ where: { id: decoded.id } });
    if (!userExists || !userExists.isActive) {
      throw new Error('Kullanıcı bulunamadı veya hesabı aktif değil');
    }

    await prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: { revoked: true },
    });

    const tokens = this.generateTokens(userExists.id, userExists.email, userExists.role);
    await this.saveRefreshToken(userExists.id, tokens.refreshToken);

    return tokens;
  }

  async logout(refreshToken: string) {
    await prisma.refreshToken.updateMany({
      where: { token: refreshToken },
      data: { revoked: true },
    });
  }

  async sendVerificationCode(userId: string, target: string, channel: 'sms' | 'email') {
    const provider = getVerificationProvider();
    const code = await provider.sendCode(target, channel);

    await prisma.verificationCode.create({
      data: {
        userId,
        code,
        channel,
        target,
        expiresAt: new Date(Date.now() + config.verification.codeExpiry),
      },
    });

    return { message: 'Doğrulama kodu gönderildi' };
  }

  async verifyCode(userId: string, target: string, code: string, channel: 'sms' | 'email') {
    const storedCode = await prisma.verificationCode.findFirst({
      where: {
        userId,
        target,
        channel,
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!storedCode) {
      throw new Error('Doğrulama kodu bulunamadı veya süresi dolmuş');
    }

    const provider = getVerificationProvider();
    const isValid = await provider.verifyCode(target, code, storedCode.code);

    if (!isValid) {
      throw new Error('Geçersiz doğrulama kodu');
    }

    await prisma.verificationCode.update({
      where: { id: storedCode.id },
      data: { used: true },
    });

    if (channel === 'sms') {
      await prisma.user.update({
        where: { id: userId },
        data: { phoneVerified: 'VERIFIED' },
      });
    } else {
      await prisma.user.update({
        where: { id: userId },
        data: { emailVerified: 'VERIFIED' },
      });
    }

    return { message: 'Doğrulama başarılı', verified: true };
  }

  async forgotPassword(email: string) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {

      return { message: 'Eğer bu e-posta kayıtlıysa, şifre sıfırlama kodu gönderildi' };
    }

    const provider = getVerificationProvider();
    const code = await provider.sendCode(email, 'email');

    await prisma.verificationCode.create({
      data: {
        userId: user.id,
        code,
        channel: 'email',
        target: email,
        expiresAt: new Date(Date.now() + config.verification.codeExpiry),
      },
    });

    return { message: 'Eğer bu e-posta kayıtlıysa, şifre sıfırlama kodu gönderildi' };
  }

  async resetPassword(email: string, code: string, newPassword: string) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      throw new Error('Geçersiz istek');
    }

    const storedCode = await prisma.verificationCode.findFirst({
      where: {
        userId: user.id,
        target: email,
        channel: 'email',
        used: false,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!storedCode || storedCode.code !== code) {
      throw new Error('Geçersiz veya süresi dolmuş kod');
    }

    const passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);

    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    await prisma.verificationCode.update({
      where: { id: storedCode.id },
      data: { used: true },
    });

    await prisma.refreshToken.updateMany({
      where: { userId: user.id },
      data: { revoked: true },
    });

    return { message: 'Şifre başarıyla sıfırlandı' };
  }

  private generateTokens(userId: string, email: string, role: UserRole) {
    const accessToken = jwt.sign(
      { id: userId, email, role },
      config.jwt.secret,
      { expiresIn: config.jwt.accessExpiry as any }
    );

    const refreshToken = jwt.sign(
      { id: userId, email, role },
      config.jwt.refreshSecret,
      { expiresIn: config.jwt.refreshExpiry as any }
    );

    return { accessToken, refreshToken };
  }

  private async saveRefreshToken(userId: string, token: string) {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await prisma.refreshToken.create({
      data: {
        token,
        userId,
        expiresAt,
      },
    });
  }

  async changePassword(userId: string, currentPass: string, newPass: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error('Kullanıcı bulunamadı');

    const isValid = await bcrypt.compare(currentPass, user.passwordHash);
    if (!isValid) throw new Error('Mevcut şifreniz yanlış');

    if (newPass.length < 8) {
      throw new Error('Yeni şifre en az 8 karakter olmalıdır');
    }

    const newPasswordHash = await bcrypt.hash(newPass, SALT_ROUNDS);
    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash: newPasswordHash },
    });

    return { message: 'Şifreniz başarıyla değiştirildi' };
  }
}

export const authService = new AuthService();

