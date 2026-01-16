import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../navigation/app_router.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';

/// Screen that displays the current user's profile information.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('profile.title'.tr()),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('profile.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, user),
            const SizedBox(height: 24),

            // Profile Info Card
            _buildProfileInfoCard(context, user),
            const SizedBox(height: 16),

            // Contact Info Card
            _buildContactInfoCard(context, user),
            const SizedBox(height: 16),

            // Vehicle Info Card (for riders)
            if (user.isRider) ...[
              _buildVehicleInfoCard(context, user),
              const SizedBox(height: 16),
            ],

            // Address Card
            _buildAddressCard(context, user),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    return Column(
      children: [
        ProfileAvatar(
          imageUrl: user.profileImageUrl,
          fullName: user.fullName,
          size: 100,
          borderColor: AppColors.primary,
          borderWidth: 3,
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(user.role).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getRoleColor(user.role),
              width: 1,
            ),
          ),
          child: Text(
            user.role.displayName,
            style: TextStyle(
              color: _getRoleColor(user.role),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfoCard(BuildContext context, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'profile.personalInfo'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.badge,
              label: 'auth.fullName'.tr(),
              value: user.fullName,
            ),
            if (user.idCardNumber != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.credit_card,
                label: 'auth.idCardNumber'.tr(),
                value: _maskIdCard(user.idCardNumber!),
              ),
            ],
            if (user.affiliation != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.business,
                label: 'auth.affiliation'.tr(),
                value: user.affiliation!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard(BuildContext context, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'profile.contactInfo'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.phone,
              label: 'auth.phoneNumber'.tr(),
              value: user.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard(BuildContext context, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.two_wheeler, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'profile.vehicleInfo'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.directions_bike,
              label: 'profile.vehicle'.tr(),
              value: 'profile.notSpecified'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'profile.addressInfo'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.home,
              label: 'auth.address'.tr(),
              value: user.address ?? 'profile.notSpecified'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => context.push(AppRoutes.editProfile),
          icon: const Icon(Icons.edit),
          label: Text('profile.editProfile'.tr()),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showChangePasswordDialog(context, ref),
          icon: const Icon(Icons.lock),
          label: Text('profile.changePassword'.tr()),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('profile.changePassword'.tr()),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'profile.currentPassword'.tr(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.validation.passwordRequired'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'profile.newPassword'.tr(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.validation.passwordRequired'.tr();
                  }
                  if (value.length < 8) {
                    return 'auth.validation.passwordTooShort'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'auth.confirmPassword'.tr(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'auth.validation.passwordMismatch'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop();
                try {
                  await ref.read(passwordChangeProvider.notifier).changePassword(
                        currentPassword: currentPasswordController.text,
                        newPassword: newPasswordController.text,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('profile.passwordChangeSuccess'.tr()),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.rider:
        return AppColors.info;
      case UserRole.volunteer:
        return AppColors.secondary;
      case UserRole.police:
        return AppColors.warning;
      case UserRole.commander:
        return AppColors.primary;
      case UserRole.admin:
        return AppColors.primary;
      case UserRole.superAdmin:
        return AppColors.error;
    }
  }

  String _maskIdCard(String idCard) {
    if (idCard.length < 6) return idCard;
    return '${idCard.substring(0, 3)}****${idCard.substring(idCard.length - 4)}';
  }
}
