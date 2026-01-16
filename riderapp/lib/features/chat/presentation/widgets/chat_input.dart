import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Selected attachment data
class SelectedAttachment {
  final File file;
  final String fileName;
  final int fileSize;

  const SelectedAttachment({
    required this.file,
    required this.fileName,
    required this.fileSize,
  });
}

/// Chat input widget with image attachment support
class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final Function(File file, String? caption)? onSendImage;
  final bool isSending;
  final bool isUploading;
  final double uploadProgress;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onSendImage,
    this.isSending = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  bool _hasText = false;
  SelectedAttachment? _selectedAttachment;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (widget.isSending || widget.isUploading) return;

    // If there's an image selected, send it with optional caption
    if (_selectedAttachment != null) {
      final caption = _controller.text.trim();
      widget.onSendImage?.call(
        _selectedAttachment!.file,
        caption.isNotEmpty ? caption : null,
      );
      _controller.clear();
      setState(() {
        _selectedAttachment = null;
      });
      return;
    }

    // Otherwise send text message
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text('chat.takePhoto'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text('chat.chooseFromGallery'.tr()),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        final fileName = pickedFile.name;

        setState(() {
          _selectedAttachment = SelectedAttachment(
            file: file,
            fileName: fileName,
            fileSize: fileSize,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('chat.imagePickerError'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _cancelAttachment() {
    setState(() {
      _selectedAttachment = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            if (_selectedAttachment != null) _buildImagePreview(colorScheme),

            // Upload progress
            if (widget.isUploading) _buildUploadProgress(colorScheme),

            // Input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  IconButton(
                    onPressed: widget.isUploading ? null : _showAttachmentOptions,
                    icon: const Icon(Icons.attach_file),
                    color: colorScheme.onSurfaceVariant,
                  ),

                  // Text input
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !widget.isUploading,
                        decoration: InputDecoration(
                          hintText: _selectedAttachment != null
                              ? 'chat.addCaption'.tr()
                              : 'chat.typeMessage'.tr(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  _buildSendButton(colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Image thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedAttachment!.file,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedAttachment!.fileName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatFileSize(_selectedAttachment!.fileSize),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          // Cancel button
          IconButton(
            onPressed: widget.isUploading ? null : _cancelAttachment,
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'chat.uploading'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                '${(widget.uploadProgress * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: widget.uploadProgress,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(ColorScheme colorScheme) {
    final canSend = (_hasText || _selectedAttachment != null) &&
        !widget.isSending &&
        !widget.isUploading;

    if (widget.isSending || widget.isUploading) {
      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(12),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
    }

    return IconButton(
      onPressed: canSend ? _handleSend : null,
      icon: Icon(
        _selectedAttachment != null ? Icons.send_rounded : Icons.send_rounded,
        color: canSend ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      style: IconButton.styleFrom(
        backgroundColor: canSend ? colorScheme.primaryContainer : null,
      ),
    );
  }
}
