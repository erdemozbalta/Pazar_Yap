import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();
const SALT_ROUNDS = 12;

async function seed() {
  console.log('🌱 Gerçek Yayına Hazır Sıfır Veri Seed İşlemi Başlatılıyor...\n');

  const userPassword = 'User123!@#';
  const userPasswordHash = await bcrypt.hash(userPassword, SALT_ROUNDS);

  const adminEmail = 'admin@pazaryap.com';
  const adminPassword = 'Admin123!@#';
  const adminPin = '123456';
  const adminPasswordHash = await bcrypt.hash(adminPassword, SALT_ROUNDS);
  const pinHash = await bcrypt.hash(adminPin, SALT_ROUNDS);

  await prisma.user.create({
    data: {
      email: adminEmail,
      phone: '+905551234567',
      passwordHash: adminPasswordHash,
      adminPinHash: pinHash,
      firstName: 'Admin',
      lastName: 'PazarYap',
      role: 'ADMIN',
      phoneVerified: 'VERIFIED',
      emailVerified: 'VERIFIED',
      isActive: true,
    },
  });
  console.log(`✅ 1. Admin hesabı oluşturuldu: ${adminEmail} / ${adminPassword}`);

  await prisma.user.create({
    data: {
      email: 'calisan1@pazaryap.com',
      phone: '+905559876543',
      passwordHash: userPasswordHash,
      firstName: 'Ahmet',
      lastName: 'Görevli',
      role: 'EMPLOYEE',
      phoneVerified: 'VERIFIED',
      emailVerified: 'VERIFIED',
      isActive: true,
    },
  });
  console.log(`✅ 2. Çalışan hesabı oluşturuldu: calisan1@pazaryap.com / ${userPassword}`);

  const courierUser = await prisma.user.create({
    data: {
      email: 'kurye1@pazaryap.com',
      phone: '+905558765432',
      passwordHash: userPasswordHash,
      firstName: 'Mehmet',
      lastName: 'Kurye',
      role: 'COURIER',
      phoneVerified: 'VERIFIED',
      emailVerified: 'VERIFIED',
      isActive: true,
    },
  });

  await prisma.courierProfile.create({
    data: {
      userId: courierUser.id,
      isAvailable: true,
      baseFee: 25.0,
      currentLatitude: 40.9875,
      currentLongitude: 29.0250,
    },
  });
  console.log(`✅ 3. Kurye hesabı ve profili oluşturuldu: kurye1@pazaryap.com / ${userPassword}`);

  await prisma.user.create({
    data: {
      email: 'musteri1@pazaryap.com',
      phone: '+905557654321',
      passwordHash: userPasswordHash,
      firstName: 'Ayşe',
      lastName: 'Müşteri',
      role: 'CUSTOMER',
      phoneVerified: 'VERIFIED',
      emailVerified: 'VERIFIED',
      isActive: true,
    },
  });
  console.log(`✅ 4. Müşteri hesabı oluşturuldu: musteri1@pazaryap.com / ${userPassword}`);

  const categories = [
    { name: 'Sebzeler', icon: '🥬', sortOrder: 1 },
    { name: 'Meyveler', icon: '🍎', sortOrder: 2 },
    { name: 'Yeşillikler', icon: '🌿', sortOrder: 3 },
    { name: 'Baklagiller', icon: '🫘', sortOrder: 4 },
    { name: 'Baharatlar', icon: '🌶️', sortOrder: 5 },
    { name: 'Kuruyemişler', icon: '🥜', sortOrder: 6 },
    { name: 'Peynirler', icon: '🧀', sortOrder: 7 },
    { name: 'Zeytinler', icon: '🫒', sortOrder: 8 },
    { name: 'Bal & Reçel', icon: '🍯', sortOrder: 9 },
    { name: 'Unlu Mamuller', icon: '🥐', sortOrder: 10 },
    { name: 'Diğer', icon: '📦', sortOrder: 11 },
  ];

  for (const cat of categories) {
    await prisma.productCategory.create({ data: cat });
  }
  console.log(`✅ ${categories.length} Ürün Kategorisi oluşturuldu`);

  console.log('\n🎉 Gerçek yayın veritabanı tamamen hazır! (0 demo pazar, 0 demo adres)');
}

seed()
  .catch((e) => {
    console.error('❌ Seed hatası:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

