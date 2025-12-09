/// This file is a part of flutter_media_metadata
/// (https://github.com/alexmercerind/flutter_media_metadata).
///
/// Copyright (c) 2021-2022, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the
/// LICENSE file.

#include "metadata_retriever.hpp"

#include <base64.hpp>

#include "utils.hpp"

// General stream metadata keys (basic track info)
static const std::map<std::string, std::wstring> kGeneralMetadataKeys = {
    {"trackName", L"Track"},
    {"trackArtistNames", L"Performer"},
    {"albumName", L"Album"},
    {"albumArtistName", L"Album/Performer"},
    {"trackNumber", L"Track/Position"},
    {"albumLength", L"Track/Position_Total"},
    {"year", L"Recorded_Date"},
    {"genre", L"Genre"},
    {"authorName", L"Composer"},
    {"writerName", L"WrittenBy"},
    {"discNumber", L"Part/Position"},
    {"mimeType", L"InternetMediaType"},
    {"trackDuration", L"Duration"},
    {"bitrate", L"OverallBitRate"},
    {"bpm", L"BPM"},
    {"comment", L"Comment"},
    // Format info
    {"format", L"Format"},
    {"formatProfile", L"Format_Profile"},
    {"formatVersion", L"Format_Version"},
    {"fileSize", L"FileSize"},
    {"encodedApplication", L"Encoded_Application"},
    {"encodedLibrary", L"Encoded_Library"},
};

// Audio stream metadata keys
static const std::map<std::string, std::wstring> kAudioMetadataKeys = {
    {"channels", L"Channel(s)"},
    {"channelPositions", L"ChannelPositions"},
    {"channelLayout", L"ChannelLayout"},
    {"sampleRate", L"SamplingRate"},
    {"bitDepth", L"BitDepth"},
    {"audioCodec", L"Format"},
    {"audioCodecProfile", L"Format_Profile"},
    {"audioBitrate", L"BitRate"},
    {"audioBitrateMode", L"BitRate_Mode"},
    {"audioStreamSize", L"StreamSize"},
    {"audioCompressionMode", L"Compression_Mode"},
};

// Video stream metadata keys
static const std::map<std::string, std::wstring> kVideoMetadataKeys = {
    {"width", L"Width"},
    {"height", L"Height"},
    {"frameRate", L"FrameRate"},
    {"videoCodec", L"Format"},
    {"videoCodecProfile", L"Format_Profile"},
    {"videoBitrate", L"BitRate"},
    {"videoAspectRatio", L"DisplayAspectRatio"},
    {"videoColorSpace", L"ColorSpace"},
    {"videoBitDepth", L"BitDepth"},
    {"videoStreamSize", L"StreamSize"},
};

MetadataRetriever::MetadataRetriever() { Option(L"Cover_Data", L"base64"); }

void MetadataRetriever::SetFilePath(std::string file_path) {
  Open(TO_WIDESTRING(file_path));
  
  // Extract General stream metadata
  for (auto& [property, key] : kGeneralMetadataKeys) {
    std::string value = TO_STRING(Get(MediaInfoDLL::Stream_General, 0, key));
    if (!value.empty()) {
      metadata_->insert(std::make_pair(property, value));
    }
  }
  
  // Extract Audio stream metadata (from first audio track)
  int audioStreamCount = Count_Get(MediaInfoDLL::Stream_Audio);
  if (audioStreamCount > 0) {
    for (auto& [property, key] : kAudioMetadataKeys) {
      std::string value = TO_STRING(Get(MediaInfoDLL::Stream_Audio, 0, key));
      if (!value.empty()) {
        metadata_->insert(std::make_pair(property, value));
      }
    }
  }
  
  // Extract Video stream metadata (from first video track)
  int videoStreamCount = Count_Get(MediaInfoDLL::Stream_Video);
  if (videoStreamCount > 0) {
    for (auto& [property, key] : kVideoMetadataKeys) {
      std::string value = TO_STRING(Get(MediaInfoDLL::Stream_Video, 0, key));
      if (!value.empty()) {
        metadata_->insert(std::make_pair(property, value));
      }
    }
  }
  
  metadata_->insert(std::make_pair("filePath", file_path));
  
  // Extract album art
  try {
    if (Get(MediaInfoDLL::Stream_General, 0, L"Cover") == L"Yes") {
      std::vector<uint8_t> decoded_album_art = Base64Decode(
          TO_STRING(Get(MediaInfoDLL::Stream_General, 0, L"Cover_Data")));
      album_art_.reset(new std::vector<uint8_t>(decoded_album_art));
      
      // Get album art mime type
      std::string cover_mime = TO_STRING(Get(MediaInfoDLL::Stream_General, 0, L"Cover_Mime"));
      if (!cover_mime.empty()) {
        metadata_->insert(std::make_pair("albumArtMimeType", cover_mime));
      }
      
      // Apparently libmediainfo already handles the seeking of album art
      // buffer in FLAC.
      // Its a bug in libmediainfo itself that it doesn't seek
      // METADATA_BLOCK_PICTURE in OGG & assigns it to "Cover_Data" itself.
      //
      // Letting following header seeking code stay for OGG until they fix it.
      // Further reference:
      // https://github.com/harmonoid/harmonoid/issues/76
      // https://github.com/MediaArea/MediaInfoLib/pull/1098
      //
      auto format = TO_STRING(Get(MediaInfoDLL::Stream_General, 0, L"Format"));
      if (Strings::ToUpperCase(format) == "OGG") {
        uint8_t* data = decoded_album_art.data();
        size_t size = decoded_album_art.size();
        size_t header = 0;
        uint32_t length = 0;
        RM(4);
        length = U32_AT(data);
        header += length;
        RM(4);
        RM(length);
        length = U32_AT(data);
        header += length;
        RM(4);
        RM(length);
        RM(4 * 4);
        length = U32_AT(data);
        RM(4);
        header += 32;
        size = length;
        album_art_.reset(new std::vector(data, data + length));
      }
    } else {
      album_art_ = nullptr;
    }
  } catch (...) {
    album_art_ = nullptr;
  }
}

MetadataRetriever::~MetadataRetriever() {}
