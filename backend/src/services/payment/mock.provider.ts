import { v4 as uuidv4 } from 'uuid';
import {
  PaymentProvider,
  PaymentResult,
  PaymentStatus,
  RefundResult,
  CardDetails,
} from './payment.interface';

export class MockPaymentProvider implements PaymentProvider {
  readonly name = 'mock';

  private payments: Map<string, PaymentStatus> = new Map();

  async createPayment(
    amount: number,
    currency: string,
    card: CardDetails,
    metadata: Record<string, any>
  ): Promise<PaymentResult> {
    const paymentId = `mock_pay_${uuidv4()}`;

    if (card.cardNumber === '4000000000000002') {
      console.log(`[MockPayment] ❌ Ödeme başarısız — Tutar: ${amount} ${currency}`);
      this.payments.set(paymentId, {
        paymentId,
        status: 'failed',
        amount,
        currency,
      });
      return {
        success: false,
        paymentId,
        providerRef: `mock_ref_${uuidv4()}`,
        message: 'Kart reddedildi (test kartı)',
      };
    }

    console.log(`[MockPayment] ✅ Ödeme başarılı — Tutar: ${amount} ${currency}`);
    console.log(`[MockPayment]    Kart: ****${card.cardNumber.slice(-4)}, Sipariş: ${metadata.orderId || 'N/A'}`);

    this.payments.set(paymentId, {
      paymentId,
      status: 'completed',
      amount,
      currency,
    });

    return {
      success: true,
      paymentId,
      providerRef: `mock_ref_${uuidv4()}`,
      message: 'Ödeme başarıyla tamamlandı',
    };
  }

  async getPaymentStatus(paymentId: string): Promise<PaymentStatus> {
    const payment = this.payments.get(paymentId);
    if (!payment) {
      return {
        paymentId,
        status: 'pending',
        amount: 0,
        currency: 'TRY',
      };
    }
    return payment;
  }

  async refundPayment(paymentId: string, _amount?: number): Promise<RefundResult> {
    const payment = this.payments.get(paymentId);
    if (payment) {
      payment.status = 'refunded';
    }
    console.log(`[MockPayment] 🔄 İade işlemi — PaymentId: ${paymentId}`);
    return {
      success: true,
      refundId: `mock_refund_${uuidv4()}`,
      message: 'İade başarıyla tamamlandı',
    };
  }
}

