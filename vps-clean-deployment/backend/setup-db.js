const { PrismaClient } = require('@prisma/client');
const config = require('./dev-config.json');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: config.database.url
    }
  }
});

async function setupDatabase() {
  try {
    console.log('🚀 Setting up database...');
    
    // Test connection
    await prisma.$connect();
    console.log('✅ Database connection successful');
    
    // Generate Prisma client
    console.log('📦 Generating Prisma client...');
    const { execSync } = require('child_process');
    execSync('npx prisma generate', { stdio: 'inherit' });
    console.log('✅ Prisma client generated');
    
    // Push schema to database
    console.log('🗄️ Pushing schema to database...');
    execSync('npx prisma db push', { stdio: 'inherit' });
    console.log('✅ Database schema updated');
    
    // Seed with sample data (optional)
    console.log('🌱 Seeding database with sample data...');
    await seedSampleData();
    console.log('✅ Sample data seeded');
    
    console.log('\n🎉 Database setup completed successfully!');
    console.log('💡 You can now start the backend server with: npm run dev');
    
  } catch (error) {
    console.error('❌ Database setup failed:', error);
    console.log('\n💡 Troubleshooting tips:');
    console.log('1. Make sure PostgreSQL is running: docker-compose up -d');
    console.log('2. Check if the database exists');
    console.log('3. Verify connection details in dev-config.json');
  } finally {
    await prisma.$disconnect();
  }
}

async function seedSampleData() {
  try {
    // Check if users already exist
    const userCount = await prisma.user.count();
    if (userCount > 0) {
      console.log('📝 Database already has data, skipping seed');
      return;
    }

    // Create sample user
    const sampleUser = await prisma.user.create({
      data: {
        name: 'Sample User',
        username: 'sampleuser',
        email: 'sample@example.com',
        password: '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
        dailyCP: 15,
        lifetimeCP: 150,
        daysActive: 10,
        startDate: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        lastActiveDate: new Date().toISOString().split('T')[0]
      }
    });

    // Create sample tasks
    const sampleTasks = await Promise.all([
      prisma.task.create({
        data: {
          title: 'Morning Exercise',
          description: '30 minutes of cardio',
          category: 'BODY',
          priority: 'high',
          estimatedTime: 30,
          userId: sampleUser.id
        }
      }),
      prisma.task.create({
        data: {
          title: 'Read 20 pages',
          description: 'Continue reading current book',
          category: 'MIND',
          priority: 'medium',
          estimatedTime: 45,
          userId: sampleUser.id
        }
      }),
      prisma.task.create({
        data: {
          title: 'Meditation',
          description: '15 minutes of mindfulness',
          category: 'SOUL',
          priority: 'high',
          estimatedTime: 15,
          userId: sampleUser.id
        }
      })
    ]);

    // Create sample group
    const sampleGroup = await prisma.group.create({
      data: {
        name: 'Fitness Enthusiasts',
        description: 'A group for people who love staying fit and healthy',
        category: 'BODY',
        isPrivate: false,
        createdBy: sampleUser.id,
        members: {
          connect: { id: sampleUser.id }
        }
      }
    });

    console.log(`✅ Created sample user: ${sampleUser.username}`);
    console.log(`✅ Created ${sampleTasks.length} sample tasks`);
    console.log(`✅ Created sample group: ${sampleGroup.name}`);

  } catch (error) {
    console.error('❌ Seeding failed:', error);
  }
}

// Run setup if this file is executed directly
if (require.main === module) {
  setupDatabase();
}

module.exports = { setupDatabase };
