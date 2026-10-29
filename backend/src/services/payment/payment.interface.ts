export interface PaymentResult {
  success: boolean;
  paymentId: string;
  providerRef: string;
  message: string;
}

export interface PaymentStatus {
  paymentId: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  amount: number;
  currency: string;
}

export interface RefundResult {
  success: boolean;
  refundId: string;
  message: string;
}

export interface CardDetails {
  cardNumber: string;
  expireMonth: string;
  expireYear: string;
  cvc: string;
  cardHolderName: string;
}

export interface PaymentProvider {
  readonly name: string;

  createPayment(
    amount: number,
    currency: string,
    card: CardDetails,
    metadata: Record<string, any>
  ): Promise<PaymentResult>;

  getPaymentStatus(paymentId: string): Promise<PaymentStatus>;

  refundPayment(paymentId: string, amount?: number): Promise<RefundResult>;
}

