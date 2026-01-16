import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/upload/image_picker_helper.dart';
import '../../domain/entities/incident.dart';
import '../providers/incidents_provider.dart';
import '../providers/incidents_state.dart';

/// Screen to create or edit an incident
class CreateIncidentScreen extends ConsumerStatefulWidget {
  /// If not null, we're editing an existing incident
  final String? incidentId;

  const CreateIncidentScreen({
    super.key,
    this.incidentId,
  });

  @override
  ConsumerState<CreateIncidentScreen> createState() =>
      _CreateIncidentScreenState();
}

class _CreateIncidentScreenState extends ConsumerState<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();

  IncidentCategory _selectedCategory = IncidentCategory.general;
  IncidentPriority _selectedPriority = IncidentPriority.medium;
  DateTime? _incidentDate;
  bool _isAnonymous = false;
  double? _latitude;
  double? _longitude;

  bool get isEditing => widget.incidentId != null;
  Incident? _existingIncident;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      // Load existing incident data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingIncident();
      });
    }
  }

  Future<void> _loadExistingIncident() async {
    try {
      final incident = await ref
          .read(incidentsRepositoryProvider)
          .getIncidentById(widget.incidentId!);

      setState(() {
        _existingIncident = incident;
        _titleController.text = incident.title;
        _descriptionController.text = incident.description;
        _addressController.text = incident.location.address ?? '';
        _provinceController.text = incident.location.province ?? '';
        _districtController.text = incident.location.district ?? '';
        _selectedCategory = incident.category;
        _selectedPriority = incident.priority;
        _incidentDate = incident.incidentDate;
        _isAnonymous = incident.isAnonymous;
        _latitude = incident.location.latitude;
        _longitude = incident.location.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load incident: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentDate ?? DateTime.now()),
    );

    if (time == null) return;

    setState(() {
      _incidentDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    // TODO: Implement actual location fetching using geolocator package
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location feature coming soon'),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(createIncidentProvider.notifier);

    if (isEditing) {
      notifier.updateIncident(
        widget.incidentId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        locationLat: _latitude,
        locationLng: _longitude,
        locationAddress: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        locationProvince: _provinceController.text.trim().isNotEmpty
            ? _provinceController.text.trim()
            : null,
        locationDistrict: _districtController.text.trim().isNotEmpty
            ? _districtController.text.trim()
            : null,
        incidentDate: _incidentDate,
        isAnonymous: _isAnonymous,
      );
    } else {
      notifier.createIncident(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        locationLat: _latitude,
        locationLng: _longitude,
        locationAddress: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        locationProvince: _provinceController.text.trim().isNotEmpty
            ? _provinceController.text.trim()
            : null,
        locationDistrict: _districtController.text.trim().isNotEmpty
            ? _districtController.text.trim()
            : null,
        incidentDate: _incidentDate,
        isAnonymous: _isAnonymous,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createIncidentProvider);

    // Listen for success state
    ref.listen<CreateIncidentState>(createIncidentProvider, (previous, next) async {
      if (next is CreateIncidentSuccess) {
        // Upload pending attachments if any
        final pendingFiles = ref.read(pendingAttachmentsProvider).pendingFiles;
        if (pendingFiles.isNotEmpty && !next.isUpdate) {
          final uploadResult = await ref
              .read(attachmentUploadProvider.notifier)
              .uploadAttachments(next.incident.id, pendingFiles);

          if (uploadResult == null && mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incident created, but some attachments failed to upload'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        // Clear pending attachments
        ref.read(pendingAttachmentsProvider.notifier).reset();

        // Update lists
        ref.read(myIncidentsListProvider.notifier).addIncidentToList(next.incident);
        if (!next.isUpdate) {
          ref.read(incidentsListProvider.notifier).addIncidentToList(next.incident);
        }

        // Show success message
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next.isUpdate
                    ? 'Incident updated successfully'
                    : 'Incident reported successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back
          context.pop();
        }

        // Reset state
        ref.read(createIncidentProvider.notifier).reset();
      } else if (next is CreateIncidentError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });

    final isLoading = state is CreateIncidentLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Incident' : 'incidents.create'.tr()),
      ),
      body: isEditing && _existingIncident == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Category selection
                    _buildSectionTitle('incidents.form.selectCategory'.tr()),
                    const SizedBox(height: 8),
                    _buildCategorySelector(),
                    const SizedBox(height: 24),

                    // Priority selection
                    _buildSectionTitle('Priority'),
                    const SizedBox(height: 8),
                    _buildPrioritySelector(),
                    const SizedBox(height: 24),

                    // Title field
                    _buildSectionTitle('incidents.form.title'.tr()),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter a brief title for the incident',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        if (value.trim().length < 5) {
                          return 'Title must be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Description field
                    _buildSectionTitle('incidents.form.description'.tr()),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Describe the incident in detail',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        if (value.trim().length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Location section
                    _buildSectionTitle('incidents.form.location'.tr()),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText: 'Enter address or location',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.location_on_outlined),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          tooltip: 'Use current location',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _provinceController,
                            decoration: InputDecoration(
                              hintText: 'Province',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _districtController,
                            decoration: InputDecoration(
                              hintText: 'District',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Incident date/time
                    _buildSectionTitle('When did it happen?'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _incidentDate != null
                            ? DateFormat('dd MMM yyyy, HH:mm')
                                .format(_incidentDate!)
                            : 'Select date and time',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Attachments section
                    _buildAttachmentsSection(),
                    const SizedBox(height: 24),

                    // Anonymous toggle
                    _buildAnonymousToggle(),
                    const SizedBox(height: 32),

                    // Submit button
                    FilledButton(
                      onPressed: isLoading ? null : _submitForm,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing
                                  ? 'common.save'.tr()
                                  : 'incidents.form.submit'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: IncidentCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return ChoiceChip(
          label: Text(_getCategoryLabel(category)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedCategory = category);
            }
          },
          avatar: Icon(
            _getCategoryIcon(category),
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
          ),
        );
      }).toList(),
    );
  }

  String _getCategoryLabel(IncidentCategory category) {
    switch (category) {
      case IncidentCategory.intelligence:
        return 'incidents.categories.intelligence'.tr();
      case IncidentCategory.accident:
        return 'incidents.categories.accident'.tr();
      case IncidentCategory.general:
        return 'incidents.categories.general'.tr();
    }
  }

  IconData _getCategoryIcon(IncidentCategory category) {
    switch (category) {
      case IncidentCategory.intelligence:
        return Icons.lightbulb_outline;
      case IncidentCategory.accident:
        return Icons.car_crash;
      case IncidentCategory.general:
        return Icons.help_outline;
    }
  }

  Widget _buildPrioritySelector() {
    return SegmentedButton<IncidentPriority>(
      segments: IncidentPriority.values.map((priority) {
        return ButtonSegment(
          value: priority,
          label: Text(_getPriorityLabel(priority)),
          icon: Icon(_getPriorityIcon(priority), size: 18),
        );
      }).toList(),
      selected: {_selectedPriority},
      onSelectionChanged: (selected) {
        setState(() => _selectedPriority = selected.first);
      },
    );
  }

  String _getPriorityLabel(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.low:
        return 'incidents.priority.low'.tr();
      case IncidentPriority.medium:
        return 'incidents.priority.medium'.tr();
      case IncidentPriority.high:
        return 'incidents.priority.high'.tr();
      case IncidentPriority.critical:
        return 'incidents.priority.critical'.tr();
    }
  }

  IconData _getPriorityIcon(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.low:
        return Icons.arrow_downward;
      case IncidentPriority.medium:
        return Icons.remove;
      case IncidentPriority.high:
        return Icons.arrow_upward;
      case IncidentPriority.critical:
        return Icons.priority_high;
    }
  }

  Widget _buildAnonymousToggle() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAnonymous
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAnonymous
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAnonymous ? Icons.visibility_off : Icons.visibility,
            color: _isAnonymous
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Anonymously',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Your identity will be hidden from the report',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (value) {
              setState(() => _isAnonymous = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    final theme = Theme.of(context);
    final pendingState = ref.watch(pendingAttachmentsProvider);
    final pendingNotifier = ref.read(pendingAttachmentsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('incidents.form.attachments'.tr()),
            Text(
              '${pendingState.fileCount}/${PendingAttachmentsNotifier.maxAttachments}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'incidents.form.attachmentsHint'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),

        // Attachment previews
        if (pendingState.hasFiles) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pendingState.fileCount,
              itemBuilder: (context, index) {
                final file = pendingState.pendingFiles[index];
                return _buildAttachmentPreview(file, index, pendingNotifier);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Add attachment button
        if (pendingNotifier.canAddMore)
          OutlinedButton.icon(
            onPressed: _showImagePickerOptions,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(pendingState.hasFiles
                ? 'incidents.form.addMorePhotos'.tr()
                : 'incidents.form.addPhotos'.tr()),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentPreview(
    File file,
    int index,
    PendingAttachmentsNotifier notifier,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => notifier.removeFileAt(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: theme.colorScheme.onError,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePickerOptions() async {
    final pendingNotifier = ref.read(pendingAttachmentsProvider.notifier);
    final remainingSlots = pendingNotifier.remainingSlots;

    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('incidents.form.maxAttachmentsReached'.tr()),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AttachmentPickerSheet(
        onCameraSelected: () async {
          Navigator.pop(context);
          final file = await ImagePickerHelper().pickFromCamera(
            options: ImagePickerOptions.incident,
          );
          if (file != null) {
            pendingNotifier.addFiles([file]);
          }
        },
        onGallerySelected: () async {
          Navigator.pop(context);
          final files = await ImagePickerHelper().pickMultipleImages(
            options: ImagePickerOptions.incident,
            limit: remainingSlots,
          );
          if (files.isNotEmpty) {
            pendingNotifier.addFiles(files);
          }
        },
      ),
    );
  }
}

/// Bottom sheet for picking attachments
class _AttachmentPickerSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;

  const _AttachmentPickerSheet({
    required this.onCameraSelected,
    required this.onGallerySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'incidents.form.addPhotos'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Divider(height: 1),

            // Camera option
            _buildOption(
              context: context,
              icon: Icons.camera_alt_outlined,
              label: 'profile.takePhoto'.tr(),
              onTap: onCameraSelected,
            ),

            // Gallery option
            _buildOption(
              context: context,
              icon: Icons.photo_library_outlined,
              label: 'profile.chooseFromGallery'.tr(),
              onTap: onGallerySelected,
            ),

            const SizedBox(height: 8),

            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('common.cancel'.tr()),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
