import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Full screen image viewer with pinch to zoom, download and share options
class ImageMessageViewer extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final String? senderName;
  final DateTime? sentAt;

  const ImageMessageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.senderName,
    this.sentAt,
  });

  @override
  State<ImageMessageViewer> createState() => _ImageMessageViewerState();
}

class _ImageMessageViewerState extends State<ImageMessageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _showControls = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });

    // Hide system UI for immersive view
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    final position = details.localPosition;
    final double scale =
        _transformationController.value.getMaxScaleOnAxis() > 1.5 ? 1.0 : 3.0;

    final Matrix4 endMatrix;
    if (scale == 1.0) {
      endMatrix = Matrix4.identity();
    } else {
      // Create scaled matrix with translation
      endMatrix = Matrix4.identity()
        ..setEntry(0, 3, -position.dx * (scale - 1))
        ..setEntry(1, 3, -position.dy * (scale - 1))
        ..setEntry(0, 0, scale)
        ..setEntry(1, 1, scale);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Get the cached file from CachedNetworkImage
      final cacheManager = DefaultCacheManager();
      final file = await cacheManager.getSingleFile(widget.imageUrl);

      // Get the downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'chat_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${directory.path}/$fileName');

      // Copy the file
      await file.copy(savedFile.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('chat.imageSaved'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('chat.downloadFailed'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _shareImage() async {
    try {
      // Get the cached file from CachedNetworkImage
      final cacheManager = DefaultCacheManager();
      final file = await cacheManager.getSingleFile(widget.imageUrl);

      // Read the file as bytes
      final Uint8List bytes = await file.readAsBytes();

      // Create a temporary file for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/share_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);

      // Share using share_plus
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: widget.senderName != null
            ? 'Shared from ${widget.senderName}'
            : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('chat.shareFailed'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image with interactive viewer
          GestureDetector(
            onTap: _toggleControls,
            onDoubleTapDown: _handleDoubleTap,
            onDoubleTap: () {}, // Required for onDoubleTapDown to work
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Hero(
                  tag: widget.heroTag,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'chat.imageLoadFailed'.tr(),
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top bar with close button and info
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: widget.senderName != null || widget.sentAt != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.senderName != null)
                              Text(
                                widget.senderName!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (widget.sentAt != null)
                              Text(
                                DateFormat('MMM d, y HH:mm')
                                    .format(widget.sentAt!),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Bottom bar with actions
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Download button
                      _ActionButton(
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download, color: Colors.white),
                        label: 'chat.download'.tr(),
                        onTap: _downloadImage,
                      ),

                      // Share button
                      _ActionButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: 'chat.share'.tr(),
                        onTap: _shareImage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button for the bottom bar
class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
