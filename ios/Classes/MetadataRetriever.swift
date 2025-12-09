import AVFoundation
import Foundation

#if os(macOS)
  import CoreServices
#elseif os(iOS)
  import MobileCoreServices
#endif

protocol MetadataRetrieverProtocol {
  func getTrackName() -> String?
  func getArtistNames() -> String?
  func getAlbumName() -> String?
  func getAlbumArtistName() -> String?
  func getTrackNumber() -> String?
  func getAlbumLength() -> String?
  func getYear() -> String?
  func getGenre() -> String?
  func getAuthorName() -> String?
  func getWriterName() -> String?
  func getDiscNumber() -> String?
  func getBpm() -> String?
  func getComment() -> String?
  func getAlbumArt() -> Data?
}

public class MetadataRetriever {
  let filePath: String
  let url: URL
  let asset: AVAsset
  let preferredRetriever: MetadataRetrieverProtocol?

  init(_ filePath: String) {
    self.filePath = filePath
    self.url = URL(fileURLWithPath: self.filePath)

    let asset = AVAsset(url: url)
    let preferredRetriever: MetadataRetrieverProtocol? = {
      if asset.availableMetadataFormats.contains(.id3Metadata) {
        return Id3MetadataRetriever(asset.metadata(forFormat: .id3Metadata))
      }

      if asset.availableMetadataFormats.contains(.iTunesMetadata) {
        return ItunesMetadataRetriever(asset.metadata(forFormat: .iTunesMetadata))
      }

      return nil
    }()

    self.asset = asset
    self.preferredRetriever = preferredRetriever
  }

  public func getMetadata() -> [String: Any] {
    var metadata: [String: Any] = [:]

    // Basic track info
    metadata["trackName"] = getTrackName()
    metadata["trackArtistNames"] = getArtistNames()
    metadata["albumName"] = getAlbumName()
    metadata["albumArtistName"] = getAlbumArtistName()
    metadata["trackNumber"] = getTrackNumber()
    metadata["albumLength"] = getAlbumLength()
    metadata["year"] = getYear()
    metadata["genre"] = getGenre()
    metadata["authorName"] = getAuthorName()
    metadata["writerName"] = getWriterName()
    metadata["discNumber"] = getDiscNumber()
    metadata["mimeType"] = getMimeType()
    metadata["trackDuration"] = getDuration()
    metadata["bitrate"] = getBitrate()
    metadata["bpm"] = getBpm()
    metadata["comment"] = getComment()
    
    // File size
    metadata["fileSize"] = getFileSize()
    
    // Audio track metadata
    if let audioMetadata = getAudioTrackMetadata() {
      for (key, value) in audioMetadata {
        metadata[key] = value
      }
    }
    
    // Video track metadata
    if let videoMetadata = getVideoTrackMetadata() {
      for (key, value) in videoMetadata {
        metadata[key] = value
      }
    }
    
    // Format info
    metadata["format"] = getFormat()
    
    return metadata
  }

  private func getTrackName() -> String? {
    return preferredRetriever?.getTrackName()
  }

  private func getArtistNames() -> String? {
    return preferredRetriever?.getArtistNames()
  }

  private func getAlbumName() -> String? {
    return preferredRetriever?.getAlbumName()
  }

  private func getAlbumArtistName() -> String? {
    return preferredRetriever?.getAlbumArtistName()
  }

  private func getTrackNumber() -> String? {
    return preferredRetriever?.getTrackNumber()
  }

  private func getAlbumLength() -> String? {
    return preferredRetriever?.getAlbumLength()
  }

  private func getYear() -> String? {
    return preferredRetriever?.getYear()
  }

  private func getGenre() -> String? {
    return preferredRetriever?.getGenre()
  }

  private func getAuthorName() -> String? {
    return preferredRetriever?.getAuthorName()
  }

  private func getWriterName() -> String? {
    return preferredRetriever?.getWriterName()
  }

  private func getDiscNumber() -> String? {
    return preferredRetriever?.getDiscNumber()
  }
  
  private func getBpm() -> String? {
    return preferredRetriever?.getBpm()
  }
  
  private func getComment() -> String? {
    return preferredRetriever?.getComment()
  }

  private func getDuration() -> String {
    let milliseconds = Int(Float64(asset.duration.value * 1000) / Float64(asset.duration.timescale))
    return String(milliseconds)
  }

  private func getBitrate() -> String? {
    // NOTE: AVAssetTrack:estimatedDataRate returns 0.0 if file is mp3
    var audioFileRef: ExtAudioFileRef?
    let openFileResult = ExtAudioFileOpenURL(url as CFURL, &audioFileRef)
    guard let audioFileRef = audioFileRef, openFileResult == 0 else {
      return nil
    }

    var audioFileID: AudioFileID?
    var propertyDataSize = UInt32(MemoryLayout<AudioFileID>.size)
    let getPropertyResult = ExtAudioFileGetProperty(
      audioFileRef, kExtAudioFileProperty_AudioFile, &propertyDataSize, &audioFileID)
    guard let audioFileID = audioFileID, getPropertyResult == 0 else {
      return nil
    }

    var bitRate: UInt32 = 0
    var bitRateSize = UInt32(MemoryLayout.size(ofValue: bitRate))
    let getBitRateResult = AudioFileGetProperty(
      audioFileID, kAudioFilePropertyBitRate, &bitRateSize, &bitRate)
    guard getBitRateResult == 0 else {
      return nil
    }
    return String(bitRate)
  }

  private func getMimeType() -> String? {
    let pathExtension = self.url.pathExtension
    guard
      let identifier = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue()
    else {
      return nil
    }

    return UTTypeCopyPreferredTagWithClass(identifier, kUTTagClassMIMEType)?.takeRetainedValue()
      as? String
  }
  
  private func getFileSize() -> String? {
    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
      if let fileSize = attributes[.size] as? Int64 {
        return String(fileSize)
      }
    } catch {
      // Ignore errors
    }
    return nil
  }
  
  private func getFormat() -> String? {
    let pathExtension = self.url.pathExtension.uppercased()
    switch pathExtension {
    case "MP3":
      return "MPEG Audio"
    case "M4A", "AAC":
      return "AAC"
    case "FLAC":
      return "FLAC"
    case "WAV":
      return "WAV"
    case "OGG":
      return "Ogg"
    case "MP4", "M4V":
      return "MPEG-4"
    case "MOV":
      return "QuickTime"
    case "AVI":
      return "AVI"
    case "MKV":
      return "Matroska"
    default:
      return pathExtension
    }
  }
  
  private func getAudioTrackMetadata() -> [String: Any]? {
    guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
      return nil
    }
    
    var metadata: [String: Any] = [:]
    
    // Get format descriptions
    if let formatDescriptions = audioTrack.formatDescriptions as? [CMFormatDescription],
       let formatDescription = formatDescriptions.first {
      
      // Get audio stream basic description
      if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee {
        metadata["sampleRate"] = String(Int(asbd.mSampleRate))
        metadata["channels"] = String(asbd.mChannelsPerFrame)
        
        if asbd.mBitsPerChannel > 0 {
          metadata["bitDepth"] = String(asbd.mBitsPerChannel)
        }
      }
      
      // Get codec
      let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
      metadata["audioCodec"] = fourCCToCodecName(mediaSubType)
    }
    
    // Estimated bitrate
    let estimatedBitrate = audioTrack.estimatedDataRate
    if estimatedBitrate > 0 {
      metadata["audioBitrate"] = String(Int(estimatedBitrate))
    }
    
    return metadata
  }
  
  private func getVideoTrackMetadata() -> [String: Any]? {
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      return nil
    }
    
    var metadata: [String: Any] = [:]
    
    // Dimensions
    let size = videoTrack.naturalSize
    metadata["width"] = String(Int(size.width))
    metadata["height"] = String(Int(size.height))
    
    // Frame rate
    let frameRate = videoTrack.nominalFrameRate
    if frameRate > 0 {
      metadata["frameRate"] = String(format: "%.3f", frameRate)
    }
    
    // Estimated bitrate
    let estimatedBitrate = videoTrack.estimatedDataRate
    if estimatedBitrate > 0 {
      metadata["videoBitrate"] = String(Int(estimatedBitrate))
    }
    
    // Get format descriptions for codec info
    if let formatDescriptions = videoTrack.formatDescriptions as? [CMFormatDescription],
       let formatDescription = formatDescriptions.first {
      let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)
      metadata["videoCodec"] = fourCCToCodecName(mediaSubType)
    }
    
    return metadata
  }
  
  private func fourCCToCodecName(_ fourCC: FourCharCode) -> String {
    switch fourCC {
    // Audio codecs
    case kAudioFormatMPEGLayer3:
      return "MP3"
    case kAudioFormatMPEG4AAC, kAudioFormatMPEG4AAC_HE, kAudioFormatMPEG4AAC_HE_V2:
      return "AAC"
    case kAudioFormatAppleLossless:
      return "ALAC"
    case kAudioFormatFLAC:
      return "FLAC"
    case kAudioFormatLinearPCM:
      return "PCM"
    case kAudioFormatOpus:
      return "Opus"
    // Video codecs
    case kCMVideoCodecType_H264:
      return "H.264/AVC"
    case kCMVideoCodecType_HEVC:
      return "H.265/HEVC"
    case kCMVideoCodecType_VP9:
      return "VP9"
    case kCMVideoCodecType_AV1:
      return "AV1"
    default:
      // Convert FourCC to string
      let chars = [
        Character(UnicodeScalar((fourCC >> 24) & 0xFF)!),
        Character(UnicodeScalar((fourCC >> 16) & 0xFF)!),
        Character(UnicodeScalar((fourCC >> 8) & 0xFF)!),
        Character(UnicodeScalar(fourCC & 0xFF)!)
      ]
      return String(chars).trimmingCharacters(in: .whitespaces)
    }
  }

  public func getAlbumArt() -> Data? {
    return preferredRetriever?.getAlbumArt()
  }
  
  /// Get the MIME type of the album art by examining magic bytes.
  public func getAlbumArtMimeType() -> String? {
    guard let data = getAlbumArt(), data.count >= 4 else {
      return nil
    }
    
    let bytes = [UInt8](data.prefix(12))
    
    // JPEG: FF D8 FF
    if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
      return "image/jpeg"
    }
    // PNG: 89 50 4E 47
    if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
      return "image/png"
    }
    // GIF: 47 49 46 38
    if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38 {
      return "image/gif"
    }
    // WebP: 52 49 46 46 ... 57 45 42 50
    if bytes.count >= 12 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 {
      if bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50 {
        return "image/webp"
      }
    }
    // BMP: 42 4D
    if bytes[0] == 0x42 && bytes[1] == 0x4D {
      return "image/bmp"
    }
    
    return nil
  }
}
