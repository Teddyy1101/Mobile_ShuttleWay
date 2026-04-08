import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Widget bản đồ OSM hiển thị vị trí xe buýt.
/// Next-stop info overlay nằm trong map container theo design.
class BusMapWidget extends StatelessWidget {
  /// Callback khi bấm "Mở rộng" — chuyển sang tab Bản đồ.
  final VoidCallback? onExpandMap;

  const BusMapWidget({super.key, this.onExpandMap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vị trí xe',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: onExpandMap,
              child: Text(
                'Mở rộng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingSM),
        // Map + overlay
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                // ─── Map ───
                Positioned.fill(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        AppConstants.mapDefaultLat,
                        AppConstants.mapDefaultLng,
                      ),
                      initialZoom: AppConstants.mapDefaultZoom,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: isDark
                            ? const ['a', 'b', 'c', 'd']
                            : const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.safewheels.mobile',
                      ),
                      // Bus marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              AppConstants.mapDefaultLat,
                              AppConstants.mapDefaultLng,
                            ),
                            width: 120,
                            height: 32,
                            child: const _BusMarker(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ─── Next-stop overlay bên trong map ───
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    margin: const EdgeInsets.all(AppConstants.paddingSM),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingSM,
                      vertical: AppConstants.paddingSM,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard.withValues(alpha: 0.92)
                          : AppColors.lightCard.withValues(alpha: 0.92),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMD),
                    ),
                    child: Row(
                      children: [
                        // Location icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusSM),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSM),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ĐIỂM TIẾP THEO',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Số 12, Phố Huế, Hoàn Kiếm',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // ETA badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingSM,
                            vertical: AppConstants.paddingXS,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusSM),
                          ),
                          child: Text(
                            '5p nữa',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
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
}

/// Marker xe buýt trên bản đồ — hiển thị biển số.
class _BusMarker extends StatelessWidget {
  const _BusMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSM,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_bus_rounded,
            size: 14,
            color: AppColors.darkTextPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            'Xe 29B-123.45',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
