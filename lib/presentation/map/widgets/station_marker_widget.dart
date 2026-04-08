import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Trạng thái của trạm trên tuyến.
enum StationState { passed, current, upcoming }

/// Widget marker trạm dừng trên bản đồ.
/// Hiển thị icon + tên trạm dưới dạng chip nhỏ.
class StationMarkerWidget extends StatelessWidget {
  final String name;
  final int index;
  final StationState state;

  const StationMarkerWidget({
    super.key,
    required this.name,
    required this.index,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color dotColor;
    final Color bgColor;
    final Color textColor;
    final double dotSize;

    switch (state) {
      case StationState.passed:
        dotColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.success;
        dotSize = 10;
        break;
      case StationState.current:
        dotColor = colorScheme.primary;
        bgColor = colorScheme.primary.withValues(alpha: 0.15);
        textColor = colorScheme.primary;
        dotSize = 14;
        break;
      case StationState.upcoming:
        dotColor = isDark ? Colors.grey[500]! : Colors.grey[400]!;
        bgColor = isDark
            ? Colors.grey[800]!.withValues(alpha: 0.6)
            : Colors.grey[200]!.withValues(alpha: 0.8);
        textColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        dotSize = 8;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dot marker
        Container(
          width: dotSize + 8,
          height: dotSize + 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: state == StationState.current
                ? Border.all(color: dotColor, width: 2)
                : null,
          ),
          child: Center(
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: state == StationState.current
                    ? [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Station name chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            name.length > 12 ? '${name.substring(0, 12)}…' : name,
            style: TextStyle(
              fontSize: 8,
              fontWeight:
                  state == StationState.current ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
