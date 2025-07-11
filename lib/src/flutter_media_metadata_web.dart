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

    // Create MediaInfo options object using dynamic properties
    final opts = newObject();
    opts['chunkSize'] = (256 * 1024).toJS;
    opts['coverData'] = true.toJS;
    opts['format'] = 'JSON'.toJS;
    opts['full'] = true.toJS;

    // Call MediaInfo constructor
    final mediaInfoConstructor = globalContext['MediaInfo'] as JSFunction;
    mediaInfoConstructor.callAsConstructor(
      null,
      opts,
      (JSAny mediainfo) {
        // Create the promise for analyzeData
        final promise = (mediainfo as JSObject).callMethod(
          'analyzeData'.toJS,
          (() => bytes.length.toJS).toJS,
          ((int chunkSize, int offset) {
            final promiseConstructor = globalContext['Promise'] as JSFunction;
            return promiseConstructor.callAsConstructor(
                null,
                (JSFunction resolve, JSFunction reject) {
                  final sublist = bytes.sublist(offset, offset + chunkSize);
                  final jsArray = sublist.toJS;
                  resolve.callAsConstructor(null, jsArray);
                }.toJS) as JSObject;
          } as JSObject Function(int, int))
              .toJS,
        ) as JSObject;

        // Handle the promise result
        promise.callMethod(
          'then'.toJS,
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

                  try {
                    metadata['albumArt'] = data['Cover_Data'] != null
                        ? base64Decode(
                            data['Cover_Data'],
                          )
                        : null;
                  } catch (e) {
                    print('Failed to decode album art');
                    print(e);
                  }
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
