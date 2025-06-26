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
API_BASE_URL= https://the-minaret-f6e46d4294b5.herokuapp.com/api
```

Replace the value with your backend URL as needed (see below for device-specific URLs).


## License
Property of Dojo IT Solutions.


## App Theme
- Primary background color: `#4F245A`
- Post background color: Darker shade `#3D1B45`
- Signature Yellow/Golden Color: `0xFFFDCC87`

## Future Development Tasks

### 1. Cloud Storage for Media
Implement persistent cloud storage for images in posts. Currently, media is saved in a local 'uploads' folder in the Node.js backend which doesn't persist.
- **Related Files**: 
  - `lib/main_screens/post_screen.dart`
  - `minaret-backend/routes/posts.js`
  - `minaret-backend/models/Post.js`
- **Requirements**: Media URLs should be stored in MongoDB with proper cloud storage integration (AWS S3, Firebase Storage, etc.)

### 2. Real-time Messaging
Implement WebSocket functionality for real-time, instant messaging. Current implementation requires manual refresh.
- **Related Files**:
  - `minaret-backend/models/Message.js`
  - `lib/messaging/conversation_screen.dart`
  - `lib/services/api_service.dart`
  - `lib/services/message_service.dart`
- **Suggested Solution**: Implement Socket.io on backend and corresponding client in Flutter

### 3. Performance Optimization
Address noticeable latency in loading content throughout the application. Investigate if issues are related to Heroku backend or MongoDB configuration.
- **Potential Solutions**:
  - Implement caching strategies
  - Optimize database queries
  - Consider upgrading hosting tier or migrating to a different service

### 4. Enhanced Content Filtering
Improve the inappropriate content filtering mechanism. Current implementation uses predefined word lists with 4 filtering levels.
- **Related Files**:
  - `lib/main_screens/home_screen.dart`
  - `lib/services/api_service.dart`
  - `lib/settings/content_filter_screen.dart`
- **Suggested Solution**: Integrate with AI-based content moderation services (AWS Comprehend, Google Cloud Content Moderation, etc.)

### 5. Advanced Post Loading Algorithm
Enhance post loading mechanism to consider engagement metrics (upvotes, comments, shares) and implement across all post categories.
- **Related Files**:
  - `lib/main_screens/home_screen.dart`
  - `lib/utils/post_type.dart`
  - `lib/widgets/post.dart`
- **Current Limitation**: Only loads 10 posts at a time in the "ALL" section

### 6. Video Upload Support
Implement video upload functionality in posts after establishing a suitable cloud storage solution.
- **Dependencies**: Complete Task #1 (Cloud Storage) first
- **Scope**: Include video compression, thumbnail generation, and playback optimization

### 7. Additional Authentication Methods
Complete implementation of sign-in with phone number, WhatsApp, and Telegram. UI screens exist but backend functionality is incomplete.
- **Related Files**:
  - `lib/authentication/continue_with_screen.dart`
  - `lib/authentication/forgot_password_screen.dart`
  - `lib/authentication/phone_screen.dart`
  - `lib/authentication/verification_screen.dart`
- **Requirements**: Backend API endpoints and third-party service integration

### 8. Multi-language Support
Implement internationalization (i18n) to support multiple languages throughout the app.
- **Related Files**:
  - `lib/authentication/welcome_screen.dart`
  - `lib/settings/language_screen.dart`
- **Suggested Approach**: Use Flutter's built-in localization framework with .arb files






