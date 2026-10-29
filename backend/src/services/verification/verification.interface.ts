export interface VerificationProvider {
  readonly name: string;

  sendCode(target: string, channel: 'sms' | 'email'): Promise<string>;

  verifyCode(target: string, code: string, expectedCode: string): Promise<boolean>;
}

