/// This file is a part of flutter_media_metadata (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Configuration options for metadata extraction.
///
/// Use this class to customize how metadata is extracted from media files.
///
/// ```dart
/// final metadata = await MetadataRetriever.fromFile(
///   file,
///   options: MetadataOptions(
///     extractAlbumArt: true,
///     fullMetadata: true,
///   ),
/// );
/// ```
class MetadataOptions {
  /// Whether to extract album art/cover image.
  ///
  /// Set to `false` to skip album art extraction, which can significantly
  /// speed up metadata extraction for large cover images.
  ///
  /// Default: `true`
  final bool extractAlbumArt;

  /// Chunk size in bytes for streaming reads (web only).
  ///
  /// Larger chunks mean fewer read operations but more memory usage.
  /// Smaller chunks mean more read operations but less memory usage.
  ///
  /// Default: 262144 (256 KB)
  final int chunkSize;

  /// Whether to extract full/detailed metadata.
  ///
  /// When `true`, extracts all available metadata fields.
  /// When `false`, extracts only basic metadata (faster).
  ///
  /// Default: `true`
  final bool fullMetadata;

  /// HTTP headers to include in requests (web URL analysis only).
  ///
  /// Useful for authenticated requests or custom headers.
  final Map<String, String>? headers;

  /// Create metadata extraction options.
  const MetadataOptions({
    this.extractAlbumArt = true,
    this.chunkSize = 256 * 1024,
    this.fullMetadata = true,
    this.headers,
  });

  /// Default options with all features enabled.
  static const MetadataOptions defaults = MetadataOptions();

  /// Fast options that skip album art extraction.
  static const MetadataOptions fast = MetadataOptions(
    extractAlbumArt: false,
    fullMetadata: false,
  );

  /// Create a copy with some options replaced.
  MetadataOptions copyWith({
    bool? extractAlbumArt,
    int? chunkSize,
    bool? fullMetadata,
    Map<String, String>? headers,
  }) {
    return MetadataOptions(
      extractAlbumArt: extractAlbumArt ?? this.extractAlbumArt,
      chunkSize: chunkSize ?? this.chunkSize,
      fullMetadata: fullMetadata ?? this.fullMetadata,
      headers: headers ?? this.headers,
    );
  }

  /// Convert to a map for passing to JavaScript bridge.
  Map<String, dynamic> toJson() => {
        'coverData': extractAlbumArt,
        'chunkSize': chunkSize,
        'full': fullMetadata,
        if (headers != null) 'headers': headers,
      };

  @override
  String toString() => 'MetadataOptions('
      'extractAlbumArt: $extractAlbumArt, '
      'chunkSize: $chunkSize, '
      'fullMetadata: $fullMetadata, '
      'headers: $headers)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MetadataOptions) return false;
    return extractAlbumArt == other.extractAlbumArt &&
        chunkSize == other.chunkSize &&
        fullMetadata == other.fullMetadata &&
        _mapEquals(headers, other.headers);
  }

  @override
  int get hashCode => Object.hash(extractAlbumArt, chunkSize, fullMetadata, headers);

  static bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

