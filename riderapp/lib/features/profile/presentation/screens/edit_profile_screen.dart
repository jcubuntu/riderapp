import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/image_picker_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_state.dart';
import '../widgets/profile_avatar.dart';

/// Screen that allows users to edit their profile information.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _vehicleController;
  late TextEditingController _addressController;

  bool _isLoading = false;

  /// Selected local image file (before upload)
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _vehicleController = TextEditingController();
    _addressController = TextEditingController();

    // Initialize with current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFormData();
    });
  }

  void _initializeFormData() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone;
      _addressController.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final imageUploadState = ref.watch(imageUploadProvider);
    final imageRemovalState = ref.watch(imageRemovalProvider);

    // Determine if image operations are in progress
    final isUploadingImage = imageUploadState is ImageUploadInProgress;
    final isRemovingImage = imageRemovalState is ImageRemovalInProgress;
    final isImageOperationInProgress = isUploadingImage || isRemovingImage;

    // Get upload progress
    double? uploadProgress;
    if (imageUploadState is ImageUploadInProgress) {
      uploadProgress = imageUploadState.progress;
    }

    // Listen for profile state changes
    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (next is ProfileUpdateSuccess) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.updateSuccess'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else if (next is ProfileError) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (next is ProfileLoading) {
        setState(() => _isLoading = true);
      }
    });

    // Listen for image upload state changes
    ref.listen<ImageUploadState>(imageUploadProvider, (previous, next) {
      if (next is ImageUploadSuccess) {
        setState(() {
          _selectedImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.imageUploadSuccess'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        // Reset the upload state after success
        ref.read(imageUploadProvider.notifier).reset();
      } else if (next is ImageUploadError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
        // Reset the upload state after error
        ref.read(imageUploadProvider.notifier).reset();
      }
    });

    // Listen for image removal state changes
    ref.listen<ImageRemovalState>(imageRemovalProvider, (previous, next) {
      if (next is ImageRemovalSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.imageRemoveSuccess'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        // Reset the removal state after success
        ref.read(imageRemovalProvider.notifier).reset();
      } else if (next is ImageRemovalError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
        // Reset the removal state after error
        ref.read(imageRemovalProvider.notifier).reset();
      }
    });

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('profile.editProfile'.tr()),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('profile.editProfile'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Avatar with edit capability
              Center(
                child: ProfileAvatar(
                  imageUrl: user.profileImageUrl,
                  localImage: _selectedImage,
                  fullName: user.fullName,
                  size: 120,
                  borderColor: AppColors.primary,
                  borderWidth: 3,
                  editable: true,
                  isUploading: isImageOperationInProgress,
                  uploadProgress: uploadProgress,
                  onEditTap: isImageOperationInProgress
                      ? null
                      : () => _showImagePickerSheet(context, user.profileImageUrl),
                ),
              ),

              // Helper text for changing photo
              if (!isImageOperationInProgress)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'profile.tapToChangePhoto'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),

              const SizedBox(height: 32),

              // Full Name Field
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'auth.fullName'.tr(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.validation.fullNameRequired'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'auth.phoneNumber'.tr(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.validation.phoneRequired'.tr();
                  }
                  // Simple Thai phone number validation
                  final phoneRegex = RegExp(r'^0[0-9]{9}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'auth.validation.phoneInvalid'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field (optional)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'auth.email'.tr(),
                  prefixIcon: const Icon(Icons.email),
                  hintText: 'profile.emailOptional'.tr(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'auth.validation.emailInvalid'.tr();
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Vehicle Field (for riders)
              if (user.isRider) ...[
                TextFormField(
                  controller: _vehicleController,
                  decoration: InputDecoration(
                    labelText: 'profile.vehicle'.tr(),
                    prefixIcon: const Icon(Icons.two_wheeler),
                    hintText: 'profile.vehicleHint'.tr(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Address Field
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'auth.address'.tr(),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.location_on),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading || isImageOperationInProgress
                    ? null
                    : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('common.save'.tr()),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              OutlinedButton(
                onPressed: _isLoading || isImageOperationInProgress
                    ? null
                    : () => context.pop(),
                child: Text('common.cancel'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show the image picker bottom sheet.
  void _showImagePickerSheet(BuildContext context, String? currentImageUrl) {
    final hasExistingImage =
        currentImageUrl != null && currentImageUrl.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImagePickerSheet(
        showRemoveOption: hasExistingImage,
        onImageSelected: (image) {
          Navigator.of(context).pop();
          _handleImageSelected(image);
        },
        onRemoveSelected: () {
          Navigator.of(context).pop();
          _handleImageRemove();
        },
      ),
    );
  }

  /// Handle when a new image is selected.
  void _handleImageSelected(File imageFile) {
    setState(() {
      _selectedImage = imageFile;
    });

    // Start uploading the image immediately
    ref.read(imageUploadProvider.notifier).uploadProfileImage(imageFile);
  }

  /// Handle when user wants to remove their profile image.
  void _handleImageRemove() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.removePhotoTitle'.tr()),
        content: Text('profile.removePhotoConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(imageRemovalProvider.notifier).removeProfileImage();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: Text('common.remove'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref.read(profileProvider.notifier).updateProfile(
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          vehicle: _vehicleController.text.trim().isNotEmpty
              ? _vehicleController.text.trim()
              : null,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
        );
  }
}
