package com.alexmercerind.flutter_media_metadata;

import android.media.MediaMetadataRetriever;
import android.media.MediaFormat;
import android.media.MediaExtractor;
import java.util.HashMap;
import java.io.File;

public class MetadataRetriever extends MediaMetadataRetriever {
  private String filePath;
  
  public MetadataRetriever() {
    super();
  }

  public void setFilePath(String filePath) {
    this.filePath = filePath;
    setDataSource(filePath);
  }

  public HashMap<String, Object> getMetadata() {
    HashMap<String, Object> metadata = new HashMap<String, Object>();
    
    // Basic track info
    metadata.put("trackName", extractMetadata(METADATA_KEY_TITLE));
    metadata.put("trackArtistNames", extractMetadata(METADATA_KEY_ARTIST));
    metadata.put("albumName", extractMetadata(METADATA_KEY_ALBUM));
    metadata.put("albumArtistName", extractMetadata(METADATA_KEY_ALBUMARTIST));
    
    // Track number parsing (may be in format "1/12")
    String trackNumber = extractMetadata(METADATA_KEY_CD_TRACK_NUMBER);
    try {
      if (trackNumber != null && trackNumber.contains("/")) {
        String[] parts = trackNumber.split("/");
        metadata.put("trackNumber", parts[0].trim());
        metadata.put("albumLength", parts[parts.length - 1].trim());
      } else {
        metadata.put("trackNumber", trackNumber);
        metadata.put("albumLength", null);
      }
    } catch (Exception error) {
      metadata.put("trackNumber", trackNumber);
      metadata.put("albumLength", null);
    }
    
    // Year parsing
    String year = extractMetadata(METADATA_KEY_YEAR);
    String date = extractMetadata(METADATA_KEY_DATE);
    try {
      if (year != null && !year.isEmpty()) {
        metadata.put("year", year.trim());
      } else if (date != null && !date.isEmpty()) {
        // Extract year from date (may be YYYY-MM-DD format)
        metadata.put("year", date.split("-")[0].trim());
      } else {
        metadata.put("year", null);
      }
    } catch (Exception e) {
      metadata.put("year", null);
    }
    
    metadata.put("genre", extractMetadata(METADATA_KEY_GENRE));
    metadata.put("authorName", extractMetadata(METADATA_KEY_AUTHOR));
    metadata.put("writerName", extractMetadata(METADATA_KEY_WRITER));
    metadata.put("discNumber", extractMetadata(METADATA_KEY_DISC_NUMBER));
    metadata.put("mimeType", extractMetadata(METADATA_KEY_MIMETYPE));
    metadata.put("trackDuration", extractMetadata(METADATA_KEY_DURATION));
    metadata.put("bitrate", extractMetadata(METADATA_KEY_BITRATE));
    
    // Note: BPM and Comment are not available via MediaMetadataRetriever
    // They would require parsing ID3 tags directly (e.g., with JAudioTagger library)
    // metadata.put("bpm", null);
    // metadata.put("comment", null);
    
    // Video metadata
    String hasVideo = extractMetadata(METADATA_KEY_HAS_VIDEO);
    if ("yes".equalsIgnoreCase(hasVideo)) {
      metadata.put("width", extractMetadata(METADATA_KEY_VIDEO_WIDTH));
      metadata.put("height", extractMetadata(METADATA_KEY_VIDEO_HEIGHT));
      metadata.put("frameRate", extractMetadata(METADATA_KEY_CAPTURE_FRAMERATE));
      metadata.put("videoCodec", null); // Not directly available via MediaMetadataRetriever
    }
    
    // Audio metadata - try to get from MediaExtractor
    try {
      extractAudioMetadata(metadata);
    } catch (Exception e) {
      // Audio metadata extraction failed, continue without it
    }
    
    // File size
    try {
      File file = new File(filePath);
      if (file.exists()) {
        metadata.put("fileSize", String.valueOf(file.length()));
      }
    } catch (Exception e) {
      // Ignore file size errors
    }
    
    return metadata;
  }
  
  private void extractAudioMetadata(HashMap<String, Object> metadata) {
    MediaExtractor extractor = null;
    try {
      extractor = new MediaExtractor();
      extractor.setDataSource(filePath);
      
      boolean foundAudio = false;
      boolean foundVideo = false;
      
      int trackCount = extractor.getTrackCount();
      for (int i = 0; i < trackCount; i++) {
        MediaFormat format = extractor.getTrackFormat(i);
        String mime = format.getString(MediaFormat.KEY_MIME);
        
        if (!foundAudio && mime != null && mime.startsWith("audio/")) {
          // Audio track found
          foundAudio = true;
          if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
            metadata.put("channels", String.valueOf(format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)));
          }
          if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
            metadata.put("sampleRate", String.valueOf(format.getInteger(MediaFormat.KEY_SAMPLE_RATE)));
          }
          if (format.containsKey(MediaFormat.KEY_BIT_RATE)) {
            metadata.put("audioBitrate", String.valueOf(format.getInteger(MediaFormat.KEY_BIT_RATE)));
          }
          // Extract codec from mime type (e.g., "audio/mp4a-latm" -> "AAC")
          metadata.put("audioCodec", mimeToCodecName(mime));
        }
        
        if (!foundVideo && mime != null && mime.startsWith("video/")) {
          // Video track found
          foundVideo = true;
          if (format.containsKey(MediaFormat.KEY_WIDTH)) {
            metadata.put("width", String.valueOf(format.getInteger(MediaFormat.KEY_WIDTH)));
          }
          if (format.containsKey(MediaFormat.KEY_HEIGHT)) {
            metadata.put("height", String.valueOf(format.getInteger(MediaFormat.KEY_HEIGHT)));
          }
          if (format.containsKey(MediaFormat.KEY_FRAME_RATE)) {
            metadata.put("frameRate", String.valueOf(format.getInteger(MediaFormat.KEY_FRAME_RATE)));
          }
          if (format.containsKey(MediaFormat.KEY_BIT_RATE)) {
            metadata.put("videoBitrate", String.valueOf(format.getInteger(MediaFormat.KEY_BIT_RATE)));
          }
          metadata.put("videoCodec", mimeToCodecName(mime));
        }
        
        // Stop if we found both
        if (foundAudio && foundVideo) {
          break;
        }
      }
    } catch (Exception e) {
      // Extraction failed
    } finally {
      if (extractor != null) {
        extractor.release();
      }
    }
  }
  
  private String mimeToCodecName(String mime) {
    if (mime == null) return null;
    
    // Audio codecs
    if (mime.contains("mp4a") || mime.contains("aac")) return "AAC";
    if (mime.contains("mp3") || mime.contains("mpeg")) return "MP3";
    if (mime.contains("flac")) return "FLAC";
    if (mime.contains("vorbis")) return "Vorbis";
    if (mime.contains("opus")) return "Opus";
    if (mime.contains("wav") || mime.contains("raw")) return "PCM";
    
    // Video codecs
    if (mime.contains("avc") || mime.contains("h264")) return "H.264/AVC";
    if (mime.contains("hevc") || mime.contains("h265")) return "H.265/HEVC";
    if (mime.contains("vp8")) return "VP8";
    if (mime.contains("vp9")) return "VP9";
    if (mime.contains("av01")) return "AV1";
    
    return mime;
  }

  public byte[] getAlbumArt() {
    return getEmbeddedPicture();
  }
  
  /**
   * Get the MIME type of the album art by examining magic bytes.
   * Returns null if no album art or unrecognized format.
   */
  public String getAlbumArtMimeType() {
    byte[] art = getEmbeddedPicture();
    if (art == null || art.length < 4) {
      return null;
    }
    
    // Check magic bytes
    // JPEG: FF D8 FF
    if (art[0] == (byte)0xFF && art[1] == (byte)0xD8 && art[2] == (byte)0xFF) {
      return "image/jpeg";
    }
    // PNG: 89 50 4E 47
    if (art[0] == (byte)0x89 && art[1] == (byte)0x50 && art[2] == (byte)0x4E && art[3] == (byte)0x47) {
      return "image/png";
    }
    // GIF: 47 49 46 38
    if (art[0] == (byte)0x47 && art[1] == (byte)0x49 && art[2] == (byte)0x46 && art[3] == (byte)0x38) {
      return "image/gif";
    }
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (art[0] == (byte)0x52 && art[1] == (byte)0x49 && art[2] == (byte)0x46 && art[3] == (byte)0x46 && art.length > 11) {
      if (art[8] == (byte)0x57 && art[9] == (byte)0x45 && art[10] == (byte)0x42 && art[11] == (byte)0x50) {
        return "image/webp";
      }
    }
    // BMP: 42 4D
    if (art[0] == (byte)0x42 && art[1] == (byte)0x4D) {
      return "image/bmp";
    }
    
    return null;
  }
}
