# Fonts Assets

This directory contains font files for the AFO Chat Application.

## Required Font Files (as per pubspec.yaml):

### Roboto Font Family:
- `Roboto-Regular.ttf` - Regular weight
- `Roboto-Bold.ttf` - Bold weight (700)

### OromiOromoo Font Family:
- `OromiOromoo-Regular.ttf` - Regular weight for Afaan Oromoo text
- `OromiOromoo-Bold.ttf` - Bold weight (700) for Afaan Oromoo text

## Font Sources:
- **Roboto**: Available from Google Fonts (https://fonts.google.com/specimen/Roboto)
- **OromiOromoo**: Custom font for Afaan Oromoo language support

## Usage in Flutter:
```dart
Text(
  'Hello World',
  style: TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.normal, // or FontWeight.bold
  ),
)

Text(
  'Afaan Oromoo text',
  style: TextStyle(
    fontFamily: 'OromiOromoo',
    fontWeight: FontWeight.normal,
  ),
)
```

## Installation Instructions:
1. Download the required font files
2. Place them in this `fonts/` directory
3. Ensure the file names match exactly as specified in pubspec.yaml
4. Run `flutter pub get` to register the fonts
5. Restart your app to apply the fonts

## Font File Requirements:
- Format: TrueType (.ttf) or OpenType (.otf)
- Ensure proper licensing for commercial use
- Test fonts with Afaan Oromoo characters if applicable