const { PrismaClient } = require('@prisma/client');
const config = require('./backend/dev-config.json');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: config.database.url
    }
  }
});

async function setupDatabase() {
  try {
    console.log('🔌 Connecting to database...');
    await prisma.$connect();
    console.log('✅ Database connected successfully!');
    
    console.log('🔧 Generating Prisma client...');
    const { execSync } = require('child_process');
    execSync('npx prisma generate', { stdio: 'inherit' });
    console.log('✅ Prisma client generated!');
    
    console.log('📊 Pushing database schema...');
    execSync('npx prisma db push', { stdio: 'inherit' });
    console.log('✅ Database schema pushed!');
    
    console.log('🌱 Seeding sample data...');
    await seedSampleData();
    console.log('✅ Sample data seeded!');
    
    console.log('🎉 Database setup completed successfully!');
    
  } catch (error) {
    console.error('❌ Database setup failed:', error);
    console.log('💡 Make sure PostgreSQL is running with: docker-compose up -d');
  } finally {
    await prisma.$disconnect();
  }
}

async function seedSampleData() {
  try {
    // Check if users exist
    const userCount = await prisma.user.count();
    if (userCount > 0) {
      console.log('📝 Users already exist, skipping seed...');
      return;
    }
    
    // Create sample user
    const user = await prisma.user.create({
      data: {
        name: 'Test User',
        username: 'testuser',
        email: 'test@example.com',
        password: '$2b$10$example.hash.here', // This is just a placeholder
        dailyCP: 100,
        lifetimeCP: 500,
        daysActive: 5
      }
    });
    
    // Create sample tasks
    await prisma.task.createMany({
      data: [
        {
          title: 'Complete project setup',
          description: 'Finish setting up the development environment',
          category: 'Development',
          priority: 'high',
          userId: user.id
        },
        {
          title: 'Write documentation',
          description: 'Create comprehensive project documentation',
          category: 'Documentation',
          priority: 'medium',
          userId: user.id
        }
      ]
    });
    
    // Create sample group
    await prisma.group.create({
      data: {
        name: 'Development Team',
        description: 'Team for development collaboration',
        category: 'Development',
        createdBy: user.id,
        members: {
          connect: { id: user.id }
        }
      }
    });
    
    console.log('✅ Sample data created successfully!');
    
  } catch (error) {
    console.error('❌ Error seeding data:', error);
  }
}

if (require.main === module) {
  setupDatabase();
}

module.exports = { setupDatabase };
