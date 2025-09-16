# HelpMyBestLife Platform

[![CI/CD](https://github.com/Cryptovee252/my-best-life-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/Cryptovee252/my-best-life-platform/actions/workflows/ci.yml)
[![Deploy](https://github.com/Cryptovee252/my-best-life-platform/actions/workflows/deploy.yml/badge.svg)](https://github.com/Cryptovee252/my-best-life-platform/actions/workflows/deploy.yml)
[![License: ISC](https://img.shields.io/badge/License-ISC-blue.svg)](https://opensource.org/licenses/ISC)
[![GitHub stars](https://img.shields.io/github/stars/Cryptovee252/my-best-life-platform.svg)](https://github.com/Cryptovee252/my-best-life-platform/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Cryptovee252/my-best-life-platform.svg)](https://github.com/Cryptovee252/my-best-life-platform/network)

A comprehensive React Native/Expo app focused on personal development through commitment points (CP) across three categories: Mind, Body, and Soul.

🌐 **Live Demo**: [View on GitHub Pages](https://cryptovee252.github.io/my-best-life-platform/)  
📱 **Repository**: [GitHub Repository](https://github.com/Cryptovee252/my-best-life-platform)

## 🚀 Features

### Core Functionality
- **Daily Task Management**: Complete tasks in Mind, Body, and Soul categories
- **Commitment Points (CP) System**: Track daily and lifetime CP across categories
- **Equilibrium Tracking**: Visual representation of CP balance across categories
- **Group Collaboration**: Create and join groups for shared goals
- **Notifications**: Real-time notifications for achievements and updates
- **Profile Management**: User profiles with statistics and progress tracking

### Technical Features
- **Real-time Data Sync**: Automatic synchronization between local storage and backend
- **Daily Reset**: Tasks automatically reset at midnight
- **Offline Support**: Works offline with local storage
- **Cross-platform**: iOS, Android, and Web support
- **Modern UI/UX**: Dark theme with intuitive navigation

## 🏗️ Architecture

### Frontend (React Native/Expo)
- **Framework**: Expo Router with TypeScript
- **State Management**: React Context API
- **Storage**: AsyncStorage for local data persistence
- **Navigation**: Bottom tab navigation with modal support

### Backend (Node.js/Express)
- **Framework**: Express.js with MongoDB
- **Authentication**: JWT-based authentication
- **Database**: MongoDB with Mongoose ODM
- **API**: RESTful API with comprehensive endpoints

## 📁 Project Structure

```
HelpMyBestLife/
├── app/                    # Expo Router pages
│   ├── (tabs)/            # Tab navigation screens
│   ├── mind.tsx           # Mind category tasks
│   ├── body.tsx           # Body category tasks
│   └── soul.tsx           # Soul category tasks
├── components/            # Reusable components
│   ├── CommitmentContext.tsx  # CP state management
│   ├── UserContext.tsx        # User state management
│   ├── GroupContext.tsx       # Group state management
│   └── NotificationContext.tsx # Notification management
├── assets/               # Images, fonts, etc.
└── constants/           # App constants

backend/
├── routes/              # API routes
│   ├── auth.js         # Authentication endpoints
│   ├── tasks.js        # Task management
│   ├── groups.js       # Group management
│   ├── users.js        # User management
│   └── notifications.js # Notification endpoints
├── models/             # Database models
│   ├── User.js         # User model
│   ├── Task.js         # Task model
│   ├── Group.js        # Group model
│   └── Notification.js # Notification model
├── middleware/         # Express middleware
│   └── auth.js         # Authentication middleware
└── app.js             # Main server file
```

## 🚀 Getting Started

### Prerequisites
- Node.js (>=16.0.0)
- npm or yarn
- Expo CLI
- MongoDB (local or cloud)

### Frontend Setup
1. Navigate to the HelpMyBestLife directory:
   ```bash
   cd HelpMyBestLife
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npx expo start
   ```

4. Run on your preferred platform:
   - iOS: Press `i` in the terminal or scan QR code with Expo Go
   - Android: Press `a` in the terminal or scan QR code with Expo Go
   - Web: Press `w` in the terminal

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file with your configuration:
   ```env
   MONGO_URI=mongodb://localhost:27017/helpmybestlife
   JWT_SECRET=your-super-secret-jwt-key
   PORT=5000
   NODE_ENV=development
   ```

4. Start the server:
   ```bash
   npm run dev
   ```

## 📊 Commitment Points System

### Daily CP
- Each task completed earns 1 CP
- Daily CP resets at midnight
- Maximum 10 CP per category per day (30 total)

### Lifetime CP
- Accumulates all CP earned over time
- Never resets
- Tracks progress across all categories

### Equilibrium
- Visual representation of CP balance
- Goal: 33% in each category (Mind, Body, Soul)
- Tap to view detailed statistics

## 🎯 Task Categories

### Mind Tasks
1. Make Someone's Day Awesome!
2. Accomplish a Goal / Set a New Goal
3. Read a Book / Audiobook / Podcast
4. Learn Something New
5. Positively Influence Your Network
6. Teach Someone Something of Importance to Them
7. Embrace New Language / Culture / Perspective or Feedback
8. Resolve a Complicated Issue/ Problem/ Situation
9. Start a New Project
10. Practice Mindfulness or Meditation

### Body Tasks
1. Exercise / Workout
2. Eat Healthy / Drink Water
3. Get Enough Sleep
4. Take a Walk / Go Outside
5. Stretch / Yoga
6. Practice Good Posture
7. Take the Stairs
8. Dance / Move to Music
9. Try a New Sport / Activity
10. Take a Cold Shower

### Soul Tasks
1. Practice Gratitude
2. Help Someone in Need
3. Connect with Nature
4. Practice Kindness
5. Meditate / Pray
6. Listen to Uplifting Music
7. Spend Time with Loved Ones
8. Practice Forgiveness
9. Express Creativity
10. Reflect on Your Values

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Tasks
- `GET /api/tasks` - Get user's tasks
- `POST /api/tasks/complete` - Complete a task
- `POST /api/tasks/uncomplete` - Uncomplete a task

### Groups
- `GET /api/groups` - Get user's groups
- `POST /api/groups` - Create a new group
- `POST /api/groups/join` - Join a group
- `POST /api/groups/leave` - Leave a group
- `GET /api/groups/:id` - Get group details

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `GET /api/users/stats` - Get user statistics
- `POST /api/users/reset-daily` - Reset daily CP

### Notifications
- `GET /api/notifications` - Get user's notifications
- `PUT /api/notifications/:id/read` - Mark notification as read
- `PUT /api/notifications/read-all` - Mark all notifications as read
- `DELETE /api/notifications/:id` - Delete a notification
- `DELETE /api/notifications` - Clear all notifications

## 🎨 UI/UX Features

### Design System
- **Color Scheme**: Dark theme with accent colors
  - Mind: Green (#2ecc40)
  - Body: Blue (#0074d9)
  - Soul: Red (#ff4136)
  - Background: Dark (#111)
  - Text: White (#fff)

### Navigation
- Bottom tab navigation
- Modal overlays for forms
- Smooth transitions and animations
- Intuitive gesture support

### Accessibility
- High contrast colors
- Readable typography
- Touch-friendly buttons
- Screen reader support

## 🔒 Security

### Authentication
- JWT-based authentication
- Secure password hashing with bcrypt
- Token expiration and refresh
- Protected routes with middleware

### Data Protection
- Input validation and sanitization
- CORS configuration
- Rate limiting
- Error handling without sensitive data exposure

## 🧪 Testing

### Frontend Testing
```bash
cd HelpMyBestLife
npm test
```

### Backend Testing
```bash
cd backend
npm test
```

## 📱 Platform Support

### Mobile
- iOS 13+ (Expo SDK 53)
- Android 8+ (API level 26+)

### Web
- Modern browsers (Chrome, Firefox, Safari, Edge)
- Progressive Web App (PWA) support

## 🚀 Deployment

### Frontend Deployment
1. Build for production:
   ```bash
   npx expo build:web
   ```

2. Deploy to hosting service (Vercel, Netlify, etc.)

### Backend Deployment
1. Set environment variables
2. Deploy to cloud platform (Heroku, AWS, etc.)
3. Configure MongoDB connection

## 🔄 GitHub Workflow

### Getting Started with Git
```bash
# Clone the repository
git clone https://github.com/Cryptovee252/my-best-life-platform.git
cd my-best-life-platform

# Install dependencies
cd HelpMyBestLife && npm install
cd ../backend && npm install
```

### Making Changes
```bash
# Create a new branch for your feature
git checkout -b feature/your-feature-name

# Make your changes, then commit
git add .
git commit -m "Add: your feature description"

# Push to GitHub
git push origin feature/your-feature-name
```

### Pull Request Process
1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
4. **Commit** your changes (`git commit -m 'Add amazing feature'`)
5. **Push** to your branch (`git push origin feature/amazing-feature`)
6. **Open** a Pull Request on GitHub

### Branch Strategy
- `main` - Production-ready code
- `develop` - Development branch for features
- `feature/*` - Individual features
- `hotfix/*` - Critical bug fixes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines
- Follow the existing code style
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed
- Ensure all CI checks pass

## 📄 License

This project is licensed under the ISC License.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Contact the development team

## 🔄 Changelog

### Version 1.0.0
- Initial release
- Core CP system implementation
- Group functionality
- Real-time notifications
- Cross-platform support 