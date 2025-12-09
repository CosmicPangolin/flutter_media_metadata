/// This file is a part of flutter_media_metadata (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Base exception for all metadata extraction errors.
///
/// All exceptions thrown by the flutter_media_metadata package extend this class,
/// making it easy to catch all metadata-related errors:
///
/// ```dart
/// try {
///   final metadata = await MetadataRetriever.fromFile(file);
/// } on MetadataException catch (e) {
///   print('Metadata error: ${e.message}');
/// }
/// ```
abstract class MetadataException implements Exception {
  /// Human-readable error message.
  String get message;

  /// The underlying error that caused this exception, if any.
  Object? get cause;

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when the metadata extraction process fails.
///
/// This is the most common exception type and covers general extraction failures.
class MetadataExtractionException extends MetadataException {
  @override
  final String message;

  @override
  final Object? cause;

  /// The file path or source that failed, if available.
  final String? source;

  MetadataExtractionException(
    this.message, {
    this.cause,
    this.source,
  });

  @override
  String toString() {
    final buffer = StringBuffer('MetadataExtractionException: $message');
    if (source != null) buffer.write(' (source: $source)');
    if (cause != null) buffer.write(' (caused by: $cause)');
    return buffer.toString();
  }
}

/// Exception thrown when a required library or dependency is not available.
///
/// On web, this is thrown when mediainfo.js is not loaded.
/// On native platforms, this may be thrown if native libraries are missing.
class MetadataLibraryException extends MetadataException {
  @override
  final String message;

  @override
  final Object? cause;

  /// The name of the missing library.
  final String? libraryName;

  MetadataLibraryException(
    this.message, {
    this.cause,
    this.libraryName,
  });

  @override
  String toString() {
    final buffer = StringBuffer('MetadataLibraryException: $message');
    if (libraryName != null) buffer.write(' (library: $libraryName)');
    if (cause != null) buffer.write(' (caused by: $cause)');
    return buffer.toString();
  }
}

/// Exception thrown when the media file format is not supported.
class UnsupportedMediaFormatException extends MetadataException {
  @override
  final String message;

  @override
  final Object? cause;

  /// The detected format, if any.
  final String? format;

  /// The file path or source, if available.
  final String? source;

  UnsupportedMediaFormatException(
    this.message, {
    this.cause,
    this.format,
    this.source,
  });

  @override
  String toString() {
    final buffer = StringBuffer('UnsupportedMediaFormatException: $message');
    if (format != null) buffer.write(' (format: $format)');
    if (source != null) buffer.write(' (source: $source)');
    if (cause != null) buffer.write(' (caused by: $cause)');
    return buffer.toString();
  }
}

/// Exception thrown when there's a problem reading the media source.
///
/// This includes file not found, network errors, permission denied, etc.
class MediaSourceException extends MetadataException {
  @override
  final String message;

  @override
  final Object? cause;

  /// The file path or source that couldn't be read.
  final String? source;

  /// The type of source error (e.g., 'file_not_found', 'network_error', 'permission_denied').
  final String? errorType;

  MediaSourceException(
    this.message, {
    this.cause,
    this.source,
    this.errorType,
  });

  @override
  String toString() {
    final buffer = StringBuffer('MediaSourceException: $message');
    if (errorType != null) buffer.write(' ($errorType)');
    if (source != null) buffer.write(' (source: $source)');
    if (cause != null) buffer.write(' (caused by: $cause)');
    return buffer.toString();
  }

  /// Create a file not found exception.
  factory MediaSourceException.fileNotFound(String path, [Object? cause]) {
    return MediaSourceException(
      'File not found: $path',
      source: path,
      errorType: 'file_not_found',
      cause: cause,
    );
  }

  /// Create a network error exception.
  factory MediaSourceException.networkError(String url, [Object? cause]) {
    return MediaSourceException(
      'Network error accessing: $url',
      source: url,
      errorType: 'network_error',
      cause: cause,
    );
  }

  /// Create a permission denied exception.
  factory MediaSourceException.permissionDenied(String path, [Object? cause]) {
    return MediaSourceException(
      'Permission denied: $path',
      source: path,
      errorType: 'permission_denied',
      cause: cause,
    );
  }
}

/// Exception thrown when an operation is not supported on the current platform.
class PlatformNotSupportedException extends MetadataException {
  @override
  final String message;

  @override
  final Object? cause;

  /// The operation that was attempted.
  final String? operation;

  /// The current platform.
  final String? platform;

  PlatformNotSupportedException(
    this.message, {
    this.cause,
    this.operation,
    this.platform,
  });

  @override
  String toString() {
    final buffer = StringBuffer('PlatformNotSupportedException: $message');
    if (operation != null) buffer.write(' (operation: $operation)');
    if (platform != null) buffer.write(' (platform: $platform)');
    if (cause != null) buffer.write(' (caused by: $cause)');
    return buffer.toString();
  }
}

/// Exception thrown when metadata extraction times out.
class MetadataTimeoutException extends MetadataException {
  @override
  final String message;

  @override
  final Object? cause;

  /// The timeout duration that was exceeded.
  final Duration? timeout;

  /// The file path or source, if available.
  final String? source;

  MetadataTimeoutException(
    this.message, {
    this.cause,
    this.timeout,
    this.source,
  });

  @override
  String toString() {
    final buffer = StringBuffer('MetadataTimeoutException: $message');
    if (timeout != null) buffer.write(' (timeout: ${timeout!.inMilliseconds}ms)');
    if (source != null) buffer.write(' (source: $source)');
    if (cause != null) buffer.write(' (caused by: $cause)');
    return buffer.toString();
  }
}

