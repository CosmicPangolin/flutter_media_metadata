## 2.0.0

### 🚀 Major Changes

- **Web streaming support**: Uses mediainfo.js chunked reading for memory-efficient analysis
  - No more buffering entire files into memory on web
  - Supports `fromFile`, `fromBytes`, `fromUrl`, and `fromStream` methods
  - HTTP Range requests for remote file analysis

- **Expanded metadata fields**: Now extracts 40+ metadata fields including:
  - Audio: channels, sampleRate, bitDepth, audioCodec, audioBitrate, audioBitrateMode
  - Video: width, height, frameRate, videoCodec, videoBitrate, videoAspectRatio
  - Format: format, formatProfile, fileSize, encodedApplication
  - Additional: bpm, comment, albumArtMimeType

- **Configuration options**: New `MetadataOptions` class
  - `extractAlbumArt` - skip album art for faster extraction
  - `fullMetadata` - extract all vs basic fields
  - `chunkSize` - customize streaming chunk size (web)
  - `headers` - HTTP headers for URL requests (web)

- **Typed exceptions**: Comprehensive error hierarchy
  - `MetadataException` (base class)
  - `MetadataExtractionException` - general extraction failures
  - `MetadataLibraryException` - library not loaded (web)
  - `MediaSourceException` - file/network errors
  - `UnsupportedMediaFormatException` - unsupported formats
  - `PlatformNotSupportedException` - operation not supported

### 🔧 Platform Improvements

**Windows/Linux:**
- Extended metadata extraction from Audio and Video streams
- Album art MIME type detection from MediaInfoLib

**Android:**
- Added MediaExtractor for audio/video track metadata
- Album art MIME type detection via magic bytes
- Fixed video metadata extraction when audio track comes first

**iOS/macOS:**
- Added audio track analysis (channels, sampleRate, bitDepth, codec)
- Added video track analysis (resolution, frameRate, codec)
- Fixed ID3 genre parsing for string values (not just numeric codes)
- Implemented writerName extraction for ID3 tags
- Added BPM and comment extraction
- Album art MIME type detection

**Web:**
- Complete rewrite using modern `dart:js_interop`
- Chunked/streaming file reading via mediainfo.js
- HTTP Range request support for URL analysis
- Custom stream reader API for advanced use cases

### 📦 Dependencies

- Updated to `web: ^1.1.1` (replaced deprecated `package:js`)
- Updated `flutter_lints: ^6.0.0`
- Minimum Dart SDK: `>=3.4.0 <4.0.0`
- Minimum Flutter: `>=3.22.0`

### ⚠️ Breaking Changes

- Web: Removed `MetadataExtractionException` from web exports (use new exception hierarchy)
- Web: `fromFile` now takes `web.File` instead of `dart:io.File`
- All platforms: New exception types may require catch block updates

---

## 1.0.0

- Now supporting all platforms Windows, Linux, macOS, Android, iOS & Web.
- Add web support (@alexmercerind).
- Add iOS support (@DiscombobulatedDrag).
- Revert to using `CompletableFuture` on Android (@alexmercerind).

## 0.1.3

- Add macOS support (@DiscombobulatedDrag).
- Add optional `createNewInstance` argument to `MetadataRetriever.fromFile` (@alexmercerind).
  - Works only on Android.
  - Creates new `MediaMetadataRetriever` instance.
  - Forces `CompletableFuture`.

## 0.1.2

- Add iOS support (@DiscombobulatedDrag)
- Linux: Use `wcstombs` for `std::wstring` conversion (@alexmercerind).
- Linux: Fix segmentation fault with no album art files (@alexmercerind).
- Windows: Fix media having no tags & embedded album art container causing crash (@alexmercerind).
- Windows: Fix UTF16 tags not being parsed properly (@alexmercerind).
- Windows: Add `file_path` to metadata (@alexmercerind).
- Windows & Linux: Fix FLAC album arts (@alexmercerind).
- Windows & Linux: Use Format `Stream_General` for METADATA_BLOCK_PICTURE detection (@alexmercerind).

## 0.1.1

- Added Windows support.
- Moved `MediaMetadataRetriever.setDataSource` & `MediaMetadataRetriever.extractMetadata` calls to another non-UI thread on Android.
- Improved Linux support.
- Added support for embedded album arts on Windows & Linux.
- Changed API to single call, `MetadataRetriever.fromFile`.

## 0.1.0

- Migrated to null-safety
- `trackArtistNames` is now `List<String>` instead of `List<dynamic>`

## 0.0.3+2

- Update documentation.

## 0.0.3

- [media_metadata_retriever](https://github.com/alexmercerind/flutter_media_metadata) is now [flutter_media_metadata](https://github.com/alexmercerind/media_metadata_retriever).
- Added Linux support with album arts.
- Uses [MediaInfoLib](https://github.com/MediaArea/MediaInfoLib) on Linux.

## 0.0.1+4

- Updated Metadata class structure.
- Now bitrate & duration in stored in Metadata itself.

## 0.0.1+3

- More minor changes.

## 0.0.1+2

- Minor updates to documentation.

## 0.0.1

- Support for retriving metadata of a media file in Android.
- Uses [MediaMetadataRetriever](https://developer.android.com/reference/android/media/MediaMetadataRetriever).
