/// This file is a part of flutter_media_metadata (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_media_metadata/src/utils.dart';

/// Metadata of a media file.
class Metadata {
  /// Name of the track.
  final String? trackName;

  /// Names of the artists performing in the track.
  final List<String>? trackArtistNames;

  /// Name of the album.
  final String? albumName;

  /// Name of the album artist.
  final String? albumArtistName;

  /// Position of track in the album.
  final int? trackNumber;

  /// Number of tracks in the album.
  final int? albumLength;

  /// Year of the track.
  final int? year;

  /// Genre of the track.
  final String? genre;

  /// Author of the track.
  final String? authorName;

  /// Writer of the track.
  final String? writerName;

  /// Number of the disc.
  final int? discNumber;

  /// Mime type.
  final String? mimeType;

  /// Duration of the track in milliseconds.
  final int? trackDuration;

  /// Bitrate of the track.
  final int? bitrate;

  /// [Uint8List] having album art data.
  final Uint8List? albumArt;

  // Useful...
  final String? albumArtMimeType;

  /// File path of the media file. `null` on web.
  final String? filePath;

  // TODO: BPM implemented on web only for now
  final int? bpm;

  // TODO: Comment implemented on web only for now
  final String? comment;

  // TODO: Channels implemented on web only for now. Assuming int is correct?
  final int? channels;

  // TODO: Sample rate implemented on web only for now
  final int? sampleRate;

  const Metadata({
    this.trackName,
    this.trackArtistNames,
    this.albumName,
    this.albumArtistName,
    this.trackNumber,
    this.albumLength,
    this.year,
    this.genre,
    this.authorName,
    this.writerName,
    this.discNumber,
    this.mimeType,
    this.trackDuration,
    this.bitrate,
    this.albumArt,
    this.filePath,
    this.bpm,
    this.comment,
    this.albumArtMimeType,
    this.channels,
    this.sampleRate,
  });

  factory Metadata.fromJson(dynamic map) => Metadata(
        trackName: map['metadata']['trackName'],
        // trackArtistNames: map['metadata']['trackArtistNames'] != null
        //     ? map['metadata']['trackArtistNames'].split('/')
        //     : null,
        trackArtistNames: map['metadata']['trackArtistNames']?.split('/'),
        albumName: map['metadata']['albumName'],
        albumArtistName: map['metadata']['albumArtistName'],
        trackNumber: parseInteger(map['metadata']['trackNumber']),
        albumLength: parseInteger(map['metadata']['albumLength']),
        year: parseInteger(map['metadata']['year']),
        authorName: map['metadata']['authorName'],
        writerName: map['metadata']['writerName'],
        discNumber: parseInteger(map['metadata']['discNumber']),
        mimeType: map['metadata']['mimeType'],
        trackDuration: parseInteger(map['metadata']['trackDuration']),
        bitrate: parseInteger(map['metadata']['bitrate']),
        bpm: parseInteger(map['metadata']['bpm']),
        albumArtMimeType: map['metadata']['albumArtMimeType'],
        channels: parseInteger(map['metadata']['channels']),
        sampleRate: parseInteger(map['metadata']['sampleRate']),
        comment: map['metadata']['comment'],
        albumArt: map['albumArt'],
        filePath: map['filePath'],
        genre: map['genre'],
      );

  Map<String, dynamic> toJson() => {
        'trackName': trackName,
        'trackArtistNames': trackArtistNames,
        'albumName': albumName,
        'albumArtistName': albumArtistName,
        'trackNumber': trackNumber,
        'albumLength': albumLength,
        'year': year,
        'genre': genre,
        'authorName': authorName,
        'writerName': writerName,
        'discNumber': discNumber,
        'mimeType': mimeType,
        'trackDuration': trackDuration,
        'bitrate': bitrate,
        'filePath': filePath,
        'bpm': bpm,
        'comment': comment,
        'channels': channels,
        'sampleRate': sampleRate,
        'albumArtMimeType': albumArtMimeType,
      };

  @override
  String toString() => toJson().toString();
}
