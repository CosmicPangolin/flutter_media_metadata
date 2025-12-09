/// This file is a part of flutter_media_metadata (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:typed_data';

/// Metadata of a media file.
///
/// This class contains comprehensive metadata extracted from media files
/// including audio, video, and general file information.
class Metadata {
  // ============================================
  // Basic Track Information
  // ============================================

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

  /// Author of the track (composer).
  final String? authorName;

  /// Writer of the track.
  final String? writerName;

  /// Number of the disc.
  final int? discNumber;

  /// Mime type of the file.
  final String? mimeType;

  /// Duration of the track in milliseconds.
  final double? trackDuration;

  /// Overall bitrate of the track in bits per second.
  final int? bitrate;

  /// [Uint8List] containing album art data.
  final Uint8List? albumArt;

  /// MIME type of the album art (e.g., "image/jpeg", "image/png").
  final String? albumArtMimeType;

  /// File path of the media file. May be filename on web.
  final String? filePath;

  /// Beats per minute.
  final int? bpm;

  /// Comment/description.
  final String? comment;

  // ============================================
  // Audio-specific Information
  // ============================================

  /// Number of audio channels (e.g., 2 for stereo).
  final int? channels;

  /// Channel positions description.
  final String? channelPositions;

  /// Channel layout (e.g., "L R").
  final String? channelLayout;

  /// Sample rate in Hz (e.g., 44100, 48000).
  final int? sampleRate;

  /// Bit depth (e.g., 16, 24).
  final int? bitDepth;

  /// Audio codec (e.g., "AAC", "FLAC", "MP3").
  final String? audioCodec;

  /// Audio codec profile.
  final String? audioCodecProfile;

  /// Audio stream bitrate in bits per second.
  final int? audioBitrate;

  /// Bitrate mode (e.g., "CBR", "VBR").
  final String? audioBitrateMode;

  /// Audio stream size in bytes.
  final int? audioStreamSize;

  /// Compression mode (e.g., "Lossy", "Lossless").
  final String? audioCompressionMode;

  /// ReplayGain value in dB.
  final String? audioReplayGain;

  /// ReplayGain peak value.
  final String? audioReplayGainPeak;

  // ============================================
  // Video-specific Information
  // ============================================

  /// Video width in pixels.
  final int? width;

  /// Video height in pixels.
  final int? height;

  /// Frame rate (frames per second).
  final double? frameRate;

  /// Video codec (e.g., "AVC", "HEVC").
  final String? videoCodec;

  /// Video codec profile.
  final String? videoCodecProfile;

  /// Video bitrate in bits per second.
  final int? videoBitrate;

  /// Display aspect ratio (e.g., "16:9").
  final String? videoAspectRatio;

  /// Color space (e.g., "YUV").
  final String? videoColorSpace;

  /// Video bit depth.
  final int? videoBitDepth;

  /// Video stream size in bytes.
  final int? videoStreamSize;

  // ============================================
  // Format Information
  // ============================================

  /// Container format (e.g., "MPEG Audio", "FLAC", "Matroska").
  final String? format;

  /// Format profile.
  final String? formatProfile;

  /// Format version.
  final String? formatVersion;

  /// File size in bytes.
  final int? fileSize;

  /// Application used to encode the file.
  final String? encodedApplication;

  /// Library used to encode the file.
  final String? encodedLibrary;

  // ============================================
  // Raw Data
  // ============================================

  /// Raw metadata map for accessing fields not exposed as properties.
  final Map<String, dynamic>? rawMetadata;

  /// Raw track data from mediainfo.js (web only).
  final List<dynamic>? rawTracks;

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
    this.albumArtMimeType,
    this.filePath,
    this.bpm,
    this.comment,
    this.channels,
    this.channelPositions,
    this.channelLayout,
    this.sampleRate,
    this.bitDepth,
    this.audioCodec,
    this.audioCodecProfile,
    this.audioBitrate,
    this.audioBitrateMode,
    this.audioStreamSize,
    this.audioCompressionMode,
    this.audioReplayGain,
    this.audioReplayGainPeak,
    this.width,
    this.height,
    this.frameRate,
    this.videoCodec,
    this.videoCodecProfile,
    this.videoBitrate,
    this.videoAspectRatio,
    this.videoColorSpace,
    this.videoBitDepth,
    this.videoStreamSize,
    this.format,
    this.formatProfile,
    this.formatVersion,
    this.fileSize,
    this.encodedApplication,
    this.encodedLibrary,
    this.rawMetadata,
    this.rawTracks,
  });

  /// Parse a value to int, handling various input types.
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    // Handle values like "2/12" (track number format)
    final parts = str.split('/');
    return int.tryParse(parts.first.trim());
  }

  /// Parse a value to double, handling various input types.
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    return double.tryParse(str);
  }

  /// Parse a value to string, handling null.
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  /// Parse artist names from a string, splitting by common delimiters.
  static List<String>? _parseArtistNames(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    // Split by common delimiters: /, ;, &, and/feat./featuring
    final artists = str
        .split(RegExp(r'[/;]|(?:\s+(?:&|and|feat\.?|featuring)\s+)', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return artists.isEmpty ? [str] : artists;
  }

  /// Parse year from various date formats.
  static int? _parseYear(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    // Try to extract 4-digit year
    final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(str);
    if (yearMatch != null) {
      return int.tryParse(yearMatch.group(0)!);
    }
    return int.tryParse(str);
  }

  /// Create Metadata from a JSON map.
  ///
  /// This handles both the native platform format (with nested 'metadata' key)
  /// and the web format (flat structure from mediainfo.js bridge).
  factory Metadata.fromJson(dynamic map) {
    if (map == null) {
      return const Metadata();
    }

    // Handle nested 'metadata' structure (native platforms)
    final metadata = map['metadata'] ?? map;

    return Metadata(
      trackName: _parseString(metadata['trackName']),
      trackArtistNames: _parseArtistNames(metadata['trackArtistNames']),
      albumName: _parseString(metadata['albumName']),
      albumArtistName: _parseString(metadata['albumArtistName']),
      trackNumber: _parseInt(metadata['trackNumber']),
      albumLength: _parseInt(metadata['albumLength']),
      year: _parseYear(metadata['year']),
      genre: _parseString(metadata['genre']),
      authorName: _parseString(metadata['authorName']),
      writerName: _parseString(metadata['writerName']),
      discNumber: _parseInt(metadata['discNumber']),
      mimeType: _parseString(metadata['mimeType']),
      trackDuration: _parseDouble(metadata['trackDuration']),
      bitrate: _parseInt(metadata['bitrate']),
      bpm: _parseInt(metadata['bpm']),
      comment: _parseString(metadata['comment']),
      albumArtMimeType: _parseString(map['albumArtMimeType'] ?? metadata['albumArtMimeType']),
      // Audio fields
      channels: _parseInt(metadata['channels']),
      channelPositions: _parseString(metadata['channelPositions']),
      channelLayout: _parseString(metadata['channelLayout']),
      sampleRate: _parseInt(metadata['sampleRate']),
      bitDepth: _parseInt(metadata['bitDepth']),
      audioCodec: _parseString(metadata['audioCodec']),
      audioCodecProfile: _parseString(metadata['audioCodecProfile']),
      audioBitrate: _parseInt(metadata['audioBitrate']),
      audioBitrateMode: _parseString(metadata['audioBitrateMode']),
      audioStreamSize: _parseInt(metadata['audioStreamSize']),
      audioCompressionMode: _parseString(metadata['audioCompressionMode']),
      audioReplayGain: _parseString(metadata['audioReplayGain']),
      audioReplayGainPeak: _parseString(metadata['audioReplayGainPeak']),
      // Video fields
      width: _parseInt(metadata['width']),
      height: _parseInt(metadata['height']),
      frameRate: _parseDouble(metadata['frameRate']),
      videoCodec: _parseString(metadata['videoCodec']),
      videoCodecProfile: _parseString(metadata['videoCodecProfile']),
      videoBitrate: _parseInt(metadata['videoBitrate']),
      videoAspectRatio: _parseString(metadata['videoAspectRatio']),
      videoColorSpace: _parseString(metadata['videoColorSpace']),
      videoBitDepth: _parseInt(metadata['videoBitDepth']),
      videoStreamSize: _parseInt(metadata['videoStreamSize']),
      // Format fields
      format: _parseString(metadata['format']),
      formatProfile: _parseString(metadata['formatProfile']),
      formatVersion: _parseString(metadata['formatVersion']),
      fileSize: _parseInt(metadata['fileSize']),
      encodedApplication: _parseString(metadata['encodedApplication']),
      encodedLibrary: _parseString(metadata['encodedLibrary']),
      // Album art and file info
      albumArt: map['albumArt'] is Uint8List ? map['albumArt'] : null,
      filePath: _parseString(map['filePath']),
      // Raw data
      rawMetadata: metadata is Map<String, dynamic> ? metadata : null,
      rawTracks: map['rawTracks'] is List ? map['rawTracks'] : null,
    );
  }

  /// Convert to JSON map.
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
        'albumArtMimeType': albumArtMimeType,
        'channels': channels,
        'channelPositions': channelPositions,
        'channelLayout': channelLayout,
        'sampleRate': sampleRate,
        'bitDepth': bitDepth,
        'audioCodec': audioCodec,
        'audioCodecProfile': audioCodecProfile,
        'audioBitrate': audioBitrate,
        'audioBitrateMode': audioBitrateMode,
        'audioStreamSize': audioStreamSize,
        'audioCompressionMode': audioCompressionMode,
        'audioReplayGain': audioReplayGain,
        'audioReplayGainPeak': audioReplayGainPeak,
        'width': width,
        'height': height,
        'frameRate': frameRate,
        'videoCodec': videoCodec,
        'videoCodecProfile': videoCodecProfile,
        'videoBitrate': videoBitrate,
        'videoAspectRatio': videoAspectRatio,
        'videoColorSpace': videoColorSpace,
        'videoBitDepth': videoBitDepth,
        'videoStreamSize': videoStreamSize,
        'format': format,
        'formatProfile': formatProfile,
        'formatVersion': formatVersion,
        'fileSize': fileSize,
        'encodedApplication': encodedApplication,
        'encodedLibrary': encodedLibrary,
      };

  @override
  String toString() => 'Metadata(${toJson()})';

  /// Returns true if this metadata contains video information.
  bool get hasVideo => width != null || height != null || videoCodec != null;

  /// Returns true if this metadata contains audio information.
  bool get hasAudio => channels != null || sampleRate != null || audioCodec != null;

  /// Returns true if album art is available.
  bool get hasAlbumArt => albumArt != null && albumArt!.isNotEmpty;

  /// Returns the duration as a [Duration] object, or null if not available.
  Duration? get duration {
    if (trackDuration == null) return null;
    return Duration(milliseconds: trackDuration!.toInt());
  }

  /// Returns a human-readable duration string (e.g., "3:45").
  String? get durationString {
    final d = duration;
    if (d == null) return null;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns a human-readable bitrate string (e.g., "320 kbps").
  String? get bitrateString {
    if (bitrate == null) return null;
    return '${(bitrate! / 1000).round()} kbps';
  }

  /// Returns a human-readable sample rate string (e.g., "44.1 kHz").
  String? get sampleRateString {
    if (sampleRate == null) return null;
    return '${(sampleRate! / 1000).toStringAsFixed(1)} kHz';
  }

  /// Returns video resolution string (e.g., "1920x1080").
  String? get resolutionString {
    if (width == null || height == null) return null;
    return '${width}x$height';
  }

  /// Create a copy with some fields replaced.
  Metadata copyWith({
    String? trackName,
    List<String>? trackArtistNames,
    String? albumName,
    String? albumArtistName,
    int? trackNumber,
    int? albumLength,
    int? year,
    String? genre,
    String? authorName,
    String? writerName,
    int? discNumber,
    String? mimeType,
    double? trackDuration,
    int? bitrate,
    Uint8List? albumArt,
    String? albumArtMimeType,
    String? filePath,
    int? bpm,
    String? comment,
    int? channels,
    String? channelPositions,
    String? channelLayout,
    int? sampleRate,
    int? bitDepth,
    String? audioCodec,
    String? audioCodecProfile,
    int? audioBitrate,
    String? audioBitrateMode,
    int? audioStreamSize,
    String? audioCompressionMode,
    String? audioReplayGain,
    String? audioReplayGainPeak,
    int? width,
    int? height,
    double? frameRate,
    String? videoCodec,
    String? videoCodecProfile,
    int? videoBitrate,
    String? videoAspectRatio,
    String? videoColorSpace,
    int? videoBitDepth,
    int? videoStreamSize,
    String? format,
    String? formatProfile,
    String? formatVersion,
    int? fileSize,
    String? encodedApplication,
    String? encodedLibrary,
    Map<String, dynamic>? rawMetadata,
    List<dynamic>? rawTracks,
  }) {
    return Metadata(
      trackName: trackName ?? this.trackName,
      trackArtistNames: trackArtistNames ?? this.trackArtistNames,
      albumName: albumName ?? this.albumName,
      albumArtistName: albumArtistName ?? this.albumArtistName,
      trackNumber: trackNumber ?? this.trackNumber,
      albumLength: albumLength ?? this.albumLength,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      authorName: authorName ?? this.authorName,
      writerName: writerName ?? this.writerName,
      discNumber: discNumber ?? this.discNumber,
      mimeType: mimeType ?? this.mimeType,
      trackDuration: trackDuration ?? this.trackDuration,
      bitrate: bitrate ?? this.bitrate,
      albumArt: albumArt ?? this.albumArt,
      albumArtMimeType: albumArtMimeType ?? this.albumArtMimeType,
      filePath: filePath ?? this.filePath,
      bpm: bpm ?? this.bpm,
      comment: comment ?? this.comment,
      channels: channels ?? this.channels,
      channelPositions: channelPositions ?? this.channelPositions,
      channelLayout: channelLayout ?? this.channelLayout,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      audioCodec: audioCodec ?? this.audioCodec,
      audioCodecProfile: audioCodecProfile ?? this.audioCodecProfile,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioBitrateMode: audioBitrateMode ?? this.audioBitrateMode,
      audioStreamSize: audioStreamSize ?? this.audioStreamSize,
      audioCompressionMode: audioCompressionMode ?? this.audioCompressionMode,
      audioReplayGain: audioReplayGain ?? this.audioReplayGain,
      audioReplayGainPeak: audioReplayGainPeak ?? this.audioReplayGainPeak,
      width: width ?? this.width,
      height: height ?? this.height,
      frameRate: frameRate ?? this.frameRate,
      videoCodec: videoCodec ?? this.videoCodec,
      videoCodecProfile: videoCodecProfile ?? this.videoCodecProfile,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      videoAspectRatio: videoAspectRatio ?? this.videoAspectRatio,
      videoColorSpace: videoColorSpace ?? this.videoColorSpace,
      videoBitDepth: videoBitDepth ?? this.videoBitDepth,
      videoStreamSize: videoStreamSize ?? this.videoStreamSize,
      format: format ?? this.format,
      formatProfile: formatProfile ?? this.formatProfile,
      formatVersion: formatVersion ?? this.formatVersion,
      fileSize: fileSize ?? this.fileSize,
      encodedApplication: encodedApplication ?? this.encodedApplication,
      encodedLibrary: encodedLibrary ?? this.encodedLibrary,
      rawMetadata: rawMetadata ?? this.rawMetadata,
      rawTracks: rawTracks ?? this.rawTracks,
    );
  }
}
