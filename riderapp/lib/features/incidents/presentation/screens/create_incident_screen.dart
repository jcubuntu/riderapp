import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    ref.listen<CreateIncidentState>(createIncidentProvider, (previous, next) {
      if (next is CreateIncidentSuccess) {
        // Update lists
        ref.read(myIncidentsListProvider.notifier).addIncidentToList(next.incident);
        if (!next.isUpdate) {
          ref.read(incidentsListProvider.notifier).addIncidentToList(next.incident);
        }

        // Show success message
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

        // Reset state
        ref.read(createIncidentProvider.notifier).reset();
      } else if (next is CreateIncidentError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.red,
          ),
        );
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
}
