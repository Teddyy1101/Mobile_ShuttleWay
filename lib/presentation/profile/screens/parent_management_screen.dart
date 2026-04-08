import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child_model.dart';
import '../controllers/profile_controller.dart';

/// Màn hình Quản lý phụ huynh dành cho học sinh.
/// Hiển thị danh sách phụ huynh đã liên kết + FAB để liên kết thêm qua SĐT.
class ParentManagementScreen extends StatefulWidget {
  final ProfileController controller;

  const ParentManagementScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ParentManagementScreen> createState() =>
      _ParentManagementScreenState();
}

class _ParentManagementScreenState extends State<ParentManagementScreen> {
  final _phoneController = TextEditingController();
  bool _isLinking = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C252E) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Quản lý phụ huynh',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading &&
              widget.controller.linkedUsers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody(context, theme, isDark);
        },
      ),
      floatingActionButton: _buildFab(theme),
    );
  }

  /// FAB dấu cộng ở góc phải dưới.
  Widget _buildFab(ThemeData theme) {
    return FloatingActionButton(
      onPressed: () => _showLinkBottomSheet(context),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, bool isDark) {
    final parents = widget.controller.linkedUsers;
    final cardColor = isDark ? const Color(0xFF1C252E) : Colors.white;

    if (parents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom_outlined,
              size: 48,
              color: isDark ? Colors.grey[500] : Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa liên kết phụ huynh nào',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút + để liên kết phụ huynh',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh sách phụ huynh',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C252E) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${parents.length} phụ huynh',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Parent list
          ...parents.map((parent) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildParentCard(
                    context, parent, theme, isDark, cardColor),
              )),
          // Padding dưới cùng tránh FAB che card cuối
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Widget _buildParentCard(
    BuildContext context,
    ChildModel parent,
    ThemeData theme,
    bool isDark,
    Color cardColor,
  ) {
    return GestureDetector(
      onTap: () => _showParentDetail(context, parent),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                ),
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor:
                    isDark ? AppColors.darkSurface : AppColors.lightSurface,
                backgroundImage: parent.avatarUrl != null
                    ? NetworkImage(parent.avatarUrl!)
                    : null,
                child: parent.avatarUrl == null
                    ? Text(
                        parent.fullName.isNotEmpty
                            ? parent.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parent.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parent.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status + Chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: parent.isActive
                        ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    parent.isActive ? 'Hoạt động' : 'Ngừng',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: parent.isActive
                          ? const Color(0xFF22C55E)
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Link parent bottom sheet ────────────────────────────

  void _showLinkBottomSheet(BuildContext context) {
    _phoneController.clear();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C252E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_outlined,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      'Liên kết phụ huynh',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nhập số điện thoại của phụ huynh để liên kết',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Phone input
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: +84987654321',
                        hintStyle: TextStyle(
                          color:
                              isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color:
                              isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF141A22)
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Link button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLinking
                            ? null
                            : () => _handleLink(ctx, setSheetState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLinking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Liên kết',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Xử lý liên kết: validate → gọi controller → feedback.
  Future<void> _handleLink(
    BuildContext ctx,
    void Function(void Function()) setSheetState,
  ) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar(ctx, 'Vui lòng nhập số điện thoại', isError: true);
      return;
    }

    setSheetState(() => _isLinking = true);

    final success = await widget.controller.linkByPhone(phone);
    final errorMsg = widget.controller.errorMessage;

    setSheetState(() => _isLinking = false);

    if (!ctx.mounted) return;

    // Đóng bottom sheet trước khi hiện thông báo
    Navigator.pop(ctx);

    // Đợi bottom sheet đóng xong rồi mới hiện SnackBar trên context chính
    if (!mounted) return;
    if (success) {
      _showSnackBar(context, 'Liên kết phụ huynh thành công');
    } else {
      _showSnackBar(
        context,
        errorMsg ?? 'Liên kết thất bại',
        isError: true,
      );
      widget.controller.clearError();
    }
  }

  void _showSnackBar(BuildContext ctx, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // ─── Parent detail bottom sheet ─────────────────────────

  void _showParentDetail(BuildContext context, ChildModel parent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C252E) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 37,
                    backgroundColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    backgroundImage: parent.avatarUrl != null
                        ? NetworkImage(parent.avatarUrl!)
                        : null,
                    child: parent.avatarUrl == null
                        ? Text(
                            parent.fullName.isNotEmpty
                                ? parent.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  parent.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: parent.isActive
                        ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    parent.isActive ? 'Đang hoạt động' : 'Ngừng hoạt động',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: parent.isActive
                          ? const Color(0xFF22C55E)
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Detail rows
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: parent.email,
                ),
                _buildDetailRow(
                  isDark: isDark,
                  icon: Icons.phone_outlined,
                  label: 'Số điện thoại',
                  value: parent.phone ?? 'Chưa cập nhật',
                  isLast: true,
                ),
                const SizedBox(height: 24),
                // Unlink button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmUnlink(ctx, parent),
                    icon: const Icon(Icons.link_off, size: 20),
                    label: const Text(
                      'Hủy liên kết',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hiện dialog xác nhận hủy liên kết.
  void _confirmUnlink(BuildContext sheetCtx, ChildModel parent) {
    showDialog(
      context: sheetCtx,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Xác nhận hủy liên kết'),
          content: Text(
            'Bạn có chắc chắn muốn hủy liên kết với phụ huynh ${parent.fullName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx); // đóng dialog
                _handleUnlink(sheetCtx, parent);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  /// Xử lý hủy liên kết: gọi controller → đóng sheet → feedback.
  Future<void> _handleUnlink(BuildContext sheetCtx, ChildModel parent) async {
    final success = await widget.controller.unlinkUser(parent.id);
    final errorMsg = widget.controller.errorMessage;

    if (!sheetCtx.mounted) return;

    // Đóng bottom sheet trước
    Navigator.pop(sheetCtx);

    if (!mounted) return;
    if (success) {
      _showSnackBar(context, 'Đã hủy liên kết với ${parent.fullName}');
    } else {
      _showSnackBar(
        context,
        errorMsg ?? 'Hủy liên kết thất bại',
        isError: true,
      );
      widget.controller.clearError();
    }
  }

  Widget _buildDetailRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[900],
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark
                ? Colors.grey[800]!.withValues(alpha: 0.5)
                : Colors.grey[200],
          ),
      ],
    );
  }
}
