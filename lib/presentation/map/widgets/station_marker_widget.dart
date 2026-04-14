import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Trạng thái của trạm trên tuyến.
enum StationState { passed, current, upcoming }

/// Widget marker trạm dừng trên bản đồ — hình tròn có STT, kèm tên trạm.
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
    final Color circleColor;
    final Color borderColor;
    final Color labelBgColor;
    final Color labelTextColor;
    final Widget centerContent;

    switch (state) {
      case StationState.passed:
        circleColor = AppColors.success;
        borderColor = Colors.white;
        labelBgColor = AppColors.success.withValues(alpha: 0.15);
        labelTextColor = AppColors.success;
        centerContent = const Icon(
          Icons.check,
          color: Colors.white,
          size: 14,
        );
        break;
      case StationState.current:
        circleColor = const Color(0xFF4285F4);
        borderColor = Colors.white;
        labelBgColor = const Color(0xFF4285F4).withValues(alpha: 0.15);
        labelTextColor = const Color(0xFF4285F4);
        centerContent = Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        );
        break;
      case StationState.upcoming:
        circleColor = const Color(0xFFEA4335);
        borderColor = Colors.white;
        labelBgColor = const Color(0xFFEA4335).withValues(alpha: 0.12);
        labelTextColor = const Color(0xFFEA4335);
        centerContent = Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        );
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vòng tròn marker
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: circleColor.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: centerContent),
        ),
        const SizedBox(height: 3),
        // Tên trạm chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: labelBgColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 2,
              ),
            ],
          ),
          child: Text(
            name.length > 14 ? '${name.substring(0, 14)}…' : name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: state == StationState.current
                  ? FontWeight.w700
                  : FontWeight.w600,
              color: labelTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
