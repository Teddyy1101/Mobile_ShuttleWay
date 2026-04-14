import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/support_controller.dart';

class SupportScreen extends StatefulWidget {
  final SupportController controller;
  final String userId;

  const SupportScreen({
    super.key,
    required this.controller,
    required this.userId,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedCategory;

  static const _categories = [
    _CategoryItem(
      key: 'LOST_ITEM',
      label: 'Quên/Mất đồ',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFF97316),
    ),
    _CategoryItem(
      key: 'COMPLAINT',
      label: 'Khiếu nại',
      icon: Icons.report_problem_outlined,
      color: Color(0xFFEF4444),
    ),
    _CategoryItem(
      key: 'PAYMENT_ISSUE',
      label: 'Lỗi thanh toán',
      icon: Icons.credit_card_off_outlined,
      color: Color(0xFF8B5CF6),
    ),
    _CategoryItem(
      key: 'GENERAL_INQUIRY',
      label: 'Hỏi đáp chung',
      icon: Icons.help_outline_rounded,
      color: Color(0xFF3B82F6),
    ),
  ];

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
                        _buildSectionTitle('Chọn danh mục', colorScheme),
                        const SizedBox(height: AppConstants.paddingSM),
                        _buildCategoryGrid(colorScheme, isDark),
                        const SizedBox(height: AppConstants.paddingLG),
                        _buildSectionTitle('Tiêu đề', colorScheme),
                        const SizedBox(height: AppConstants.paddingSM),
                        _buildTitleField(colorScheme, isDark),
                        const SizedBox(height: AppConstants.paddingLG),
                        _buildSectionTitle('Nội dung chi tiết', colorScheme),
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
                'Gửi yêu cầu hỗ trợ',
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
            colorScheme.primary.withValues(alpha: 0.12),
            colorScheme.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trung tâm hỗ trợ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chúng tôi sẽ phản hồi trong thời gian sớm nhất',
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

  Widget _buildCategoryGrid(ColorScheme colorScheme, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppConstants.paddingSM,
      crossAxisSpacing: AppConstants.paddingSM,
      childAspectRatio: 2.2,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat.key;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSM + 4,
              vertical: AppConstants.paddingSM,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.color.withValues(alpha: 0.12)
                  : isDark
                      ? AppColors.darkCard
                      : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(
                color: isSelected
                    ? cat.color.withValues(alpha: 0.5)
                    : isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withValues(alpha: 0.2)
                        : cat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(cat.icon, size: 20, color: cat.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? cat.color
                          : colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: cat.color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTitleField(ColorScheme colorScheme, bool isDark) {
    return TextFormField(
      controller: _titleController,
      style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'VD: Quên đồ trên xe buýt tuyến 01',
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
        hintText: 'Mô tả chi tiết vấn đề bạn gặp phải...',
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
    final canSubmit = _selectedCategory != null && !isSubmitting;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSubmit ? _handleSubmit : null,
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
        label: Text(isSubmitting ? 'Đang gửi...' : 'Gửi yêu cầu hỗ trợ'),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.4),
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
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục hỗ trợ'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final success = await widget.controller.submitTicket(
      userId: widget.userId,
      category: _selectedCategory!,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Gửi yêu cầu hỗ trợ thành công!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Gửi yêu cầu thất bại',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _CategoryItem {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}
