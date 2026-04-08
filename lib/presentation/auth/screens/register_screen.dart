import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_toast.dart';
import '../controllers/auth_controller.dart';
import '../widgets/register_form_widget.dart';
import '../widgets/role_selector_widget.dart';

/// Màn hình đăng ký tài khoản của ứng dụng SafeWheels.
/// Giao diện đồng nhất với [LoginScreen].
class RegisterScreen extends StatefulWidget {
  final AuthController authController;

  const RegisterScreen({super.key, required this.authController});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'PARENT';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePassword() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _toggleConfirmPassword() {
    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
  }

  void _onRoleChanged(String role) {
    setState(() => _selectedRole = role);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.authController.register(
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _passwordController.text.trim(),
      _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      AppToast.showSuccess(context, 'Đăng ký thành công!');
      Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Đăng ký',
          style: TextStyle(color: colorScheme.onSurface),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.authController,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLG,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppConstants.paddingSM),
                _buildLogo(colorScheme),
                const SizedBox(height: AppConstants.paddingMD),
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: RoleSelectorWidget(
                    selectedRole: _selectedRole,
                    onRoleChanged: _onRoleChanged,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSM),
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: RegisterFormWidget(
                    fullNameController: _fullNameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    obscurePassword: _obscurePassword,
                    obscureConfirmPassword: _obscureConfirmPassword,
                    onTogglePassword: _togglePassword,
                    onToggleConfirmPassword: _toggleConfirmPassword,
                    formKey: _formKey,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMD),
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: _buildRegisterButton(colorScheme),
                ),
                const SizedBox(height: AppConstants.paddingMD),
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: _buildLoginLink(colorScheme),
                ),
                const SizedBox(height: AppConstants.paddingMD),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Logo (đồng nhất với LoginScreen).
  Widget _buildLogo(ColorScheme colorScheme) {
    return Transform.translate(
      offset: const Offset(-30, -10),
      child: Image.asset(
        AppConstants.logoPath,
        width: AppConstants.logoSizeLG * 1.5,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Nút Đăng ký.
  Widget _buildRegisterButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            widget.authController.isLoading ? null : _handleRegister,
        child: widget.authController.isLoading
            ? SizedBox(
                width: AppConstants.iconSizeMD,
                height: AppConstants.iconSizeMD,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onPrimary,
                ),
              )
            : const Text('Đăng ký'),
      ),
    );
  }

  /// Link "Đã có tài khoản? Đăng nhập".
  Widget _buildLoginLink(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: TextStyle(
            color: colorScheme.onSurface.withAlpha(153),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Đăng nhập',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
