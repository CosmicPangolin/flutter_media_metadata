/**
 * Flutter Media Metadata - mediainfo.js Bridge
 * 
 * This bridge provides chunked/streaming access to mediainfo.js,
 * avoiding the need to buffer entire files in memory.
 * 
 * @see https://github.com/buzz/mediainfo.js
 */

(function() {
  'use strict';

  /**
   * Default options for MediaInfo initialization
   */
  const DEFAULT_OPTIONS = {
    coverData: true,
    chunkSize: 256 * 1024, // 256KB chunks
    format: 'object',
    full: true,
  };

  /**
   * Merge user options with defaults
   */
  function mergeOptions(userOptions) {
    return { ...DEFAULT_OPTIONS, ...userOptions };
  }

  /**
   * Parse MediaInfo result into a normalized structure
   * @param {Object} result - Raw MediaInfo result
   * @returns {Object} Normalized metadata object
   */
  function parseMediaInfoResult(result) {
    const output = {
      metadata: {},
      albumArt: null,
      albumArtMimeType: null,
      filePath: null,
      rawTracks: [],
    };

    if (!result || !result.media || !result.media.track) {
      throw new Error('Invalid MediaInfo result structure');
    }

    const tracks = result.media.track;
    output.rawTracks = tracks;

    for (const track of tracks) {
      if (track['@type'] === 'General') {
        // Basic metadata
        output.metadata.trackName = track.Track || track.Title || null;
        output.metadata.trackArtistNames = track.Performer || null;
        output.metadata.albumName = track.Album || null;
        output.metadata.albumArtistName = track.Album_Performer || null;
        output.metadata.trackNumber = track.Track_Position || null;
        output.metadata.albumLength = track.Track_Position_Total || null;
        output.metadata.year = track.Recorded_Date || null;
        output.metadata.genre = track.Genre || null;
        output.metadata.writerName = track.WrittenBy || null;
        output.metadata.authorName = track.Composer || null;
        output.metadata.discNumber = track.Part_Position || null;
        output.metadata.mimeType = track.InternetMediaType || null;
        output.metadata.trackDuration = track.Duration || null;
        output.metadata.bitrate = track.OverallBitRate || null;
        output.metadata.bpm = track.BPM || null;
        output.metadata.comment = track.Comment || null;

        // Format info
        output.metadata.format = track.Format || null;
        output.metadata.formatProfile = track.Format_Profile || null;
        output.metadata.formatVersion = track.Format_Version || null;
        output.metadata.fileSize = track.FileSize || null;
        output.metadata.encodedApplication = track.Encoded_Application || null;
        output.metadata.encodedLibrary = track.Encoded_Library || null;

        // Album art
        if (track.Cover_Data) {
          try {
            output.albumArt = track.Cover_Data;
            output.albumArtMimeType = track.Cover_Mime || null;
          } catch (e) {
            console.warn('Failed to process album art:', e);
          }
        }
      } else if (track['@type'] === 'Audio') {
        // Audio-specific metadata
        output.metadata.channels = track.Channels || null;
        output.metadata.channelPositions = track.ChannelPositions || null;
        output.metadata.channelLayout = track.ChannelLayout || null;
        output.metadata.sampleRate = track.SamplingRate || null;
        output.metadata.bitDepth = track.BitDepth || null;
        output.metadata.audioCodec = track.Format || null;
        output.metadata.audioCodecProfile = track.Format_Profile || null;
        output.metadata.audioBitrate = track.BitRate || null;
        output.metadata.audioBitrateMode = track.BitRate_Mode || null;
        output.metadata.audioStreamSize = track.StreamSize || null;
        output.metadata.audioCompressionMode = track.Compression_Mode || null;
        output.metadata.audioReplayGain = track.ReplayGain_Gain || null;
        output.metadata.audioReplayGainPeak = track.ReplayGain_Peak || null;
      } else if (track['@type'] === 'Video') {
        // Video-specific metadata
        output.metadata.width = track.Width || null;
        output.metadata.height = track.Height || null;
        output.metadata.frameRate = track.FrameRate || null;
        output.metadata.videoCodec = track.Format || null;
        output.metadata.videoCodecProfile = track.Format_Profile || null;
        output.metadata.videoBitrate = track.BitRate || null;
        output.metadata.videoAspectRatio = track.DisplayAspectRatio || null;
        output.metadata.videoColorSpace = track.ColorSpace || null;
        output.metadata.videoBitDepth = track.BitDepth || null;
        output.metadata.videoStreamSize = track.StreamSize || null;
      } else if (track['@type'] === 'Image') {
        // Image track (sometimes used for cover art)
        if (!output.metadata.width) {
          output.metadata.width = track.Width || null;
          output.metadata.height = track.Height || null;
        }
      }
    }

    return output;
  }

  /**
   * Initialize MediaInfo and analyze data using chunked reading
   * @param {Function} getSize - Returns the total size of the media
   * @param {Function} readChunk - Async function(size, offset) => Uint8Array
   * @param {Object} options - MediaInfo options
   * @returns {Promise<Object>} Parsed metadata
   */
  async function analyzeWithChunks(getSize, readChunk, options = {}) {
    const mergedOptions = mergeOptions(options);
    
    // Get MediaInfo instance
    const mediainfo = await MediaInfo(mergedOptions);
    
    try {
      const result = await mediainfo.analyzeData(getSize, readChunk);
      return parseMediaInfoResult(result);
    } finally {
      // IMPORTANT: Always close to free WASM memory
      mediainfo.close();
    }
  }

  /**
   * Analyze a File or Blob object using chunked reading
   * This is the most memory-efficient method for web file uploads
   * 
   * @param {File|Blob} file - The file to analyze
   * @param {Object} options - Optional MediaInfo options
   * @returns {Promise<Object>} Parsed metadata
   */
  async function analyzeFile(file, options = {}) {
    const getSize = () => file.size;
    
    const readChunk = async (chunkSize, offset) => {
      const chunk = file.slice(offset, offset + chunkSize);
      const buffer = await chunk.arrayBuffer();
      return new Uint8Array(buffer);
    };

    const result = await analyzeWithChunks(getSize, readChunk, options);
    
    // Add filename if available
    if (file.name) {
      result.filePath = file.name;
    }
    
    return result;
  }

  /**
   * Analyze a URL using HTTP Range requests
   * Requires server support for Range headers
   * 
   * @param {string} url - The URL to analyze
   * @param {Object} options - Optional configuration
   * @param {Object} options.headers - Additional headers for requests
   * @param {Object} options.mediaInfo - MediaInfo options
   * @returns {Promise<Object>} Parsed metadata
   */
  async function analyzeUrl(url, options = {}) {
    const { headers = {}, ...mediaInfoOptions } = options;
    
    // First, get the file size with a HEAD request
    const headResponse = await fetch(url, {
      method: 'HEAD',
      headers: headers,
    });
    
    if (!headResponse.ok) {
      throw new Error(`Failed to fetch URL: ${headResponse.status} ${headResponse.statusText}`);
    }
    
    const contentLength = headResponse.headers.get('Content-Length');
    if (!contentLength) {
      throw new Error('Server did not return Content-Length header');
    }
    
    const size = parseInt(contentLength, 10);
    if (isNaN(size) || size <= 0) {
      throw new Error(`Invalid Content-Length: ${contentLength}`);
    }

    // Check if server supports Range requests
    const acceptRanges = headResponse.headers.get('Accept-Ranges');
    if (acceptRanges === 'none') {
      throw new Error('Server does not support Range requests');
    }

    const getSize = () => size;
    
    const readChunk = async (chunkSize, offset) => {
      const end = Math.min(offset + chunkSize - 1, size - 1);
      
      const response = await fetch(url, {
        headers: {
          ...headers,
          'Range': `bytes=${offset}-${end}`,
        },
      });
      
      if (!response.ok && response.status !== 206) {
        throw new Error(`Range request failed: ${response.status} ${response.statusText}`);
      }
      
      const buffer = await response.arrayBuffer();
      return new Uint8Array(buffer);
    };

    const result = await analyzeWithChunks(getSize, readChunk, mediaInfoOptions);
    result.filePath = url;
    
    return result;
  }

  /**
   * Analyze a Uint8Array or ArrayBuffer
   * Note: The data is already in memory, but this still uses chunked
   * reading internally for consistency with MediaInfo's API
   * 
   * @param {Uint8Array|ArrayBuffer} data - The media data
   * @param {Object} options - Optional MediaInfo options
   * @returns {Promise<Object>} Parsed metadata
   */
  async function analyzeBytes(data, options = {}) {
    // Convert ArrayBuffer to Uint8Array if needed
    const bytes = data instanceof Uint8Array ? data : new Uint8Array(data);
    
    const getSize = () => bytes.length;
    
    const readChunk = (chunkSize, offset) => {
      // Synchronous slice - data already in memory
      return bytes.slice(offset, offset + chunkSize);
    };

    return await analyzeWithChunks(getSize, readChunk, options);
  }

  /**
   * Analyze using a custom chunk reader
   * For advanced use cases where you control the data source
   * 
   * @param {number} size - Total size of the media
   * @param {Function} readChunk - Async function(size, offset) => Uint8Array
   * @param {Object} options - Optional MediaInfo options
   * @returns {Promise<Object>} Parsed metadata
   */
  async function analyzeStream(size, readChunk, options = {}) {
    const getSize = () => size;
    return await analyzeWithChunks(getSize, readChunk, options);
  }

  /**
   * Check if MediaInfo is loaded and available
   * @returns {boolean}
   */
  function isMediaInfoAvailable() {
    return typeof MediaInfo !== 'undefined';
  }

  /**
   * Get MediaInfo version information
   * @returns {Promise<Object>} Version info
   */
  async function getVersion() {
    const mediainfo = await MediaInfo({ format: 'text' });
    try {
      // Analyze empty data to get version
      const version = mediainfo.inform();
      return {
        library: 'mediainfo.js',
        info: version,
      };
    } finally {
      mediainfo.close();
    }
  }

  // Expose the bridge API globally
  window.FlutterMediaInfo = {
    analyzeFile,
    analyzeUrl,
    analyzeBytes,
    analyzeStream,
    isMediaInfoAvailable,
    getVersion,
    parseMediaInfoResult,
    DEFAULT_OPTIONS,
  };

  // Log initialization
  console.log('[FlutterMediaInfo] Bridge loaded');
  
})();

