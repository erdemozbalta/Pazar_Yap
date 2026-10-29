import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

  database: {
    url: process.env.DATABASE_URL || '',
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'dev-secret-change-me',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'dev-refresh-secret-change-me',
    accessExpiry: process.env.JWT_ACCESS_EXPIRY || '15m',
    refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '7d',
  },

  admin: {
    email: process.env.ADMIN_EMAIL || 'admin@pazaryap.com',
    password: process.env.ADMIN_PASSWORD || 'Admin123!@#',
    phone: process.env.ADMIN_PHONE || '+905551234567',
    pin: process.env.ADMIN_PIN || '123456',
    firstName: process.env.ADMIN_FIRST_NAME || 'Admin',
    lastName: process.env.ADMIN_LAST_NAME || 'PazarYap',
  },

  upload: {
    dir: process.env.UPLOAD_DIR || './uploads',
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE || '5242880', 10),
  },

  verification: {
    codeLength: 6,
    codeExpiry: 5 * 60 * 1000,
    mockCode: '123456',
  },
};

