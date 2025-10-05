# Sounds Assets

This directory contains audio assets for the AFO Chat Application.

## Recommended file types:
- `.mp3` - For general audio files (good compression)
- `.wav` - For high-quality, uncompressed audio
- `.m4a` - For iOS-optimized audio
- `.ogg` - For web and Android-optimized audio

## Suggested organization:
- `notifications/` - Message received, call incoming sounds
- `ui/` - Button clicks, swipe sounds, feedback tones
- `calls/` - Ringtones, call connecting, disconnect sounds
- `media/` - Camera shutter, recording start/stop sounds
- `alerts/` - Error sounds, warning tones

## Common sounds needed:
- `message_received.mp3` - New message notification
- `incoming_call.mp3` - Incoming voice/video call
- `call_connect.mp3` - Call successfully connected
- `call_disconnect.mp3` - Call ended
- `typing.mp3` - Typing indicator sound
- `button_click.mp3` - UI interaction feedback

## Usage in Flutter:
```dart
// With audioplayers package
AudioPlayer player = AudioPlayer();
await player.play(AssetSource('sounds/message_received.mp3'));

// With flutter_local_notifications
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'channel_id',
  'channel_name',
  sound: RawResourceAndroidNotificationSound('notification_sound'),
);
```
y
## Audio Guidelines:
- Keep file sizes small (< 1MB for notification sounds)
- Use appropriate bitrates (128kbps for most sounds)
- Consider different volumes for different sound types