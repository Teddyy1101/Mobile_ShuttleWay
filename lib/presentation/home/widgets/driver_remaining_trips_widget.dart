import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_model.dart';

class DriverRemainingTripsWidget extends StatelessWidget {
  final List<TripModel> trips;
  final void Function(TripModel trip)? onTripSelected;

  const DriverRemainingTripsWidget({
    super.key,
    required this.trips,
    this.onTripSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Các chuyến còn lại',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.paddingSM),
        ...trips.map((trip) => _TripCard(
          trip: trip,
          onTripSelected: onTripSelected,
        )),
      ],
    );
  }
}

/// Card chuyến đi nhỏ — hiển thị trong danh sách "còn lại".
class _TripCard extends StatelessWidget {
  final TripModel trip;
  final void Function(TripModel trip)? onTripSelected;

  const _TripCard({required this.trip, this.onTripSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final routeName = trip.route?.name ?? 'N/A';
    final routeCode = trip.route?.routeCode ?? '';
    final directionLabel =
        trip.direction == 'PICK_UP' ? 'Đón học sinh' : 'Trả học sinh';
    final statusInfo = _getStatusInfo(trip.status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSM),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ─── Time column ───
              _buildTimeColumn(colorScheme),
              const SizedBox(width: AppConstants.paddingMD),
              // Vertical divider
              Container(
                width: 1,
                height: 44,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(width: AppConstants.paddingMD),
              // ─── Info ───
              Expanded(
                child: _buildInfoColumn(
                  routeCode,
                  routeName,
                  directionLabel,
                  statusInfo,
                  colorScheme,
                ),
              ),
            ],
          ),
          // ─── Nút chạy chuyến cho PENDING ───
          if (trip.status.toUpperCase() == 'PENDING' && onTripSelected != null) ...[
            const SizedBox(height: AppConstants.paddingSM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onTripSelected!(trip),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Chạy chuyến này'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeColumn(ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          _getFormattedTime(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _getTimeLabel(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(
    String routeCode,
    String routeName,
    String directionLabel,
    _StatusInfo statusInfo,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Route code badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#$routeCode',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusInfo.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusInfo.color,
                ),
              ),
            ),
            const Spacer(),
            // Số học sinh
            Icon(Icons.people_alt_rounded,
                size: 13, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 3),
            Text(
              '${trip.attendanceCount}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Tuyến $routeName',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '• $directionLabel',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  String _getFormattedTime() {
    final status = trip.status.toUpperCase();

    if (status == 'COMPLETED' && trip.endTime != null) {
      final t = trip.endTime!.add(const Duration(hours: 7));
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }

    if (status == 'IN_PROGRESS' && trip.startTime != null) {
      final t = trip.startTime!.add(const Duration(hours: 7));
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }

    // PENDING → giờ lý thuyết từ route
    final estimatedTime = trip.route?.estimatedTime;
    if (estimatedTime != null) {
      return '${estimatedTime.hour.toString().padLeft(2, '0')}:${estimatedTime.minute.toString().padLeft(2, '0')}';
    }
    return '--:--';
  }

  String _getTimeLabel() {
    final status = trip.status.toUpperCase();
    if (status == 'COMPLETED') return 'Hoàn thành';
    if (status == 'IN_PROGRESS') return 'Bắt đầu';
    return 'Dự kiến';
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'IN_PROGRESS':
        return _StatusInfo('Đang chạy', AppColors.warning);
      case 'COMPLETED':
        return _StatusInfo('Đã hoàn thành', AppColors.success);
      case 'CANCELLED':
        return _StatusInfo('Đã hủy', AppColors.error);
      default:
        return _StatusInfo('Chờ thực hiện', AppColors.primary);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}
