import prisma from '../config/database';

async function main() {
  console.log('Cleaning pre-seeded dummy products and vendor products...');
  await prisma.cartItem.deleteMany({});
  await prisma.orderItem.deleteMany({});
  await prisma.favorite.deleteMany({});
  await prisma.vendorProduct.deleteMany({});
  await prisma.product.deleteMany({});
  console.log('✅ Database products wiped clean! Employees now start with empty markets.');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

