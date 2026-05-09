import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/profile_controller.dart';

/// Màn hình chỉnh sửa thông tin cá nhân.
/// Cho phép thay đổi: Họ tên, Số điện thoại, Ảnh đại diện.
class EditProfileScreen extends StatefulWidget {
  final ProfileController controller;

  const EditProfileScreen({super.key, required this.controller});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  /// File ảnh mới được chọn (chưa upload).
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.profile;
    _nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.95)
            : AppColors.lightBackground.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Chỉnh sửa thông tin',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.grey[800],
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.grey[800]!.withValues(alpha: 0.5)
                : Colors.grey[200]!.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLG),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // ── Avatar ──
                  _buildAvatarSection(theme, isDark),
                  const SizedBox(height: 32),

                  // ── Form Fields ──
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Họ và tên',
                    icon: Icons.person_outline_rounded,
                    theme: theme,
                    isDark: isDark,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Vui lòng nhập họ tên'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneCtrl,
                    label: 'Số điện thoại',
                    icon: Icons.phone_outlined,
                    theme: theme,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: TextEditingController(
                      text: widget.controller.profile?.email ?? '',
                    ),
                    label: 'Email',
                    icon: Icons.email_outlined,
                    theme: theme,
                    isDark: isDark,
                    enabled: false,
                  ),
                  const SizedBox(height: 32),

                  // ── Error message ──
                  if (widget.controller.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: isDark ? 0.15 : 0.08),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMD),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.controller.errorMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Social Links ──
                  _buildSocialLinks(theme, isDark),
                  const SizedBox(height: 32),

                  // ── Save button ──
                  _buildSaveButton(theme, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Avatar Section 

  Widget _buildAvatarSection(ThemeData theme, bool isDark) {
    final profile = widget.controller.profile;

    return Center(
      child: Stack(
        children: [
          // Avatar circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF1C252E) : Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null),
              child: _selectedImage == null && profile?.avatarUrl == null
                  ? Text(
                      profile?.fullName.isNotEmpty == true
                          ? profile!.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          ),

          // Upload overlay khi đang upload
          if (widget.controller.isUpdatingProfile)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Camera button
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourcePicker,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1C252E) : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Text Field 

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        color: enabled
            ? (isDark ? Colors.white : Colors.grey[900])
            : (isDark ? Colors.grey[500] : Colors.grey[400]),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: enabled
            ? (isDark
                ? Colors.grey[900]!.withValues(alpha: 0.3)
                : Colors.grey[50])
            : (isDark
                ? Colors.grey[900]!.withValues(alpha: 0.15)
                : Colors.grey[100]),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Social Links Section

  Widget _buildSocialLinks(ThemeData theme, bool isDark) {
    final profile = widget.controller.profile;
    if (profile == null) return const SizedBox.shrink();

    final hasGoogle = profile.googleId != null && profile.googleId!.isNotEmpty;
    final hasFacebook = profile.facebookId != null && profile.facebookId!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liên kết mạng xã hội',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900]!.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              _buildSocialTile(
                icon: Icons.g_mobiledata_rounded,
                iconColor: Colors.red[600]!,
                title: 'Google',
                isLinked: hasGoogle,
                onTap: hasGoogle ? null : () => widget.controller.linkWithGoogle(),
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              _buildSocialTile(
                icon: Icons.facebook_rounded,
                iconColor: Colors.blue[600]!,
                title: 'Facebook',
                isLinked: hasFacebook,
                onTap: hasFacebook ? null : () => widget.controller.linkWithFacebook(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isLinked,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 32),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: isLinked
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Đã liên kết', style: TextStyle(color: Colors.green, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.check_circle, color: Colors.green, size: 18),
              ],
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Liên kết', style: TextStyle(fontSize: 13)),
            ),
    );
  }

  // Save Button 

  Widget _buildSaveButton(ThemeData theme, bool isDark) {
    final isLoading = widget.controller.isUpdatingProfile;

    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [Colors.grey, Colors.grey]
                : [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }


  /// Hiển thị bottom sheet chọn nguồn ảnh (Thư viện / Camera).
  void _showImageSourcePicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1C252E) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chọn ảnh đại diện',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceOption(
                        theme: theme,
                        isDark: isDark,
                        icon: Icons.photo_library_outlined,
                        label: 'Thư viện',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSourceOption(
                        theme: theme,
                        isDark: isDark,
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Card chọn nguồn ảnh.
  Widget _buildSourceOption({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chọn ảnh từ gallery/camera.
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  /// Lưu thay đổi: gửi API cập nhật profile.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final currentProfile = widget.controller.profile;
    final newName = _nameCtrl.text.trim();
    final newPhone = _phoneCtrl.text.trim();

    // Chỉ gửi field thay đổi
    String? nameToSend;
    String? phoneToSend;
    if (newName != (currentProfile?.fullName ?? '')) nameToSend = newName;
    if (newPhone != (currentProfile?.phone ?? '')) phoneToSend = newPhone;

    // Nếu không có gì thay đổi
    if (nameToSend == null &&
        phoneToSend == null &&
        _selectedImage == null) {
      Navigator.pop(context);
      return;
    }

    final success = await widget.controller.updateProfile(
      fullName: nameToSend,
      phone: phoneToSend,
      avatarFilePath: _selectedImage?.path,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cập nhật thông tin thành công'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }
}
