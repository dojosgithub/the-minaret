# Flutter Minaret App

## Project Overview
This Flutter project is a social media app featuring a bottom navigation bar and customizable post widgets. The app consists of multiple screens, including Home, Notifications, Post, User, and Search screens, with a consistent theme and user-friendly layout.

## Folder Structure
```
lib
|-- main.dart                      # Entry point of the application
|-- screens
|   |-- home_screen.dart           # Home screen implementation
|   |-- notifications_screen.dart  # Notifications screen implementation
|   |-- post_screen.dart           # Post creation screen
|   |-- user_screen.dart           # User profile screen
|   |-- search_screen.dart         # Search screen implementation
|
|-- widgets
|   |-- bottom_nav_bar.dart        # Custom bottom navigation bar with curved edges
|   |-- top_bar.dart               # Custom top bar with profile picture and menu button
|   |-- post.dart                  # Customizable post widget
```

## App Theme
- Primary background color: `#4F245A`
- Post background color: Darker shade `#3D1B45`
- Profile picture circle: `#FFE4A7`

## Post Widget
The `Post` widget displays user-generated content and consists of:
- **Profile picture** with a decorative circle
- **Name** and **Username** displayed vertically
- **Text content** of the post
- **Bookmark icon** (functionality to be added later)

### Post Widget Example
```dart
Post(
  name: 'John Doe',
  username: '@johndoe',
  profilePic: 'assets/profile_picture.png',
  text: 'This is a sample post!',
)
```

## How to Change Background Color
To change the background color of all screens, wrap the `Scaffold` widget in a `Container` with the desired `color`:
```dart
return Container(
  color: const Color(0xFF4F245A),
  child: Scaffold(
    // Screen content here
  ),
);
```

## How to Run
1. Ensure Flutter and Dart are properly set up.
2. Launch the Google Pixel 5 emulator.
3. In VSCode terminal, navigate to the project directory.
4. Run the project:
```bash
flutter run
```

## Future Enhancements
- Implement functionality for the bookmark icon.
- Add interactive features to the top bar and navigation bar.
- Improve post styling and support multimedia content.

