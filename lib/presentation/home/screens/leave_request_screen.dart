import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/leave_request_controller.dart';

class LeaveRequestScreen extends StatefulWidget {
  final ProfileController profileController;
  final LeaveRequestController leaveRequestController;

  const LeaveRequestScreen({
    super.key,
    required this.profileController,
    required this.leaveRequestController,
  });

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  ChildModel? _selectedChild;
  DateTime? _fromDate;
  DateTime? _toDate;

  bool get _isParent => widget.profileController.isParent;
  List<ChildModel> get _children => widget.profileController.linkedUsers;

  @override
  void initState() {
    super.initState();
    if (_isParent && _children.isNotEmpty) {
      _selectedChild = _children.first;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime initialDate = isFromDate
        ? (_fromDate ?? DateTime.now())
        : (_toDate ?? _fromDate ?? DateTime.now());
    
    final DateTime firstDate = isFromDate 
        ? DateTime.now() 
        : (_fromDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              // For dark mode compatibility
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
          // Reset toDate if it's before fromDate
          if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
            _toDate = null;
          }
        } else {
          _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ thời gian bắt đầu và kết thúc')),
      );
      return;
    }

    final parentId = widget.profileController.profile!.id;
    final studentId = _isParent ? _selectedChild?.id : parentId;

    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin học sinh')),
      );
      return;
    }

    final success = await widget.leaveRequestController.createLeaveRequest(
      context: context,
      studentId: studentId,
      parentId: parentId, // If student role, we can pass studentId as parentId since backend may handle it (or requires parentId). Usually student request uses their own ID but DTO requires parentId. For now passing parentId.
      fromDate: _fromDate!.toIso8601String(),
      toDate: _toDate!.toIso8601String(),
      reason: _reasonController.text,
    );

    if (success && mounted) {
      Navigator.pop(context); // Go back to calendar tab
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Đăng ký nghỉ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
              icon: Icon(Icons.close, color: colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: _isParent && _children.isEmpty
          ? _buildNoChildLinkedBody(theme, isDark, colorScheme)
          : ListenableBuilder(
        listenable: widget.leaveRequestController,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isParent) ...[
                    // Chọn học sinh
                    Text(
                      'Học sinh',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSM),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ChildModel>(
                          value: _selectedChild,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
                          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                          icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
                          items: _children.map((child) {
                            return DropdownMenuItem(
                              value: child,
                              child: Text(
                                child.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedChild = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLG),
                  ],

                  // Chọn thời gian
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateSelector(
                          context, 
                          isDark, 
                          colorScheme, 
                          label: 'Từ ngày',
                          date: _fromDate,
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMD),
                      Expanded(
                        child: _buildDateSelector(
                          context, 
                          isDark, 
                          colorScheme, 
                          label: 'Đến ngày',
                          date: _toDate,
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingLG),

                  // Lý do
                  Text(
                    'Lý do xin nghỉ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSM),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do xin nghỉ (Tùy chọn)',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
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
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.paddingXXL),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: AppConstants.buttonHeight,
                    child: ElevatedButton(
                      onPressed: widget.leaveRequestController.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                        ),
                      ),
                      child: widget.leaveRequestController.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Gửi đăng ký',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context, 
    bool isDark, 
    ColorScheme colorScheme, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: AppConstants.paddingSM),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined, 
                  size: 18, 
                  color: date != null ? colorScheme.primary : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Chọn ngày',
                    style: TextStyle(
                      color: date != null 
                          ? colorScheme.onSurface 
                          : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                      fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoChildLinkedBody(ThemeData theme, bool isDark, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard
                    : Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_disabled_rounded,
                size: 40,
                color: isDark ? Colors.orange[300] : Colors.orange[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa liên kết học sinh',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn cần liên kết tài khoản học sinh trong mục Cá nhân trước khi đăng ký xin nghỉ.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Quay lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
