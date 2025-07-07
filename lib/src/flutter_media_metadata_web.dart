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

import 'package:flutter_media_metadata/src/models/metadata.dart';

/// ## MetadataRetriever
///
/// Use [MetadataRetriever.fromBytes] to extract [Metadata] from bytes of media file.
///
/// ```dart
/// final metadata = MetadataRetriever.fromBytes(byteData);
/// String? trackName = metadata.trackName;
/// List<String>? trackArtistNames = metadata.trackArtistNames;
/// String? albumName = metadata.albumName;
/// String? albumArtistName = metadata.albumArtistName;
/// int? trackNumber = metadata.trackNumber;
/// int? albumLength = metadata.albumLength;
/// int? year = metadata.year;
/// String? genre = metadata.genre;
/// String? authorName = metadata.authorName;
/// String? writerName = metadata.writerName;
/// int? discNumber = metadata.discNumber;
/// String? mimeType = metadata.mimeType;
/// int? trackDuration = metadata.trackDuration;
/// int? bitrate = metadata.bitrate;
/// Uint8List? albumArt = metadata.albumArt;
/// ```
///
class MetadataRetriever {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'flutter_media_metadata',
      const StandardMethodCodec(),
      registrar,
    );
    final pluginInstance = MetadataRetriever();
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
  static Future<Metadata> fromBytes(Uint8List bytes) {
    final completer = Completer<Metadata>();

    // Create MediaInfo options object
    final opts = createMediaInfoOptions(
      chunkSize: 256 * 1024,
      coverData: true,
      format: 'JSON',
      full: true,
    );

    // Call MediaInfo constructor
    createMediaInfo(
      opts,
      (JSObject mediainfo) {
        // Create the promise for analyzeData
        final promise = callAnalyzeData(
          mediainfo,
          (() => bytes.length.toJS).toJS,
          (int chunkSize, int offset) {
            return createPromise((JSFunction resolve, JSFunction reject) {
              final sublist = bytes.sublist(offset, offset + chunkSize);
              final jsArray = sublist.toJS;
              resolve.callAsFunction(null, jsArray);
            }.toJS);
          }.toJS,
        );

        // Handle the promise result
        callThen(
          promise,
          (JSString result) {
            try {
              // Parse the metadata result from MediaInfo
              // print(result.toDart); // Uncomment for debugging
              final rawMetadataJson = jsonDecode(result.toDart)['media']['track'];

              // Keeping original mappings for MediaInfo.from/toJson() for now so I don't have to fuck with the C++
              Map<String, dynamic> metadata = <String, dynamic>{
                'metadata': {},
                'albumArt': null,
                'filePath': null,
              };

              bool isFound = false;
              for (final data in rawMetadataJson) {
                if (data['@type'] == 'General') {
                  isFound = true;

                  metadata['albumArt'] = data['Cover_Data'] != null ? base64Decode(data['Cover_Data']) : null;

                  _kGeneralMetadataKeys.forEach((key, value) {
                    metadata['metadata'][key] = data[value];
                  });
                } else if (data['@type'] == 'Audio') {
                  _kAudioMetadataKeys.forEach((key, value) {
                    metadata['metadata'][key] = data[value];
                  });
                }
              }

              if (!isFound) {
                completer.completeError(Exception('No metadata found'));
                return;
              }

              completer.complete(Metadata.fromJson(metadata));
            } catch (e) {
              completer.completeError(e);
            }
          }.toJS,
          (JSAny? error) {
            completer.completeError(Exception('MediaInfo analysis failed'));
          }.toJS,
        );
      }.toJS,
      (JSAny? error) {
        completer.completeError(Exception('Failed to create MediaInfo instance'));
      }.toJS,
    );

    return completer.future;
  }
}

// MediaInfo JavaScript interop using dart:js_interop

@JS('MediaInfo')
external void createMediaInfo(
  JSObject opts,
  JSFunction successCallback,
  JSFunction errorCallback,
);

@JS('Object')
external JSObject createMediaInfoOptions({
  required int chunkSize,
  required bool coverData,
  required String format,
  required bool full,
});

@JS('Promise')
external JSObject createPromise(JSFunction executor);

// Helper functions to call methods on JS objects
JSObject callAnalyzeData(
  JSObject mediaInfo,
  JSFunction getSize,
  JSFunction readChunk,
) {
  return mediaInfo.callMethod('analyzeData'.toJS, getSize, readChunk);
}

void callThen(
  JSObject promise,
  JSFunction onFulfilled,
  JSFunction onRejected,
) {
  promise.callMethod('then'.toJS, onFulfilled, onRejected);
}

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
