import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Widget chứa form đăng ký (5 trường: họ tên, email, SĐT, mật khẩu, xác nhận).
/// Tách ra khỏi screen để tuân thủ quy tắc < 150 dòng / file.
class RegisterFormWidget extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final GlobalKey<FormState> formKey;

  const RegisterFormWidget({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Họ và tên ────────────────────────────────
          _buildLabel('Họ và tên', colorScheme),
          const SizedBox(height: AppConstants.paddingSM),
          TextFormField(
            controller: fullNameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Nhập họ và tên',
              prefixIcon: Icon(
                Icons.person_outline,
                color: colorScheme.onSurface.withAlpha(128),
              ),
            ),
            validator: _validateFullName,
          ),
          const SizedBox(height: AppConstants.paddingSM),

          // ─── Email ────────────────────────────────────
          _buildLabel('Email', colorScheme),
          const SizedBox(height: AppConstants.paddingSM),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Nhập email',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: colorScheme.onSurface.withAlpha(128),
              ),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: AppConstants.paddingSM),

          // ─── Số điện thoại ─────────────────────────────
          _buildLabel('Số điện thoại', colorScheme),
          const SizedBox(height: AppConstants.paddingSM),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Nhập số điện thoại',
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: colorScheme.onSurface.withAlpha(128),
              ),
            ),
            validator: _validatePhone,
          ),
          const SizedBox(height: AppConstants.paddingSM),

          // ─── Mật khẩu ────────────────────────────────
          _buildLabel('Mật khẩu', colorScheme),
          const SizedBox(height: AppConstants.paddingSM),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: colorScheme.onSurface.withAlpha(128),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colorScheme.onSurface.withAlpha(128),
                ),
                onPressed: onTogglePassword,
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: AppConstants.paddingMD),

          // ─── Xác nhận mật khẩu ───────────────────────
          _buildLabel('Xác nhận mật khẩu', colorScheme),
          const SizedBox(height: AppConstants.paddingSM),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Nhập lại mật khẩu',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: colorScheme.onSurface.withAlpha(128),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colorScheme.onSurface.withAlpha(128),
                ),
                onPressed: onToggleConfirmPassword,
              ),
            ),
            validator: (value) => _validateConfirmPassword(
              value,
              passwordController.text,
            ),
          ),
        ],
      ),
    );
  }

  /// Label chung cho các trường input.
  Widget _buildLabel(String text, ColorScheme colorScheme) {
    return Text(
      text,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ─── Validators ────────────────────────────────────────

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final phoneRegex = RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.trim().length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value.trim() != password.trim()) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }
}
