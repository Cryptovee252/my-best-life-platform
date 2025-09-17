const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function testConnection() {
  try {
    console.log('🔍 Testing Prisma connection...');
    
    // Test basic connection
    await prisma.$connect();
    console.log('✅ Prisma connection successful');
    
    // Test a simple query
    const userCount = await prisma.user.count();
    console.log(`✅ User count query successful: ${userCount} users`);
    
    // Test finding a specific user
    const user = await prisma.user.findUnique({
      where: { email: 'test@example.com' }
    });
    
    if (user) {
      console.log(`✅ Found user: ${user.name} (${user.email})`);
    } else {
      console.log('⚠️ No user found with test@example.com');
    }
    
  } catch (error) {
    console.error('❌ Prisma test failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

testConnection();
