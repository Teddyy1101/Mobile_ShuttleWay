import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Widget hiển thị một bubble tin nhắn trong chatbot.
/// Phân biệt tin nhắn user (phải, primary) và AI (trái, surface).
class ChatBubbleWidget extends StatelessWidget {
  final String message;
  final bool isUser;
  final String time;

  const ChatBubbleWidget({
    super.key,
    required this.message,
    required this.isUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatarAI(colorScheme, isDark),
            const SizedBox(width: AppConstants.paddingSM),
          ],
          Flexible(child: _buildBubble(colorScheme, isDark)),
          if (isUser) const SizedBox(width: AppConstants.paddingSM),
        ],
      ),
    );
  }

  /// Avatar tròn cho AI (bên trái).
  Widget _buildAvatarAI(ColorScheme colorScheme, bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  /// Bubble tin nhắn với bo góc phù hợp.
  Widget _buildBubble(ColorScheme colorScheme, bool isDark) {
    final bgColor = isUser
        ? colorScheme.primary
        : isDark
            ? AppColors.darkCard
            : const Color(0xFFF0F2F5);

    final textColor = isUser
        ? Colors.white
        : colorScheme.onSurface;

    final timeColor = isUser
        ? Colors.white.withValues(alpha: 0.7)
        : colorScheme.onSurface.withValues(alpha: 0.4);

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: timeColor,
            ),
          ),
        ],
      ),
    );
  }
}
