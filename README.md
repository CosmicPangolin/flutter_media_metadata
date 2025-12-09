# flutter_media_metadata

A Flutter plugin to read metadata of media files. Supports streaming/chunked reading on web for memory efficiency.

[![pub package](https://img.shields.io/pub/v/flutter_media_metadata.svg)](https://pub.dev/packages/flutter_media_metadata)

## Features

- 🎵 **Audio metadata**: title, artist, album, year, genre, BPM, and more
- 🎬 **Video metadata**: resolution, frame rate, codec, bitrate
- 🖼️ **Album art extraction**: with MIME type detection
- 🌐 **Web streaming**: chunked reading via mediainfo.js (no full file buffering!)
- 📱 **Cross-platform**: Windows, Linux, macOS, Android, iOS, and Web
- ⚙️ **Configurable**: options to skip album art, customize chunk size
- 🛡️ **Typed errors**: comprehensive exception hierarchy

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_media_metadata: ^2.0.0
```

## Quick Start

### Native Platforms (Windows, Linux, macOS, Android, iOS)

```dart
import 'dart:io';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

final metadata = await MetadataRetriever.fromFile(File('/path/to/audio.mp3'));

print(metadata.trackName);        // "Song Title"
print(metadata.trackArtistNames); // ["Artist 1", "Artist 2"]
print(metadata.albumName);        // "Album Name"
print(metadata.durationString);   // "3:45"
print(metadata.bitrateString);    // "320 kbps"
```

### Web Platform

1. Add scripts to your `web/index.html`:

```html
<head>
  <!-- Add before </head> -->
  <script src="https://unpkg.com/mediainfo.js/dist/mediainfo.min.js"></script>
  <script src="mediainfo_bridge.js"></script>
</head>
```

2. Copy `mediainfo_bridge.js` from the package's `web/` folder to your project's `web/` folder.

3. Use the web-specific API:

```dart
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

// From a File object (uses chunked streaming - most memory efficient!)
final metadata = await MetadataRetriever.fromFile(webFile);

// From bytes (when you already have the data)
final metadata = await MetadataRetriever.fromBytes(bytes);

// From a URL using HTTP Range requests
final metadata = await MetadataRetriever.fromUrl(Uri.parse('https://example.com/audio.mp3'));
```

## Configuration Options

Use `MetadataOptions` to customize extraction:

```dart
final metadata = await MetadataRetriever.fromFile(
  file,
  options: MetadataOptions(
    extractAlbumArt: false,  // Skip album art for faster extraction
    fullMetadata: true,      // Extract all available fields
    chunkSize: 512 * 1024,   // 512KB chunks (web only)
  ),
);

// Or use presets
final metadata = await MetadataRetriever.fromFile(
  file,
  options: MetadataOptions.fast,  // Skip album art, basic metadata only
);
```

## Error Handling

The package provides a hierarchy of typed exceptions:

```dart
try {
  final metadata = await MetadataRetriever.fromFile(file);
} on MetadataLibraryException catch (e) {
  // mediainfo.js not loaded (web only)
  print('Library error: ${e.libraryName}');
} on MediaSourceException catch (e) {
  // File not found, network error, permission denied
  print('Source error: ${e.errorType} - ${e.source}');
} on UnsupportedMediaFormatException catch (e) {
  // File format not supported
  print('Unsupported format: ${e.format}');
} on MetadataExtractionException catch (e) {
  // General extraction failure
  print('Extraction failed: ${e.message}');
} on PlatformNotSupportedException catch (e) {
  // Operation not supported on this platform
  print('Not supported: ${e.operation} on ${e.platform}');
} on MetadataException catch (e) {
  // Catch-all for any metadata error
  print('Error: ${e.message}');
}
```

## Available Metadata Fields

### Basic Track Information

| Field | Type | Description |
|-------|------|-------------|
| `trackName` | `String?` | Track/song title |
| `trackArtistNames` | `List<String>?` | Performing artists |
| `albumName` | `String?` | Album name |
| `albumArtistName` | `String?` | Album artist |
| `trackNumber` | `int?` | Track position in album |
| `albumLength` | `int?` | Total tracks in album |
| `discNumber` | `int?` | Disc number |
| `year` | `int?` | Release year |
| `genre` | `String?` | Genre |
| `authorName` | `String?` | Composer |
| `writerName` | `String?` | Writer/lyricist |
| `bpm` | `int?` | Beats per minute |
| `comment` | `String?` | Comment/description |

### Audio Information

| Field | Type | Description |
|-------|------|-------------|
| `trackDuration` | `double?` | Duration in milliseconds |
| `bitrate` | `int?` | Overall bitrate (bps) |
| `channels` | `int?` | Number of channels |
| `sampleRate` | `int?` | Sample rate (Hz) |
| `bitDepth` | `int?` | Bit depth |
| `audioCodec` | `String?` | Audio codec (e.g., "AAC", "MP3") |
| `audioBitrate` | `int?` | Audio stream bitrate |
| `audioBitrateMode` | `String?` | "CBR" or "VBR" |

### Video Information

| Field | Type | Description |
|-------|------|-------------|
| `width` | `int?` | Video width (pixels) |
| `height` | `int?` | Video height (pixels) |
| `frameRate` | `double?` | Frame rate (fps) |
| `videoCodec` | `String?` | Video codec (e.g., "H.264/AVC") |
| `videoBitrate` | `int?` | Video stream bitrate |
| `videoAspectRatio` | `String?` | Display aspect ratio |

### File Information

| Field | Type | Description |
|-------|------|-------------|
| `mimeType` | `String?` | MIME type |
| `format` | `String?` | Container format |
| `fileSize` | `int?` | File size in bytes |
| `filePath` | `String?` | File path or name |
| `albumArt` | `Uint8List?` | Album art image data |
| `albumArtMimeType` | `String?` | Album art MIME type |

### Helper Getters

```dart
metadata.hasVideo        // true if video metadata exists
metadata.hasAudio        // true if audio metadata exists  
metadata.hasAlbumArt     // true if album art exists
metadata.duration        // Duration object
metadata.durationString  // "3:45" format
metadata.bitrateString   // "320 kbps" format
metadata.sampleRateString // "44.1 kHz" format
metadata.resolutionString // "1920x1080" format
```

## Platform Support

| Platform | Implementation | Streaming |
|----------|---------------|-----------|
| Windows | MediaInfoLib (C++) | File-based |
| Linux | MediaInfoLib (C++) | File-based |
| macOS | AVFoundation (Swift) | File-based |
| iOS | AVFoundation (Swift) | File-based |
| Android | MediaMetadataRetriever + MediaExtractor | File-based |
| Web | mediainfo.js (WASM) | ✅ Chunked streaming |

### Web Streaming

On web, the plugin uses [mediainfo.js](https://github.com/nicholasrice/mediainfo.js) which supports chunked reading. This means:

- **Large files don't block the UI** - only needed chunks are loaded
- **Memory efficient** - entire file isn't buffered
- **Works with URLs** - uses HTTP Range requests for remote files

```dart
// Analyze a remote file without downloading it entirely
final metadata = await MetadataRetriever.fromUrl(
  Uri.parse('https://example.com/large-video.mp4'),
  options: MetadataOptions(
    headers: {'Authorization': 'Bearer token'},
  ),
);
```

## Platform-Specific Notes

### Android
- BPM and Comment fields are not available (Android API limitation)
- Uses `MediaMetadataRetriever` + `MediaExtractor` for comprehensive metadata

### iOS/macOS
- Supports ID3 (MP3) and iTunes (M4A) metadata formats
- Uses AVFoundation for audio/video track analysis

### Windows/Linux
- Full MediaInfoLib support with all metadata fields
- Native album art MIME type detection

## Example App

See the [example](example/) directory for a complete demo app showing:
- File picker integration
- Metadata display with album art
- Options configuration
- Error handling

## Migration from 1.x

### Breaking Changes

1. **Web API changed**: Use `fromFile` with web `File` objects instead of `fromBytes` for streaming support
2. **New exception types**: Catch `MetadataException` subtypes instead of generic exceptions
3. **Options parameter**: New `MetadataOptions` class for configuration

### Migration Steps

```dart
// Before (1.x) - web
final metadata = await MetadataRetriever.fromBytes(bytes);

// After (2.x) - web (preferred - uses streaming)
final metadata = await MetadataRetriever.fromFile(webFile);

// Or if you still have bytes
final metadata = await MetadataRetriever.fromBytes(bytes);
```

## License

MIT License - see [LICENSE](LICENSE) for details.

Copyright (c) 2021-2024 Hitesh Kumar Saini
