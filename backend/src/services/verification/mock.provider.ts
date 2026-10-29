import { VerificationProvider } from './verification.interface';
import { config } from '../../config';

export class MockVerificationProvider implements VerificationProvider {
  readonly name = 'mock';

  async sendCode(target: string, channel: 'sms' | 'email'): Promise<string> {
    const code = config.verification.mockCode;

    if (channel === 'sms') {
      console.log(`[MockSMS] 📱 Doğrulama kodu gönderildi`);
      console.log(`[MockSMS]    Telefon: ${target}`);
      console.log(`[MockSMS]    Kod: ${code}`);
    } else {
      console.log(`[MockEmail] 📧 Doğrulama kodu gönderildi`);
      console.log(`[MockEmail]    E-posta: ${target}`);
      console.log(`[MockEmail]    Kod: ${code}`);
    }

    return code;
  }

  async verifyCode(_target: string, code: string, expectedCode: string): Promise<boolean> {
    const isValid = code === expectedCode;
    console.log(`[MockVerification] Kod doğrulama: ${isValid ? '✅ Başarılı' : '❌ Başarısız'}`);
    return isValid;
  }
}

