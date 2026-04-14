import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/support_controller.dart';

/// Màn hình gửi báo cáo sự cố dành cho tài xế.
/// Mặc định category = COMPLAINT (báo cáo xe hỏng, sự cố kỹ thuật...).
class DriverSupportScreen extends StatefulWidget {
  final SupportController controller;
  final String userId;

  const DriverSupportScreen({
    super.key,
    required this.controller,
    required this.userId,
  });

  @override
  State<DriverSupportScreen> createState() => _DriverSupportScreenState();
}

class _DriverSupportScreenState extends State<DriverSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          _buildAppBar(theme, isDark),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppConstants.paddingMD),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoBanner(colorScheme, isDark),
                        const SizedBox(height: AppConstants.paddingLG),
                        _buildSectionTitle('Tiêu đề sự cố', colorScheme),
                        const SizedBox(height: AppConstants.paddingSM),
                        _buildTitleField(colorScheme, isDark),
                        const SizedBox(height: AppConstants.paddingLG),
                        _buildSectionTitle('Mô tả chi tiết', colorScheme),
                        const SizedBox(height: AppConstants.paddingSM),
                        _buildContentField(colorScheme, isDark),
                        const SizedBox(height: AppConstants.paddingXL),
                        _buildSubmitButton(colorScheme),
                        const SizedBox(height: AppConstants.paddingLG),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDark) {
    final bgColor = theme.scaffoldBackgroundColor;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXS,
          vertical: AppConstants.paddingSM,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: const CircleBorder(),
              ),
            ),
            Expanded(
              child: Text(
                'Báo cáo sự cố',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppConstants.avatarSizeMD),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.12),
            AppColors.warning.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Báo cáo sự cố xe',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Xe hỏng, sự cố kỹ thuật, tai nạn...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTitleField(ColorScheme colorScheme, bool isDark) {
    return TextFormField(
      controller: _titleController,
      style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'VD: Xe bị hỏng điều hòa tuyến 01',
        hintStyle: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: 14,
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tiêu đề';
        return null;
      },
    );
  }

  Widget _buildContentField(ColorScheme colorScheme, bool isDark) {
    return TextFormField(
      controller: _contentController,
      maxLines: 5,
      style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Mô tả chi tiết sự cố bạn gặp phải...',
        hintStyle: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.paddingMD),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập nội dung';
        return null;
      },
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    final isSubmitting = widget.controller.isSubmitting;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : _handleSubmit,
        icon: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(isSubmitting ? 'Đang gửi...' : 'Gửi báo cáo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.warning.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.controller.submitTicket(
      userId: widget.userId,
      category: 'COMPLAINT',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Gửi báo cáo sự cố thành công!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Gửi báo cáo thất bại',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
