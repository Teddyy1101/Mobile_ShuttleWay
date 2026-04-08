import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child_model.dart';

/// Card hiển thị thông tin học sinh liên kết.
/// Hỗ trợ carousel ngang khi có nhiều con.
/// Nếu chưa liên kết, hiện UI nhập SĐT để liên kết.
class StudentCardWidget extends StatefulWidget {
  final List<ChildModel> children;
  final bool isLoading;
  final String? errorMessage;
  final Future<bool> Function(String phone) onLinkStudent;

  const StudentCardWidget({
    super.key,
    required this.children,
    required this.isLoading,
    this.errorMessage,
    required this.onLinkStudent,
  });

  @override
  State<StudentCardWidget> createState() => _StudentCardWidgetState();
}

class _StudentCardWidgetState extends State<StudentCardWidget> {
  final _phoneController = TextEditingController();
  bool _isLinking = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return _buildLinkStudentCard(context);
    }
    return _buildCarousel(context);
  }

  /// Carousel ngang hiển thị danh sách các con — theo design HTML.
  Widget _buildCarousel(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: widget.children.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppConstants.paddingMD),
        itemBuilder: (context, index) {
          final child = widget.children[index];
          // Card đầu tiên dùng style active (primary), các card sau dùng inactive
          if (index == 0) {
            return _buildActiveCard(context, child);
          }
          return _buildInactiveCard(context, child);
        },
      ),
    );
  }

  /// Card active: nền primary, text trắng, badge ping "Trực tuyến", bus status.
  Widget _buildActiveCard(BuildContext context, ChildModel child) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Top: Avatar + Name + Badge ───
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x4DFFFFFF), // white 30%
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: AppConstants.avatarSizeMD / 2,
                  backgroundColor:
                      colorScheme.primary.withValues(alpha: 0.3),
                  backgroundImage: child.avatarUrl != null
                      ? NetworkImage(child.avatarUrl!)
                      : null,
                  child: child.avatarUrl == null
                      ? Text(
                          child.fullName.isNotEmpty
                              ? child.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFFFFF),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppConstants.paddingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFFFFF),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Học sinh',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge Trực tuyến với ping animation
              _buildOnlineBadge(),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSM),
          // ─── Divider ───
          Divider(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
            height: 1,
          ),
          const SizedBox(height: AppConstants.paddingSM),
          // ─── Bus status ───
          Row(
            children: [
              const Icon(
                Icons.directions_bus_rounded,
                size: 20,
                color: Color(0xFFFFFFFF),
              ),
              const SizedBox(width: AppConstants.paddingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đang trên xe đến trường',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Biển số: 29B-123.45 • Tài xế Hùng',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Badge "Trực tuyến" với ping animation (chấm xanh nhấp nháy).
  Widget _buildOnlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSM,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ping dot — dùng simple green dot
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.paddingXS),
          const Text(
            'Trực tuyến',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  /// Card inactive: nền card, border, badge "Đã đến nơi", check icon xanh.
  Widget _buildInactiveCard(BuildContext context, ChildModel child) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Top: Avatar + Name + Badge ───
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: AppConstants.avatarSizeMD / 2,
                  backgroundColor:
                      colorScheme.primary.withValues(alpha: 0.15),
                  backgroundImage: child.avatarUrl != null
                      ? NetworkImage(child.avatarUrl!)
                      : null,
                  child: child.avatarUrl == null
                      ? Text(
                          child.fullName.isNotEmpty
                              ? child.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppConstants.paddingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Học sinh',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Badge "Đã đến nơi"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingSM,
                  vertical: AppConstants.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
                child: Text(
                  'Đã đến nơi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSM),
          // ─── Divider ───
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),
          const SizedBox(height: AppConstants.paddingSM),
          // ─── Status ───
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.success,
              ),
              const SizedBox(width: AppConstants.paddingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã đến trường',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lúc 07:15 sáng nay',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card liên kết học sinh (khi chưa có HS nào).
  Widget _buildLinkStudentCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppConstants.paddingSM),
          Text(
            'Chưa liên kết học sinh',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            'Nhập số điện thoại học sinh để liên kết',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMD),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Nhập số điện thoại...',
                    prefixIcon: Icon(
                      Icons.phone_rounded,
                      color: colorScheme.primary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingSM,
                      vertical: AppConstants.paddingSM,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSM),
              SizedBox(
                height: AppConstants.inputHeight,
                child: ElevatedButton(
                  onPressed: _isLinking ? null : _handleLink,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, AppConstants.buttonHeight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMD,
                    ),
                  ),
                  child: _isLinking
                      ? const SizedBox(
                          width: AppConstants.iconSizeSM,
                          height: AppConstants.iconSizeSM,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Liên kết'),
                ),
              ),
            ],
          ),
          if (widget.errorMessage != null) ...[
            const SizedBox(height: AppConstants.paddingSM),
            Text(
              widget.errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleLink() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLinking = true);
    final success = await widget.onLinkStudent(phone);
    if (mounted) {
      setState(() => _isLinking = false);
      if (success) {
        _phoneController.clear();
      }
    }
  }
}
