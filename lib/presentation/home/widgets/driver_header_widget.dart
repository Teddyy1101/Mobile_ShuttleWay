import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/login_response.dart';
import '../../notification/controllers/notification_controller.dart';

class DriverHeaderWidget extends StatelessWidget {
  final UserModel? profile;
  final String greeting;
  final NotificationController notificationController;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationTap;

  const DriverHeaderWidget({
    super.key,
    required this.profile,
    required this.greeting,
    required this.notificationController,
    required this.onAvatarTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // ─── Avatar ───
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.success, colorScheme.primary],
              ),
            ),
            child: CircleAvatar(
              radius: AppConstants.avatarSizeSM / 2,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              backgroundImage: profile?.avatarUrl != null
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: profile?.avatarUrl == null
                  ? Text(
                      profile?.fullName.isNotEmpty == true
                          ? profile!.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.paddingSM),
        // ─── Greeting + Name ───
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile?.fullName ?? 'Tài xế',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        // ─── Notification Bell ───
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
              ),
              child: IconButton(
                onPressed: onNotificationTap,
                icon: Icon(
                  Icons.notifications_none_rounded,
                  size: AppConstants.iconSizeSM,
                  color: colorScheme.onSurface,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            Positioned(
              top: 8,
              right: 10,
              child: ListenableBuilder(
                listenable: notificationController,
                builder: (context, _) {
                  if (notificationController.unreadCount == 0) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        width: 1.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
