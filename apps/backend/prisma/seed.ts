import { PrismaClient, AdminRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create default admin user
  const adminPassword = await bcrypt.hash('admin123', 10);
  const admin = await prisma.admin.upsert({
    where: { email: 'admin@flowgrid.local' },
    update: {},
    create: {
      email: 'admin@flowgrid.local',
      password: adminPassword,
      name: 'System Admin',
      role: AdminRole.SUPER_ADMIN,
    },
  });
  console.log(`Created admin: ${admin.email}`);

  // Create sample owner
  const ownerPassword = await bcrypt.hash('owner123', 10);
  const owner = await prisma.owner.upsert({
    where: { email: 'owner@example.com' },
    update: {},
    create: {
      email: 'owner@example.com',
      password: ownerPassword,
      name: 'Sample Owner',
      phone: '+1234567890',
    },
  });
  console.log(`Created owner: ${owner.email}`);

  // Create sample consumer
  const consumerPassword = await bcrypt.hash('consumer123', 10);
  const consumer = await prisma.consumer.upsert({
    where: { email: 'consumer@example.com' },
    update: {},
    create: {
      email: 'consumer@example.com',
      displayName: 'sample_consumer',
      password: consumerPassword,
      name: 'Sample Consumer',
      phone: '+0987654321',
    },
  });
  console.log(`Created consumer: ${consumer.email} (@${consumer.displayName})`);

  // Create sample plant
  const existingPlant = await prisma.plant.findFirst({
    where: { name: 'Sample Water Plant' },
  });

  if (!existingPlant) {
    const plant = await prisma.plant.create({
      data: {
        name: 'Sample Water Plant',
        address: '123 Main Street, Sample City',
        latitude: 40.7128,
        longitude: -74.006,
        phone: '+1234567890',
        ownerId: owner.id,
        photos: '[]', // JSON string
      },
    });
    console.log(`Created plant: ${plant.name}`);
  }

  console.log('Seeding completed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
