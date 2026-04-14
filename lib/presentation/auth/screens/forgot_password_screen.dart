import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_toast.dart';
import '../controllers/auth_controller.dart';

/// Màn hình Quên mật khẩu — nhập email để nhận mật khẩu mới.
class ForgotPasswordScreen extends StatefulWidget {
  final AuthController authController;

  const ForgotPasswordScreen({
    super.key,
    required this.authController,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.authController.forgotPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() => _emailSent = true);
    } else {
      final error = widget.authController.errorMessage;
      if (error != null) {
        AppToast.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quên mật khẩu',
          style: TextStyle(color: colorScheme.onSurface),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.authController,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLG),
            child: _emailSent ? _buildSuccessView(colorScheme, isDark) : _buildFormView(colorScheme, isDark),
          );
        },
      ),
    );
  }

  /// Giao diện nhập email.
  Widget _buildFormView(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.paddingXL),

        // Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingXL),

        // Tiêu đề
        Center(
          child: Text(
            'Khôi phục mật khẩu',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingSM),
        Center(
          child: Text(
            'Nhập email đã đăng ký tài khoản.\nMật khẩu mới sẽ được gửi đến email của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withAlpha(153),
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingXL),

        // Form
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSM),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Nhập email của bạn',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: colorScheme.onSurface.withAlpha(128),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.paddingXL),

              // Nút gửi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.authController.isLoading ? null : _handleSubmit,
                  child: widget.authController.isLoading
                      ? SizedBox(
                          width: AppConstants.iconSizeMD,
                          height: AppConstants.iconSizeMD,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Gửi mật khẩu mới'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Giao diện thành công — email đã gửi.
  Widget _buildSuccessView(ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 60),

        // Icon thành công
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 50,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: AppConstants.paddingXL),

        Text(
          'Email đã được gửi!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMD),

        Text(
          'Mật khẩu mới đã được gửi đến\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withAlpha(153),
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMD),

        // Thông báo lưu ý
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1C252E)
                : const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFFC107).withAlpha(51)
                  : const Color(0xFFFFC107).withAlpha(77),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFFA000), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hãy đổi mật khẩu ngay sau khi đăng nhập để bảo mật tài khoản.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFFFFC107) : const Color(0xFF856404),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.paddingXL),

        // Nút quay lại đăng nhập
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Quay lại đăng nhập'),
          ),
        ),
      ],
    );
  }
}
