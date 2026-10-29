import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';

dotenv.config();
const prisma = new PrismaClient();

async function cleanData() {
  console.log('🧹 Test verileri siliniyor (Kullanıcı hesapları korunacak)...');

  await prisma.rating.deleteMany({});
  await prisma.payment.deleteMany({});
  await prisma.orderStatusHistory.deleteMany({});
  await prisma.orderItem.deleteMany({});
  await prisma.cartItem.deleteMany({});
  await prisma.order.deleteMany({});
  await prisma.vendorProduct.deleteMany({});
  await prisma.product.deleteMany({});
  await prisma.vendor.deleteMany({});
  await prisma.address.deleteMany({});
  await prisma.notification.deleteMany({});

  console.log('✅ Tüm test siparişleri, tezgahlar, ürünler ve adresler başarıyla temizlendi!');
}

cleanData()
  .catch((e) => {
    console.error('❌ Hata:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

