import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/providers/affiliations_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedAffiliation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Load affiliations when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(affiliationsProvider.notifier).loadAffiliations();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _idCardController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).register(
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            idCardNumber: _idCardController.text.trim(),
            affiliation: _selectedAffiliation ?? '',
            address: _addressController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final affiliationsState = ref.watch(affiliationsProvider);
    final affiliationNames = ref.watch(affiliationNamesProvider);

    // Show error snackbar if there's an error
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'auth.register'.tr(),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'auth.fullName'.tr(),
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.validation.fullNameRequired'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ID Card Number
                TextFormField(
                  controller: _idCardController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  maxLength: 13,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'auth.idCardNumber'.tr(),
                    prefixIcon: const Icon(Icons.credit_card_outlined),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.validation.idCardRequired'.tr();
                    }
                    if (value.length != 13) {
                      return 'auth.validation.idCardInvalid'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'auth.phoneNumber'.tr(),
                    prefixIcon: const Icon(Icons.phone_outlined),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.validation.phoneRequired'.tr();
                    }
                    if (value.length < 9 || value.length > 10) {
                      return 'auth.validation.phoneInvalid'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Affiliation dropdown
                _buildAffiliationDropdown(
                  affiliationsState,
                  affiliationNames,
                  isLoading,
                ),

                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'auth.address'.tr(),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.location_on_outlined),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.validation.addressRequired'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'auth.password'.tr(),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: InputDecoration(
                    labelText: 'auth.confirmPassword'.tr(),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.validation.passwordRequired'.tr();
                    }
                    if (value != _passwordController.text) {
                      return 'auth.validation.passwordMismatch'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Register button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'auth.registerButton'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'auth.pendingApproval.message'.tr(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.info,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAffiliationDropdown(
    AffiliationsState affiliationsState,
    List<String> affiliationNames,
    bool isLoading,
  ) {
    // Show loading indicator while fetching affiliations
    if (affiliationsState is AffiliationsLoading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'auth.affiliation'.tr(),
          prefixIcon: const Icon(Icons.business_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('กำลังโหลดสังกัด...'),
          ],
        ),
      );
    }

    // Show error with retry button
    if (affiliationsState is AffiliationsError) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: 'auth.affiliation'.tr(),
          prefixIcon: const Icon(Icons.business_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          errorText: affiliationsState.message,
        ),
        child: Row(
          children: [
            const Text('โหลดสังกัดไม่สำเร็จ'),
            const Spacer(),
            TextButton(
              onPressed: () {
                ref.read(affiliationsProvider.notifier).retry();
              },
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      );
    }

    // Show dropdown when loaded
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'auth.affiliation'.tr(),
        prefixIcon: const Icon(Icons.business_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: affiliationNames.map((affiliation) {
        return DropdownMenuItem(
          value: affiliation,
          child: Text(affiliation),
        );
      }).toList(),
      onChanged: isLoading
          ? null
          : (value) {
              setState(() {
                _selectedAffiliation = value;
              });
            },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'auth.validation.affiliationRequired'.tr();
        }
        return null;
      },
    );
  }
}
