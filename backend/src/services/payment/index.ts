import { PaymentProvider } from './payment.interface';
import { MockPaymentProvider } from './mock.provider';

let paymentProvider: PaymentProvider | null = null;

export function getPaymentProvider(): PaymentProvider {
  if (!paymentProvider) {

    paymentProvider = new MockPaymentProvider();
    console.log(`[Payment] Ödeme sağlayıcısı başlatıldı: ${paymentProvider.name}`);
  }
  return paymentProvider;
}

export * from './payment.interface';

