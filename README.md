# HelpMyBestLife Platform

A full-stack productivity and life management platform built with React Native (Expo) frontend and Node.js backend.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Docker & Docker Compose
- Git

### Local Development Setup

1. **Clone and install dependencies:**
   ```bash
   git clone <your-repo>
   cd helpmybestlife-platform
   npm run install:all
   ```

2. **Set up environment:**
   ```bash
   cp env.local.example .env.local
   # Edit .env.local with your local settings
   ```

3. **Start development environment:**
   ```bash
   npm run dev
   ```
   This will start:
   - PostgreSQL database (Docker)
   - Backend API server (port 5000)
   - Frontend development server (port 3000)

## 📁 Project Structure

```
helpmybestlife-platform/
├── frontend/                 # React Native/Expo app
│   ├── app/                 # App screens and navigation
│   ├── components/          # Reusable components
│   ├── services/           # API services
│   └── package.json
├── backend/                 # Node.js/Express API
│   ├── routes/             # API routes
│   ├── models/             # Database models
│   ├── middleware/         # Auth & security
│   ├── services/           # Business logic
│   ├── prisma/             # Database schema
│   └── package.json
├── scripts/                 # Development & deployment scripts
│   ├── dev-start.js        # Local development starter
│   ├── deploy-staging.js   # Staging deployment
│   ├── deploy-production.js # Production deployment
│   └── backup.js           # Backup utility
├── docs/                    # Documentation
├── backups/                 # Local backups
└── package.json            # Root package.json with workspaces
```

## 🛠 Development Workflow

### Local Development
```bash
# Start everything locally
npm run dev

# Start individual services
npm run dev:backend    # Backend only
npm run dev:frontend   # Frontend only

# Database operations
npm run db:setup       # Set up database
npm run db:studio      # Open Prisma Studio
npm run db:reset       # Reset database
```

### Testing
```bash
npm test              # Run all tests
npm run test:backend  # Backend tests only
npm run test:frontend # Frontend tests only
```

### Building
```bash
npm run build         # Build everything
npm run build:frontend # Frontend build only
npm run build:backend  # Backend build only
```

## 🚀 Deployment Workflow

### Staging Deployment
```bash
npm run deploy:staging
```
This will:
1. Build the project
2. Run tests
3. Commit changes to git
4. Push to staging branch
5. Deploy to VPS staging environment

### Production Deployment
```bash
npm run deploy:production
```
This will:
1. Ensure you're on main branch
2. Pull latest changes
3. Build and test
4. Create backup
5. Commit and push to main
6. Deploy to VPS production

### Manual Backup
```bash
npm run backup
```

## 🔧 Available Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start full development environment |
| `npm run dev:backend` | Start backend server only |
| `npm run dev:frontend` | Start frontend server only |
| `npm run build` | Build all components |
| `npm run test` | Run all tests |
| `npm run db:setup` | Set up database |
| `npm run db:studio` | Open database studio |
| `npm run deploy:staging` | Deploy to staging |
| `npm run deploy:production` | Deploy to production |
| `npm run backup` | Create project backup |
| `npm run clean` | Clean build artifacts |

## 🌐 Environment URLs

- **Frontend (Local)**: http://localhost:3000
- **Backend API (Local)**: http://localhost:5000
- **Database Studio**: http://localhost:5555 (when running `npm run db:studio`)

## 📝 Development Notes

- All development happens locally first
- Changes are committed to git before deployment
- Automated backups are created before production deployments
- Environment variables are managed through `.env.local` for local development
- Docker is used for local database to match production environment

## 🆘 Troubleshooting

### Database Issues
```bash
# Reset database
npm run db:reset

# Check database connection
cd backend && npm run db:studio
```

### Port Conflicts
- Backend: Change `PORT` in `.env.local`
- Frontend: Change `FRONTEND_PORT` in `.env.local`
- Database: Change port in `docker-compose.yml`

### Clean Installation
```bash
npm run clean
npm run install:all
```
