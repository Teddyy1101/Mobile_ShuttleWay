import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Helper hiển thị toast notification ở góc trên màn hình.
/// Dùng chung cho toàn app, tránh hardcode SnackBar lặp lại.
class AppToast {
  AppToast._();

  /// Hiển thị toast thành công ở phía trên.
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, isError: false);
  }

  /// Hiển thị toast lỗi ở phía trên.
  static void showError(BuildContext context, String message) {
    _show(context, message, isError: true);
  }

  static void _show(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: colorScheme.onPrimary,
                size: AppConstants.iconSizeMD,
              ),
              const SizedBox(width: AppConstants.paddingSM),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:
              isError ? colorScheme.error : colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            top: AppConstants.paddingMD,
            left: AppConstants.paddingMD,
            right: AppConstants.paddingMD,
            bottom: AppConstants.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          duration: const Duration(seconds: 3),
          dismissDirection: DismissDirection.up,
        ),
      );
  }
}
