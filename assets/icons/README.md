# Icons Assets

This directory contains icon assets for the AFO Chat Application.

## Recommended file types:
- `.png` - For raster icons (24x24, 48x48, 72x72, 96x96, etc.)
- `.svg` - For scalable vector icons (with flutter_svg package)
- `.ico` - For Windows app icons

## Suggested organization:
- `navigation/` - Bottom navigation and tab bar icons
- `actions/` - Action buttons (send, call, video, etc.)
- `status/` - Online, offline, typing indicators
- `media/` - Camera, microphone, gallery icons
- `social/` - Share, like, comment icons
- `system/` - Settings, notification, help icons

## App Icon Requirements:
For `afo_logo.png` (referenced in pubspec.yaml):
- iOS: 1024x1024px
- Android: 512x512px (with adaptive icon support)

## Usage in Flutter:
```dart
Icon(Icons.chat) // For Material icons
Image.asset('assets/icons/custom_icon.png') // For custom icons
```

## Note:
The app uses flutter_launcher_icons package for generating platform-specific icons.