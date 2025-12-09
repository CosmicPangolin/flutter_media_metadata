/// Native platform implementation for metadata extraction.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

/// Options for metadata extraction
MetadataOptions? _currentOptions;

/// Set the options to use for extraction
void setOptions(MetadataOptions? options) {
  _currentOptions = options;
}

/// Extract metadata from a PlatformFile on native platforms.
Future<Metadata> extractMetadata(PlatformFile file) async {
  if (file.path != null) {
    return await MetadataRetriever.fromFile(
      File(file.path!),
      options: _currentOptions,
    );
  }
  throw MediaSourceException('Could not access file path', source: file.name);
}

/// Get the load method description for native platforms.
String getLoadMethod() {
  final skipArt = _currentOptions?.extractAlbumArt == false;
  return 'Native fromFile()${skipArt ? ' [no album art]' : ''}';
}

/// MediaInfo is not used on native platforms (they use native APIs).
bool isMediaInfoAvailable() => true;

/// No version on native platforms
Future<String?> getMediaInfoVersion() async => null;
