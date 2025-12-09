# flutter_media_metadata Example

This example demonstrates all features of the `flutter_media_metadata` package.

## Features Demonstrated

- 📁 **File selection** via file_picker
- 🎵 **Metadata extraction** with comprehensive field display
- 🖼️ **Album art display** with MIME type detection
- ⚙️ **Options configuration** (toggle album art extraction, full metadata)
- 🚫 **Error handling** with typed exceptions
- 🌐 **Web streaming** via mediainfo.js chunked reading
- ⏱️ **Performance timing** for extraction operations

## Running the Example

### Desktop (Windows/Linux/macOS)

```bash
cd example
flutter run -d windows  # or linux, macos
```

### Android

```bash
cd example
flutter run -d android
```

### iOS

```bash
cd example
flutter run -d ios
```

### Web

1. Make sure `mediainfo_bridge.js` is in the `web/` folder
2. Run:

```bash
cd example
flutter run -d chrome
```

## Web Setup

The example's `web/index.html` includes:

```html
<script src="https://unpkg.com/mediainfo.js/dist/mediainfo.min.js"></script>
<script src="mediainfo_bridge.js"></script>
```

## Screenshot

The app displays:
- Settings button to toggle extraction options
- MediaInfo.js availability indicator (web only)
- Album art with track info header
- Organized metadata sections:
  - Basic Info (title, artist, album, year, genre, etc.)
  - Audio (duration, bitrate, sample rate, codec, etc.)
  - Video (resolution, frame rate, codec - if applicable)
  - File (format, size, path, encoder)

## Code Structure

- `main.dart` - Main app with platform-aware UI
- `main_web.dart` - Web-specific extraction using `web.File`
- `main_stub.dart` - Native platform extraction using `dart:io.File`
