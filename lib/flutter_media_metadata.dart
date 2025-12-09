/// ## flutter_media_metadata
///
/// A Flutter plugin to read metadata of media files.
///
/// MIT License.
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:flutter_media_metadata/flutter_media_metadata.dart';
///
/// // From a file
/// final metadata = await MetadataRetriever.fromFile(file);
///
/// // Access metadata
/// print(metadata.trackName);
/// print(metadata.trackArtistNames);
/// print(metadata.albumName);
/// print(metadata.duration);
/// ```
///
/// ## Web Platform (Streaming/Chunked)
///
/// On web, use [MetadataRetriever.fromFile] for memory-efficient chunked reading:
///
/// ```dart
/// // From a file picker (most efficient - uses chunked reading)
/// final result = await FilePicker.platform.pickFiles();
/// if (result != null && result.files.isNotEmpty) {
///   final file = result.files.first.asWebFile();
///   final metadata = await MetadataRetriever.fromFile(file);
/// }
///
/// // Or from bytes if you already have them
/// final metadata = await MetadataRetriever.fromBytes(bytes);
///
/// // Or from a URL using Range requests
/// final metadata = await MetadataRetriever.fromUrl(Uri.parse('https://example.com/audio.mp3'));
/// ```
///
/// ## Options
///
/// Configure extraction behavior with [MetadataOptions]:
///
/// ```dart
/// final metadata = await MetadataRetriever.fromFile(
///   file,
///   options: MetadataOptions(
///     extractAlbumArt: false, // Skip album art for faster extraction
///     fullMetadata: true,     // Extract all available fields
///   ),
/// );
/// ```
///
/// ## Error Handling
///
/// The package provides a hierarchy of exceptions:
///
/// ```dart
/// try {
///   final metadata = await MetadataRetriever.fromFile(file);
/// } on MetadataLibraryException catch (e) {
///   print('Library not loaded: ${e.message}');
/// } on MediaSourceException catch (e) {
///   print('Source error: ${e.message}');
/// } on UnsupportedMediaFormatException catch (e) {
///   print('Unsupported format: ${e.message}');
/// } on MetadataExtractionException catch (e) {
///   print('Extraction failed: ${e.message}');
/// } on MetadataException catch (e) {
///   print('General error: ${e.message}');
/// }
/// ```
///
/// ## Native Platforms (File-based)
///
/// On native platforms (Windows, Linux, macOS, Android, iOS):
///
/// ```dart
/// import 'dart:io';
///
/// final metadata = await MetadataRetriever.fromFile(File('/path/to/audio.mp3'));
///
/// // Audio metadata
/// String? trackName = metadata.trackName;
/// List<String>? trackArtistNames = metadata.trackArtistNames;
/// String? albumName = metadata.albumName;
/// String? albumArtistName = metadata.albumArtistName;
/// int? trackNumber = metadata.trackNumber;
/// int? albumLength = metadata.albumLength;
/// int? year = metadata.year;
/// String? genre = metadata.genre;
/// int? bitrate = metadata.bitrate;
/// int? sampleRate = metadata.sampleRate;
///
/// // Video metadata (if applicable)
/// int? width = metadata.width;
/// int? height = metadata.height;
/// double? frameRate = metadata.frameRate;
/// String? videoCodec = metadata.videoCodec;
///
/// // Album art
/// Uint8List? albumArt = metadata.albumArt;
/// String? albumArtMimeType = metadata.albumArtMimeType;
/// ```
///
library flutter_media_metadata;

// Platform-specific MetadataRetriever
export 'package:flutter_media_metadata/src/flutter_media_metadata_native.dart'
    if (dart.library.js_interop) 'package:flutter_media_metadata/src/flutter_media_metadata_web.dart';

// Models
export 'package:flutter_media_metadata/src/models/metadata.dart';
export 'package:flutter_media_metadata/src/models/options.dart';
export 'package:flutter_media_metadata/src/models/exceptions.dart';
