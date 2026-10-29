import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🧹 Clearing non-user application data...');

  await prisma.$transaction([
    prisma.cartItem.deleteMany(),
    prisma.cart.deleteMany(),
    prisma.orderItem.deleteMany(),
    prisma.orderStatusHistory.deleteMany(),
    prisma.payment.deleteMany(),
    prisma.rating.deleteMany(),
    prisma.favorite.deleteMany(),
    prisma.order.deleteMany(),
    prisma.vendorProduct.deleteMany(),
    prisma.vendor.deleteMany(),
    prisma.product.deleteMany(),
    prisma.productCategory.deleteMany(),
    prisma.employeeAssignment.deleteMany(),
    prisma.market.deleteMany(),
    prisma.notification.deleteMany(),
    prisma.address.deleteMany(),
  ]);

  console.log('✅ All test data (markets, products, orders, carts, addresses, ratings) cleared successfully!');
  console.log('👤 User accounts, courier profiles, and login tokens have been preserved.');
}

main()
  .catch((e) => {
    console.error('❌ Cleanup failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

