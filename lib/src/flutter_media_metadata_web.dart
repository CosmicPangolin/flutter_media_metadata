/// This file is a part of flutter_media_metadata (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'package:flutter_media_metadata/src/models/metadata.dart';
import 'package:flutter_media_metadata/src/models/options.dart';
import 'package:flutter_media_metadata/src/models/exceptions.dart';

// ============================================
// JavaScript Interop Definitions
// ============================================

@JS('typeof FlutterMediaInfo !== "undefined"')
external bool get _isFlutterMediaInfoDefined;

@JS('FlutterMediaInfo.analyzeFile')
external JSPromise<JSObject> _analyzeFile(web.File file, JSAny? options);

@JS('FlutterMediaInfo.analyzeBytes')
external JSPromise<JSObject> _analyzeBytes(JSAny bytes, JSAny? options);

@JS('FlutterMediaInfo.analyzeUrl')
external JSPromise<JSObject> _analyzeUrl(JSString url, JSAny? options);

@JS('FlutterMediaInfo.analyzeStream')
external JSPromise<JSObject> _analyzeStream(
  JSNumber size,
  JSFunction readChunk,
  JSAny? options,
);

@JS('FlutterMediaInfo.isMediaInfoAvailable')
external JSBoolean _isMediaInfoAvailable();

@JS('FlutterMediaInfo.getVersion')
external JSPromise<JSString> _getVersion();

@JS('JSON.stringify')
external JSString _jsonStringify(JSAny? obj);

@JS('JSON.parse')
external JSAny _jsonParse(JSString json);

Map<String, dynamic> _jsObjectToMap(JSObject obj) {
  final jsonStr = _jsonStringify(obj).toDart;
  return jsonDecode(jsonStr) as Map<String, dynamic>;
}

JSObject? _optionsToJs(MetadataOptions? options) {
  if (options == null) return null;
  final json = jsonEncode(options.toJson());
  return _jsonParse(json.toJS) as JSObject;
}

// ============================================
// MetadataRetriever Implementation
// ============================================

/// Web implementation of MetadataRetriever using mediainfo.js
///
/// This implementation uses chunked/streaming reading to avoid
/// loading entire files into memory. It supports:
///
/// - [fromFile] - Extract metadata from a web File/Blob (most efficient)
/// - [fromBytes] - Extract metadata from a Uint8List
/// - [fromUrl] - Extract metadata from a URL using Range requests
/// - [fromStream] - Extract metadata using a custom chunk reader
class MetadataRetriever {
  /// Check if mediainfo.js is loaded and available.
  static bool get isAvailable {
    try {
      return _isFlutterMediaInfoDefined && _isMediaInfoAvailable().toDart;
    } catch (_) {
      return false;
    }
  }

  /// Get the version of mediainfo.js being used.
  static Future<String?> getVersion() async {
    if (!isAvailable) return null;
    try {
      final version = await _getVersion().toDart;
      return version.toDart;
    } catch (_) {
      return null;
    }
  }

  static void _ensureAvailable() {
    if (!_isFlutterMediaInfoDefined) {
      throw MetadataLibraryException(
        'FlutterMediaInfo bridge is not loaded. Make sure to include both '
        'mediainfo.js and mediainfo_bridge.js in your index.html:\n\n'
        '<script src="https://unpkg.com/mediainfo.js/dist/mediainfo.min.js"></script>\n'
        '<script src="mediainfo_bridge.js"></script>',
        libraryName: 'FlutterMediaInfo',
      );
    }

    if (!_isMediaInfoAvailable().toDart) {
      throw MetadataLibraryException(
        'mediainfo.js is not loaded. Make sure to include mediainfo.js '
        'before mediainfo_bridge.js in your index.html:\n\n'
        '<script src="https://unpkg.com/mediainfo.js/dist/mediainfo.min.js"></script>',
        libraryName: 'MediaInfo',
      );
    }
  }

  /// Extract [Metadata] from a web [File].
  ///
  /// This is the most memory-efficient method on web as it uses
  /// chunked reading - only small portions of the file are loaded
  /// into memory at a time.
  ///
  /// Throws [MetadataLibraryException] if mediainfo.js is not loaded.
  /// Throws [MetadataExtractionException] if extraction fails.
  static Future<Metadata> fromFile(
    web.File file, {
    MetadataOptions? options,
  }) async {
    _ensureAvailable();

    try {
      final jsResult = await _analyzeFile(file, _optionsToJs(options)).toDart;
      return _parseResult(jsResult, source: file.name);
    } catch (e) {
      if (e is MetadataException) rethrow;
      throw MetadataExtractionException(
        'Failed to extract metadata from file',
        cause: e,
        source: file.name,
      );
    }
  }

  /// Extract [Metadata] from a [Blob].
  ///
  /// Similar to [fromFile] but accepts any Blob object.
  static Future<Metadata> fromBlob(
    web.Blob blob, {
    MetadataOptions? options,
  }) async {
    _ensureAvailable();

    try {
      final file = web.File([blob].toJS, 'blob');
      final jsResult = await _analyzeFile(file, _optionsToJs(options)).toDart;
      return _parseResult(jsResult, source: 'blob');
    } catch (e) {
      if (e is MetadataException) rethrow;
      throw MetadataExtractionException(
        'Failed to extract metadata from blob',
        cause: e,
        source: 'blob',
      );
    }
  }

  /// Extract [Metadata] from a [Uint8List].
  ///
  /// Note: The bytes are already in memory, so this doesn't benefit
  /// from chunked reading. Prefer [fromFile] for file uploads.
  static Future<Metadata> fromBytes(
    Uint8List bytes, {
    MetadataOptions? options,
  }) async {
    _ensureAvailable();

    if (bytes.isEmpty) {
      throw MetadataExtractionException(
        'Cannot extract metadata from empty byte array',
        source: 'bytes',
      );
    }

    try {
      final jsBytes = bytes.toJS;
      final jsResult = await _analyzeBytes(jsBytes, _optionsToJs(options)).toDart;
      return _parseResult(jsResult, source: 'bytes');
    } catch (e) {
      if (e is MetadataException) rethrow;
      throw MetadataExtractionException(
        'Failed to extract metadata from bytes',
        cause: e,
        source: 'bytes',
      );
    }
  }

  /// Extract [Metadata] from a URL using HTTP Range requests.
  ///
  /// This method only downloads the portions of the file needed
  /// for metadata extraction, making it very efficient for large
  /// remote files.
  ///
  /// Requirements:
  /// - Server must support Range requests (Accept-Ranges header)
  /// - Server must return Content-Length header
  /// - CORS must be configured if cross-origin
  static Future<Metadata> fromUrl(
    Uri url, {
    MetadataOptions? options,
  }) async {
    _ensureAvailable();

    final urlString = url.toString();

    try {
      final jsResult = await _analyzeUrl(urlString.toJS, _optionsToJs(options)).toDart;
      return _parseResult(jsResult, source: urlString);
    } catch (e) {
      if (e is MetadataException) rethrow;

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') ||
          errorStr.contains('cors') ||
          errorStr.contains('fetch') ||
          errorStr.contains('failed to fetch')) {
        throw MediaSourceException.networkError(urlString, e);
      }

      throw MetadataExtractionException(
        'Failed to extract metadata from URL',
        cause: e,
        source: urlString,
      );
    }
  }

  /// Extract [Metadata] using a custom chunk reader.
  ///
  /// This is the most flexible method, allowing you to provide
  /// your own data source.
  static Future<Metadata> fromStream({
    required int size,
    required Future<Uint8List> Function(int offset, int size) readChunk,
    MetadataOptions? options,
  }) async {
    _ensureAvailable();

    if (size <= 0) {
      throw MetadataExtractionException(
        'Invalid size: $size. Size must be greater than 0.',
        source: 'stream',
      );
    }

    try {
      JSPromise<JSUint8Array> jsReadChunk(JSNumber jsChunkSize, JSNumber jsOffset) {
        final dartChunkSize = jsChunkSize.toDartInt;
        final dartOffset = jsOffset.toDartInt;
        final future = readChunk(dartOffset, dartChunkSize).then((bytes) => bytes.toJS);
        return future.toJS;
      }

      final jsResult = await _analyzeStream(
        size.toJS,
        jsReadChunk.toJS,
        _optionsToJs(options),
      ).toDart;

      return _parseResult(jsResult, source: 'stream');
    } catch (e) {
      if (e is MetadataException) rethrow;
      throw MetadataExtractionException(
        'Failed to extract metadata from stream',
        cause: e,
        source: 'stream',
      );
    }
  }

  static Metadata _parseResult(JSObject jsResult, {String? source}) {
    final map = _jsObjectToMap(jsResult);

    if (map.containsKey('error')) {
      final error = map['error'];
      throw MetadataExtractionException(
        'Extraction failed: $error',
        source: source,
      );
    }

    Uint8List? albumArt;
    final albumArtData = map['albumArt'];
    if (albumArtData != null) {
      if (albumArtData is List<int>) {
        albumArt = Uint8List.fromList(albumArtData);
      } else if (albumArtData is String && albumArtData.isNotEmpty) {
        try {
          albumArt = base64Decode(albumArtData);
        } catch (e) {
          // Invalid base64, ignore
        }
      }
    }

    final metadataMap = <String, dynamic>{
      'metadata': map['metadata'] ?? {},
      'albumArt': albumArt,
      'albumArtMimeType': map['albumArtMimeType'],
      'filePath': map['filePath'] ?? source,
      'rawTracks': map['rawTracks'],
    };

    return Metadata.fromJson(metadataMap);
  }
}

/// Plugin class for web platform registration
class MetadataRetrieverPluginWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'flutter_media_metadata',
      const StandardMethodCodec(),
      registrar,
    );
    final pluginInstance = MetadataRetrieverPluginWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) => throw PlatformException(
        code: 'Unimplemented',
        details: 'flutter_media_metadata for web doesn\'t implement \'${call.method}\'',
      );

  /// Extracts [Metadata] from a [File]. Works on Windows, Linux, macOS, Android & iOS.
  static Future<Metadata> fromFile(dynamic _) async {
    throw UnimplementedError(
      '[MetadataRetriever.fromFile] is not supported on web. This method is only available for Windows, Linux, macOS, Android or iOS. Use [MetadataRetriever.fromBytes] instead.',
    );
  }

  /// Extracts [Metadata] from [Uint8List]. Works only on Web.
  static Future<Metadata> fromBytes(Uint8List bytes) async {
    final completer = Completer<Metadata>();

    try {
      // Check if MediaInfo factory is available
      if (globalContext['MediaInfo'] == null) {
        completer
            .completeError(Exception('MediaInfo.js library not loaded. Make sure to include the script in your HTML.'));
        return completer.future;
      }

      // MediaInfo is now a factory function with the ESM bundle
      final mediaInfoFactory = globalContext['MediaInfo'] as JSFunction;

      // Create options
      final opts = newObject();
      opts['format'] = 'JSON'.toJS;
      opts['full'] = true.toJS;
      opts['coverData'] = true.toJS;

      // Call the factory function
      final mediaInfoPromise = mediaInfoFactory.callAsConstructor(opts) as JSObject;

      // Handle the factory promise
      mediaInfoPromise.callMethod(
        'then'.toJS,
        (JSAny mediainfo) {
          try {
            // Create a simpler readChunk function that uses async/await pattern
            final readChunkJS = (int chunkSize, int offset) {
              // Create a resolved Promise directly
              final promiseConstructor = globalContext['Promise'] as JSFunction;

              // Calculate the chunk
              final endOffset = (offset + chunkSize).clamp(0, bytes.length);
              final sublist = bytes.sublist(offset, endOffset);

              // Return Promise.resolve(chunk)
              return (promiseConstructor as JSObject).callMethod('resolve'.toJS, sublist.toJS) as JSObject;
            }.toJS;

            // Now use analyzeData with the callback approach
            (mediainfo as JSObject).callMethod(
              'analyzeData'.toJS,
              bytes.length.toJS,
              readChunkJS,
              (JSString result) {
                try {
                  _processResult(result.toDart, completer);
                } catch (e) {
                  completer.completeError(Exception('Result processing failed: $e'));
                }
              }.toJS,
            );
          } catch (e) {
            completer.completeError(Exception('Failed to call analyzeData: $e'));
          }
        }.toJS,
        (JSAny? error) {
          completer.completeError(Exception('MediaInfo factory failed: $error'));
        }.toJS,
      );

      // Add timeout
      Timer(Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.completeError(Exception('MediaInfo analysis timed out'));
        }
      });
    } catch (e) {
      completer.completeError(Exception('MediaInfo initialization failed: $e'));
    }

    return completer.future;
  }

  static void _processResult(String resultJson, Completer<Metadata> completer) {
    try {
      final rawMetadataJson = jsonDecode(resultJson)['media']['track'];

      Map<String, dynamic> metadata = <String, dynamic>{
        'metadata': {},
        'albumArt': null,
        'filePath': null,
      };

      bool isFound = false;
      for (final data in rawMetadataJson) {
        if (data['@type'] == 'General') {
          isFound = true;
          try {
            metadata['albumArt'] = data['Cover_Data'] != null ? base64Decode(data['Cover_Data']) : null;
          } catch (e) {
            print('Failed to decode album art: $e');
          }
          _kGeneralMetadataKeys.forEach((key, value) {
            metadata['metadata'][key] = _extractSafeValue(data[value]);
          });
        } else if (data['@type'] == 'Audio') {
          _kAudioMetadataKeys.forEach((key, value) {
            metadata['metadata'][key] = _extractSafeValue(data[value]);
          });
        }
      }

      if (!isFound) {
        completer.completeError(Exception('No metadata found'));
        return;
      }

      completer.complete(Metadata.fromJson(metadata));
    } catch (e) {
      completer.completeError(Exception('Failed to parse MediaInfo result: $e'));
    }
  }

  static dynamic _extractSafeValue(dynamic value) {
    if (value == null) return null;
    
    // Handle primitive types directly
    if (value is String || value is int || value is double || value is bool) {
      return value;
    }
    
    // Handle Map/Object types (like the Album field)
    if (value is Map) {
      // MediaInfo.js specific structure with @dt and #value
      if (value.containsKey('@dt') && value.containsKey('#value')) {
        final dataType = value['@dt'];
        final rawValue = value['#value'];
        
        if (dataType == 'binary.base64' && rawValue is String) {
          try {
            // Try to decode base64 and convert to UTF-8 string
            final decoded = base64Decode(rawValue);
            return utf8.decode(decoded, allowMalformed: true);
          } catch (e) {
            // If decoding fails, return the raw base64 string
            return rawValue;
          }
        }
        
        // For other data types, return the value as-is
        return rawValue;
      }
      
      // Fallback for other Map structures
      if (value.containsKey('#value')) {
        return _extractSafeValue(value['#value']);
      }
      if (value.containsKey('@value')) {
        return _extractSafeValue(value['@value']);
      }
      if (value.containsKey('value')) {
        return _extractSafeValue(value['value']);
      }
      
      // Convert to string as fallback
      return value.toString();
    }
    
    // Handle List types
    if (value is List) {
      return value.map((e) => _extractSafeValue(e)).join(', ');
    }
    
    // Fallback
    return value.toString();
  }
}

// Helper function to create new objects
JSObject newObject() => (globalContext['Object']! as JSFunction).callAsConstructor() as JSObject;

const _kGeneralMetadataKeys = <String, String>{
  "trackName": "Track",
  "trackArtistNames": "Performer",
  "albumName": "Album",
  "albumArtistName": "Album_Performer",
  "trackNumber": "Track_Position",
  "albumLength": "Track_Position_Total",
  "year": "Recorded_Date",
  "genre": "Genre",
  "writerName": "WrittenBy",
  "trackDuration": "Duration",
  "bitrate": "OverallBitRate",
  "mimeType": "InternetMediaType",
  "albumArtMimeType": "Cover_Mime",
  "bpm": "BPM",
  "comment": "Comment",
};

const _kAudioMetadataKeys = <String, String>{
  "channels": "Channels",
  "sampleRate": "SamplingRate",
};