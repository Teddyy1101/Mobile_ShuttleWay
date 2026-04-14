import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_model.dart';

class DriverNextTripCardWidget extends StatelessWidget {
  final TripModel trip;
  final bool isStarting;
  final VoidCallback onStartTrip;

  const DriverNextTripCardWidget({
    super.key,
    required this.trip,
    required this.isStarting,
    required this.onStartTrip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routeName = trip.route?.name ?? 'N/A';
    final routeCode = trip.route?.routeCode ?? '';
    final licensePlate = trip.bus?.licensePlate ?? 'N/A';
    final directionLabel =
        trip.direction == 'PICK_UP' ? 'Đón học sinh' : 'Trả học sinh';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.85),
            const Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(routeCode, directionLabel),
          const SizedBox(height: 16),
          _buildRouteInfo(routeName, licensePlate),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildStationsInfo(),
          ),
          const SizedBox(height: 16),
          _buildStartButton(),
        ],
      ),
    );
  }

  /// Header: route code badge + direction badge + student count.
  Widget _buildHeader(String routeCode, String directionLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Route code badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$routeCode',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Direction badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  directionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Student count — dữ liệu thực từ _count.attendances
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '${trip.attendanceCount}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Học sinh',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Route name + time + license plate.
  Widget _buildRouteInfo(String routeName, String licensePlate) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Bus icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tuyến $routeName',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Time + license plate
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      _getFormattedTime(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.directions_car_filled,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      licensePlate,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị điểm đón → điểm trả. Bấm vào mở chi tiết.
  Widget _buildStationsInfo() {
    final stations = trip.route?.stations ?? [];
    if (stations.isEmpty) return const SizedBox.shrink();

    final firstStation = stations.first.station.name;
    final lastStation = stations.last.station.name;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // From icon
          const Icon(Icons.trip_origin, size: 14, color: Color(0xFF22C55E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              firstStation,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward,
                size: 14, color: Colors.white.withValues(alpha: 0.5)),
          ),
          // To icon
          const Icon(Icons.location_on, size: 14, color: Color(0xFFEF4444)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              lastStation,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Nút bắt đầu chuyến.
  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ElevatedButton.icon(
        onPressed: isStarting ? null : onStartTrip,
        icon: isStarting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : const Icon(Icons.play_circle_filled, size: 24),
        label: Text(isStarting ? 'Đang bắt đầu...' : 'BẮT ĐẦU CHUYẾN'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
  
  String _getFormattedTime() {
    final estimatedTime = trip.route?.estimatedTime;
    if (estimatedTime != null) {
      return '${estimatedTime.hour.toString().padLeft(2, '0')}:${estimatedTime.minute.toString().padLeft(2, '0')}';
    }
    return '--:--';
  }
}
