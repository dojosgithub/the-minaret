# Flutter Minaret App

## Project Overview
A full-stack social media application built with Flutter and Node.js.

## Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Node.js (v14 or higher)
- MongoDB (v4.4 or higher)
- Git

## Installation Steps

### 1. Database Setup
```bash
# Start MongoDB
# Windows
net start MongoDB

# macOS
brew services start mongodb-community

# Linux
sudo systemctl start mongod
```

### 2. Backend Setup
```bash
# Navigate to backend directory
cd minaret-backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Update .env with your configuration:
MONGODB_URI=mongodb://localhost:27017/minaret
JWT_SECRET=e2aae21e26d37fed7f62f8d2e0e9abc5ace40eab586753a604ce4cc7475374a1
PORT=5000

# Seed the database with initial data
node scripts/seedData.js

# Start the backend server
npm start
```

### 3. Flutter Setup
```bash
# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

## Development Setup

### Backend Development
```bash
cd minaret-backend
npm install
npm run dev  # Runs with nodemon for hot reload
```

### Frontend Development
```bash
# Run with hot reload
flutter run

# Build for release
flutter build apk  # For Android
flutter build ios  # For iOS
```

## API Configuration

### Local Development
Update `lib/services/api_service.dart` with the correct backend URL:

- Android Emulator: `http://10.0.2.2:5000/api`
- iOS Simulator: `http://localhost:5000/api`
- Physical Device: `http://your.computer.ip:5000/api`

### Production
Update the API URL in `api_service.dart` with your production backend URL.

## Testing

### Backend Tests
```bash
cd minaret-backend
npm test
```

### Flutter Tests
```bash
flutter test
```

## Common Issues & Solutions

### Backend Connection Issues
1. Verify MongoDB is running:
```bash
mongo --eval "db.version()"
```

2. Check backend status:
```bash
curl http://localhost:5000/api/test
```

3. For physical devices:
- Ensure device and computer are on same network
- Configure firewall to allow port 5000
- Use correct IP address in API configuration

### Registration Issues
- Username must be unique
- Password must be at least 8 characters
- Phone number must be unique and in valid format
- All fields are required

## Contributing
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License
Property of Dojo IT Solutions.


## App Theme
- Primary background color: `#4F245A`
- Post background color: Darker shade `#3D1B45`
- Profile picture circle: `#FFE4A7`






