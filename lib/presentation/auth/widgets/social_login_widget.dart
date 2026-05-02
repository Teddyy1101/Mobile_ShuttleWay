import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Widget hiển thị phần "Hoặc đăng nhập bằng" với nút Google và FaceID.
class SocialLoginWidget extends StatelessWidget {
  final VoidCallback onGoogleTap;
  final VoidCallback onFacebookTap;

  const SocialLoginWidget({
    super.key,
    required this.onGoogleTap,
    required this.onFacebookTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ─── Divider text ─────────────────────────────
        Row(
          children: [
            Expanded(
              child: Divider(
                color: colorScheme.onSurface.withAlpha(51),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
              ),
              child: Text(
                'HOẶC ĐĂNG NHẬP BẰNG',
                style: TextStyle(
                  color: colorScheme.onSurface.withAlpha(153),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: colorScheme.onSurface.withAlpha(51),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingLG),

        // ─── Social Buttons ───────────────────────────
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: Icons.g_mobiledata,
                label: 'Google',
                onTap: onGoogleTap,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMD),
            Expanded(
              child: _SocialButton(
                icon: Icons.facebook,
                label: 'Facebook',
                onTap: onFacebookTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Button riêng cho từng social login provider.
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      child: Container(
        height: AppConstants.buttonHeight,
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.onSurface.withAlpha(51),
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.onSurface, size: 22),
            const SizedBox(width: AppConstants.paddingSM),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
