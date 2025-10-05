# Images Assets

This directory contains image assets for the AFO Chat Application.

## Recommended file types:
- `.png` - For images with transparency, icons, logos
- `.jpg/.jpeg` - For photos and complex images
- `.svg` - For scalable vector graphics (with flutter_svg package)
- `.webp` - For optimized web images

## Suggested organization:
- `avatars/` - User profile pictures and default avatars
- `backgrounds/` - Chat backgrounds and wallpapers
- `logos/` - App logos and branding images
- `ui/` - UI elements like buttons, decorative images
- `onboarding/` - Images for app introduction screens

## Usage in Flutter:
```dart
Image.asset('assets/images/your_image.png')
```

## Note:
Remember to run `flutter pub get` after adding new assets to pubspec.yaml