import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class SocialRoleDialog extends StatefulWidget {
  final Function(String role, String phone) onSubmit;

  const SocialRoleDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<SocialRoleDialog> createState() => _SocialRoleDialogState();
}

class _SocialRoleDialogState extends State<SocialRoleDialog> {
  String _selectedRole = 'PARENT';
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_selectedRole, _phoneController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLG),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hoàn tất đăng ký',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingMD),
              Text(
                'Vui lòng cung cấp thêm thông tin để hoàn tất việc đăng ký tài khoản.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withAlpha(178),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingLG),
              Text(
                'Vai trò',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSM),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleCard(
                      context: context,
                      title: 'Phụ huynh',
                      icon: Icons.family_restroom,
                      role: 'PARENT',
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMD),
                  Expanded(
                    child: _buildRoleCard(
                      context: context,
                      title: 'Học sinh',
                      icon: Icons.school,
                      role: 'STUDENT',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMD),
              Text(
                'Số điện thoại',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSM),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (value.trim().length < 10) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingLG),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String role,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withAlpha(25) : Colors.transparent,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface.withAlpha(50),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withAlpha(150),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
