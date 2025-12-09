/// Web-specific implementation for metadata extraction.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:flutter_media_metadata/src/flutter_media_metadata_web.dart' as web_retriever;
import 'package:web/web.dart' as web;

/// Options for metadata extraction
MetadataOptions? _currentOptions;

/// Set the options to use for extraction
void setOptions(MetadataOptions? options) {
  _currentOptions = options;
}

/// Extract metadata from a PlatformFile on web.
///
/// This uses the chunked/streaming API of mediainfo.js for memory efficiency.
Future<Metadata> extractMetadata(PlatformFile file) async {
  // Create a web File from the bytes
  if (file.bytes != null) {
    final webFile = web.File(
      [file.bytes!.toJS].toJS,
      file.name,
    );
    return await web_retriever.MetadataRetriever.fromFile(
      webFile,
      options: _currentOptions,
    );
  }
  throw MediaSourceException('Could not access file data', source: file.name);
}

/// Extract metadata from bytes (for testing)
Future<Metadata> extractMetadataFromBytes(List<int> bytes, {MetadataOptions? options}) async {
  return await web_retriever.MetadataRetriever.fromBytes(
    bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    options: options ?? _currentOptions,
  );
}

/// Get the load method description for web.
String getLoadMethod() {
  final skipArt = _currentOptions?.extractAlbumArt == false;
  return 'Streaming (chunked) via fromFile()${skipArt ? ' [no album art]' : ''}';
}

/// Check if MediaInfo is available on web.
bool isMediaInfoAvailable() {
  return web_retriever.MetadataRetriever.isAvailable;
}

/// Get the MediaInfo version on web.
Future<String?> getMediaInfoVersion() async {
  return await web_retriever.MetadataRetriever.getVersion();
}
