/// This file is a part of flutter_media_metadata (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter_media_metadata/src/models/metadata.dart';
import 'package:flutter_media_metadata/src/models/options.dart';
import 'package:flutter_media_metadata/src/models/exceptions.dart';

/// Native implementation of MetadataRetriever for desktop and mobile platforms.
///
/// Uses platform-specific native libraries:
/// - Windows/Linux: MediaInfoLib
/// - Android: MediaMetadataRetriever
/// - iOS/macOS: AVFoundation
///
/// ## Usage
///
/// ```dart
/// final file = File('/path/to/audio.mp3');
/// final metadata = await MetadataRetriever.fromFile(file);
///
/// // With options (note: some options may not apply to native platforms)
/// final metadata = await MetadataRetriever.fromFile(
///   file,
///   options: MetadataOptions(extractAlbumArt: false),
/// );
/// ```
class MetadataRetriever {
  /// Always returns `true` on native platforms as the native library is bundled.
  static bool get isAvailable => true;

  /// Extract [Metadata] from a [File].
  ///
  /// Works on Windows, Linux, macOS, Android & iOS.
  ///
  /// Throws:
  /// - [MediaSourceException] if the file doesn't exist or can't be read
  /// - [MetadataExtractionException] if extraction fails
  static Future<Metadata> fromFile(
    File file, {
    MetadataOptions? options,
  }) async {
    final path = file.path;

    // Check if file exists
    if (!await file.exists()) {
      throw MediaSourceException.fileNotFound(path);
    }

    try {
      final args = <String, dynamic>{
        'filePath': path,
      };

      // Pass options if provided
      if (options != null) {
        args['extractAlbumArt'] = options.extractAlbumArt;
      }

      var metadata = await _kChannel.invokeMethod('MetadataRetriever', args);

      if (metadata == null) {
        throw MetadataExtractionException(
          'No metadata returned from native platform',
          source: path,
        );
      }

      metadata['filePath'] = path;
      return Metadata.fromJson(metadata);
    } on PlatformException catch (e) {
      // Convert platform exceptions to our exception types
      if (e.code == 'FILE_NOT_FOUND') {
        throw MediaSourceException.fileNotFound(path, e);
      } else if (e.code == 'PERMISSION_DENIED') {
        throw MediaSourceException.permissionDenied(path, e);
      } else if (e.code == 'UNSUPPORTED_FORMAT') {
        throw UnsupportedMediaFormatException(
          e.message ?? 'Unsupported media format',
          source: path,
          cause: e,
        );
      }
      throw MetadataExtractionException(
        e.message ?? 'Platform error during metadata extraction',
        source: path,
        cause: e,
      );
    } catch (e) {
      if (e is MetadataException) rethrow;
      throw MetadataExtractionException(
        'Failed to extract metadata',
        source: path,
        cause: e,
      );
    }
  }

  /// Extract [Metadata] from bytes.
  ///
  /// **Not supported on native platforms.**
  /// Use [fromFile] instead, or write the bytes to a temporary file first.
  ///
  /// Throws [PlatformNotSupportedException] always.
  static Future<Metadata> fromBytes(dynamic _) async {
    throw PlatformNotSupportedException(
      '[MetadataRetriever.fromBytes] is not supported on ${Platform.operatingSystem}. '
      'Use [MetadataRetriever.fromFile] instead.',
      operation: 'fromBytes',
      platform: Platform.operatingSystem,
    );
  }

  /// Extract [Metadata] from a URL.
  ///
  /// **Not supported on native platforms.**
  /// Download the file first and use [fromFile].
  ///
  /// Throws [PlatformNotSupportedException] always.
  static Future<Metadata> fromUrl(Uri url) async {
    throw PlatformNotSupportedException(
      '[MetadataRetriever.fromUrl] is not supported on ${Platform.operatingSystem}. '
      'Download the file first and use [MetadataRetriever.fromFile] instead.',
      operation: 'fromUrl',
      platform: Platform.operatingSystem,
    );
  }

  /// Extract [Metadata] from a stream.
  ///
  /// **Not supported on native platforms.**
  /// Write the stream to a file first and use [fromFile].
  ///
  /// Throws [PlatformNotSupportedException] always.
  static Future<Metadata> fromStream({
    required int size,
    required Future<dynamic> Function(int offset, int size) readChunk,
  }) async {
    throw PlatformNotSupportedException(
      '[MetadataRetriever.fromStream] is not supported on ${Platform.operatingSystem}. '
      'Write the stream to a file first and use [MetadataRetriever.fromFile] instead.',
      operation: 'fromStream',
      platform: Platform.operatingSystem,
    );
  }
}

const _kChannel = MethodChannel('flutter_media_metadata');
