import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

// Conditional imports for web platform
import 'main_stub.dart' if (dart.library.js_interop) 'main_web.dart' as platform;

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    MaterialApp(
      title: 'Flutter Media Metadata',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Metadata? _metadata;
  bool _isLoading = false;
  String? _error;
  String? _errorType;
  String? _loadMethod;
  Duration? _loadDuration;
  String? _mediaInfoVersion;

  // Options state
  bool _extractAlbumArt = true;
  bool _fullMetadata = true;

  @override
  void initState() {
    super.initState();
    _loadMediaInfoVersion();
  }

  Future<void> _loadMediaInfoVersion() async {
    final version = await platform.getMediaInfoVersion();
    if (mounted && version != null) {
      setState(() {
        _mediaInfoVersion = version;
      });
    }
  }

  MetadataOptions get _currentOptions => MetadataOptions(
        extractAlbumArt: _extractAlbumArt,
        fullMetadata: _fullMetadata,
      );

  Future<void> _pickAndAnalyzeFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorType = null;
      _metadata = null;
      _loadMethod = null;
      _loadDuration = null;
    });

    // Update platform options
    platform.setOptions(_currentOptions);

    final stopwatch = Stopwatch()..start();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final file = result.files.first;
      final metadata = await platform.extractMetadata(file);

      stopwatch.stop();

      setState(() {
        _metadata = metadata;
        _loadMethod = platform.getLoadMethod();
        _loadDuration = stopwatch.elapsed;
        _isLoading = false;
      });
    } on MetadataLibraryException catch (e) {
      stopwatch.stop();
      setState(() {
        _error = e.message;
        _errorType = 'Library Error';
        _isLoading = false;
      });
    } on MediaSourceException catch (e) {
      stopwatch.stop();
      setState(() {
        _error = e.message;
        _errorType = 'Source Error (${e.errorType ?? 'unknown'})';
        _isLoading = false;
      });
    } on UnsupportedMediaFormatException catch (e) {
      stopwatch.stop();
      setState(() {
        _error = e.message;
        _errorType = 'Unsupported Format${e.format != null ? ' (${e.format})' : ''}';
        _isLoading = false;
      });
    } on MetadataExtractionException catch (e) {
      stopwatch.stop();
      setState(() {
        _error = e.message;
        _errorType = 'Extraction Error';
        _isLoading = false;
      });
    } on PlatformNotSupportedException catch (e) {
      stopwatch.stop();
      setState(() {
        _error = e.message;
        _errorType = 'Platform Not Supported';
        _isLoading = false;
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _error = e.toString();
        _errorType = 'Unknown Error';
        _isLoading = false;
      });
    }
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text('Extraction Options'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Extract Album Art'),
                subtitle: const Text('Disable to speed up extraction'),
                value: _extractAlbumArt,
                onChanged: (value) {
                  setDialogState(() => _extractAlbumArt = value);
                  setState(() => _extractAlbumArt = value);
                },
              ),
              SwitchListTile(
                title: const Text('Full Metadata'),
                subtitle: const Text('Extract all available fields'),
                value: _fullMetadata,
                onChanged: (value) {
                  setDialogState(() => _fullMetadata = value);
                  setState(() => _fullMetadata = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_media_metadata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showOptionsDialog,
            tooltip: 'Options',
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                label: Text(
                  platform.isMediaInfoAvailable()
                      ? 'mediainfo.js${_mediaInfoVersion != null ? ' $_mediaInfoVersion' : ''} ✓'
                      : 'mediainfo.js ✗',
                  style: TextStyle(
                    color: platform.isMediaInfoAvailable() ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickAndAnalyzeFile,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.folder_open),
        label: Text(_isLoading ? 'Analyzing...' : 'Open Media File'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Extracting metadata...'),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Using chunked streaming - only reading needed bytes',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            if (!_extractAlbumArt || !_fullMetadata)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (!_extractAlbumArt)
                      const Chip(
                        label: Text('No album art', style: TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (!_fullMetadata)
                      const Chip(
                        label: Text('Basic metadata', style: TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorType ?? 'Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red.shade300,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              if (kIsWeb && !platform.isMediaInfoAvailable()) ...[
                const SizedBox(height: 16),
                const Text(
                  'Make sure mediainfo.js and mediainfo_bridge.js are loaded in index.html',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_metadata == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.audio_file,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a media file to analyze',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'On web, uses chunked streaming for memory efficiency'
                  : 'Supports audio and video files',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    _extractAlbumArt ? Icons.check : Icons.close,
                    size: 16,
                    color: _extractAlbumArt ? Colors.green : Colors.grey,
                  ),
                  label: const Text('Album Art'),
                ),
                Chip(
                  avatar: Icon(
                    _fullMetadata ? Icons.check : Icons.close,
                    size: 16,
                    color: _fullMetadata ? Colors.green : Colors.grey,
                  ),
                  label: const Text('Full Metadata'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _MetadataDisplay(
      metadata: _metadata!,
      loadMethod: _loadMethod,
      loadDuration: _loadDuration,
    );
  }
}

class _MetadataDisplay extends StatelessWidget {
  final Metadata metadata;
  final String? loadMethod;
  final Duration? loadDuration;

  const _MetadataDisplay({
    required this.metadata,
    this.loadMethod,
    this.loadDuration,
  });

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).size.height > MediaQuery.of(context).size.width;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(context, isPortrait),
        ),

        if (loadMethod != null || loadDuration != null)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed, size: 20, color: Colors.teal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (loadMethod != null)
                          Text(
                            loadMethod!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        if (loadDuration != null)
                          Text(
                            'Completed in ${loadDuration!.inMilliseconds}ms',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: _buildMetadataSection(
            context,
            'Basic Info',
            Icons.info_outline,
            [
              _MetadataRow('Track Name', metadata.trackName),
              _MetadataRow('Artists', metadata.trackArtistNames?.join(', ')),
              _MetadataRow('Album', metadata.albumName),
              _MetadataRow('Album Artist', metadata.albumArtistName),
              _MetadataRow('Track', metadata.trackNumber != null
                  ? '${metadata.trackNumber}${metadata.albumLength != null ? ' of ${metadata.albumLength}' : ''}'
                  : null),
              _MetadataRow('Disc', metadata.discNumber?.toString()),
              _MetadataRow('Year', metadata.year?.toString()),
              _MetadataRow('Genre', metadata.genre),
              _MetadataRow('BPM', metadata.bpm?.toString()),
              _MetadataRow('Comment', metadata.comment),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: _buildMetadataSection(
            context,
            'Audio',
            Icons.audiotrack,
            [
              _MetadataRow('Duration', metadata.durationString),
              _MetadataRow('Bitrate', metadata.bitrateString),
              _MetadataRow('Sample Rate', metadata.sampleRateString),
              _MetadataRow('Channels', metadata.channels?.toString()),
              _MetadataRow('Bit Depth', metadata.bitDepth != null ? '${metadata.bitDepth} bit' : null),
              _MetadataRow('Codec', metadata.audioCodec),
              _MetadataRow('Codec Profile', metadata.audioCodecProfile),
              _MetadataRow('Bitrate Mode', metadata.audioBitrateMode),
              _MetadataRow('Compression', metadata.audioCompressionMode),
              _MetadataRow('ReplayGain', metadata.audioReplayGain),
            ],
          ),
        ),

        if (metadata.hasVideo)
          SliverToBoxAdapter(
            child: _buildMetadataSection(
              context,
              'Video',
              Icons.videocam,
              [
                _MetadataRow('Resolution', metadata.resolutionString),
                _MetadataRow('Frame Rate', metadata.frameRate != null ? '${metadata.frameRate} fps' : null),
                _MetadataRow('Codec', metadata.videoCodec),
                _MetadataRow('Codec Profile', metadata.videoCodecProfile),
                _MetadataRow('Bitrate', metadata.videoBitrate != null ? '${(metadata.videoBitrate! / 1000).round()} kbps' : null),
                _MetadataRow('Aspect Ratio', metadata.videoAspectRatio),
                _MetadataRow('Color Space', metadata.videoColorSpace),
                _MetadataRow('Bit Depth', metadata.videoBitDepth?.toString()),
              ],
            ),
          ),

        SliverToBoxAdapter(
          child: _buildMetadataSection(
            context,
            'File',
            Icons.insert_drive_file,
            [
              _MetadataRow('Format', metadata.format),
              _MetadataRow('Format Profile', metadata.formatProfile),
              _MetadataRow('MIME Type', metadata.mimeType),
              _MetadataRow('File Size', metadata.fileSize != null
                  ? '${(metadata.fileSize! / 1024 / 1024).toStringAsFixed(2)} MB'
                  : null),
              _MetadataRow('File Path', metadata.filePath),
              _MetadataRow('Encoder', metadata.encodedApplication ?? metadata.encodedLibrary),
            ],
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isPortrait) {
    final albumArtWidget = metadata.hasAlbumArt
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              metadata.albumArt!,
              width: isPortrait ? double.infinity : 200,
              height: isPortrait ? 300 : 200,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            width: isPortrait ? double.infinity : 200,
            height: isPortrait ? 200 : 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.album,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          );

    final infoWidget = Column(
      crossAxisAlignment: isPortrait ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          metadata.trackName ?? 'Unknown Track',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: isPortrait ? TextAlign.center : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (metadata.trackArtistNames != null) ...[
          const SizedBox(height: 4),
          Text(
            metadata.trackArtistNames!.join(', '),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: isPortrait ? TextAlign.center : TextAlign.start,
          ),
        ],
        if (metadata.albumName != null) ...[
          const SizedBox(height: 4),
          Text(
            metadata.albumName!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: isPortrait ? TextAlign.center : TextAlign.start,
          ),
        ],
      ],
    );

    if (isPortrait) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            albumArtWidget,
            const SizedBox(height: 16),
            infoWidget,
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            albumArtWidget,
            const SizedBox(width: 16),
            Expanded(child: infoWidget),
          ],
        ),
      );
    }
  }

  Widget _buildMetadataSection(
    BuildContext context,
    String title,
    IconData icon,
    List<_MetadataRow> rows,
  ) {
    final nonNullRows = rows.where((r) => r.value != null).toList();
    if (nonNullRows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: nonNullRows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: index < nonNullRows.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.3),
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          row.label,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.value!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataRow {
  final String label;
  final String? value;

  _MetadataRow(this.label, this.value);
}
