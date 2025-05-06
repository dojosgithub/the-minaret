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

## Environment Configuration

Create a `.env` file in the root of your Flutter project with the following content:

```
API_BASE_URL=http://10.00.2.2:5000/api
```

Replace the value with your backend URL as needed (see below for device-specific URLs).

The app uses [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) to load environment variables. Make sure to add it to your `pubspec.yaml` dependencies:

```
dependencies:
  flutter_dotenv: ^5.0.2
```

Then run:

```
flutter pub get
```

### API Configuration

- Android Emulator: `http://10.0.2.2:5000/api`
- iOS Simulator: `http://localhost:5000/api`
- Physical Device: `http://your.computer.ip:5000/api`

Update the value of `API_BASE_URL` in your `.env` file accordingly.

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
- Signature Yellow?Golden Color: `0xFFFDCC87`






