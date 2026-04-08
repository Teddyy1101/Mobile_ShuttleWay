import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_model.dart';

/// Widget bottom sheet hiển thị thông tin chuyến đi đang theo dõi.
/// Bao gồm: driver info, bus info, danh sách trạm với progress indicator.
class TripInfoSheetWidget extends StatelessWidget {
  final TripModel trip;
  final List<TripRouteStationModel> orderedStations;
  final int currentStationIndex;

  const TripInfoSheetWidget({
    super.key,
    required this.trip,
    required this.orderedStations,
    required this.currentStationIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.1,
      maxChildSize: 0.55,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusXL),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              _buildHandle(colorScheme),
              _buildTripHeader(context, isDark),
              _buildDriverInfo(context, isDark),
              _buildStationList(context, isDark),
              const SizedBox(height: AppConstants.paddingMD),
            ],
          ),
        );
      },
    );
  }

  /// Thanh kéo (drag handle).
  Widget _buildHandle(ColorScheme colorScheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Header: trạng thái + tên tuyến + biển số xe.
  Widget _buildTripHeader(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final routeName = trip.route?.name ?? 'Chuyến đi';
    final directionLabel = trip.isDropOff ? 'Chiều về' : 'Chiều đi';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
      ),
      child: Row(
        children: [
          // Bus icon container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routeName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildStatusBadge(context),
                    const SizedBox(width: 6),
                    Text(
                      directionLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // License plate
          if (trip.bus != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Text(
                trip.bus!.licensePlate,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Badge trạng thái chuyến đi.
  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Đang chạy',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  /// Thông tin tài xế.
  Widget _buildDriverInfo(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final driver = trip.driver;
    if (driver == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingSM,
        AppConstants.paddingMD,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingSM),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              backgroundImage: driver.avatarUrl != null
                  ? NetworkImage(driver.avatarUrl!)
                  : null,
              child: driver.avatarUrl == null
                  ? Text(
                      driver.fullName.isNotEmpty
                          ? driver.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppConstants.paddingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.fullName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Tài xế',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (driver.phone != null)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Danh sách trạm dừng với progress indicator.
  Widget _buildStationList(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    if (orderedStations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingSM,
        AppConstants.paddingMD,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lộ trình (${orderedStations.length} trạm)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSM),
          ...List.generate(orderedStations.length, (index) {
            return _buildStationItem(
              context,
              orderedStations[index],
              index,
              isDark,
              isLast: index == orderedStations.length - 1,
            );
          }),
        ],
      ),
    );
  }

  /// Một item trạm dừng trong danh sách.
  Widget _buildStationItem(
    BuildContext context,
    TripRouteStationModel routeStation,
    int index,
    bool isDark, {
    required bool isLast,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPassed = index < currentStationIndex;
    final isCurrent = index == currentStationIndex;

    final Color dotColor;
    final Color lineColor;
    if (isPassed) {
      dotColor = AppColors.success;
      lineColor = AppColors.success.withValues(alpha: 0.3);
    } else if (isCurrent) {
      dotColor = colorScheme.primary;
      lineColor = colorScheme.onSurface.withValues(alpha: 0.1);
    } else {
      dotColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
      lineColor = colorScheme.onSurface.withValues(alpha: 0.1);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline: dot + line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 14 : 10,
                  height: isCurrent ? 14 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: isCurrent
                        ? Border.all(
                            color: dotColor.withValues(alpha: 0.3),
                            width: 3,
                          )
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          // Station info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeStation.station.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isPassed
                          ? colorScheme.onSurface.withValues(alpha: 0.45)
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Xe đang ở trạm này',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  if (isPassed)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Đã qua',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
