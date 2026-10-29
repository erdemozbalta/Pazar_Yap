import { VerificationProvider } from './verification.interface';
import { MockVerificationProvider } from './mock.provider';

let verificationProvider: VerificationProvider | null = null;

export function getVerificationProvider(): VerificationProvider {
  if (!verificationProvider) {
    verificationProvider = new MockVerificationProvider();
    console.log(`[Verification] Doğrulama sağlayıcısı başlatıldı: ${verificationProvider.name}`);
  }
  return verificationProvider;
}

export * from './verification.interface';

