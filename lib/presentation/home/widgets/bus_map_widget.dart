import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../map/controllers/map_controller.dart' as map_ctrl;
import '../../map/widgets/bus_marker_widget.dart';
import '../../map/widgets/station_marker_widget.dart';

/// Widget bản đồ mini hiển thị tuyến xe buýt trên trang chủ.
/// Sử dụng dữ liệu thực từ [MapController] (polyline, bus position, stations).
class BusMapWidget extends StatelessWidget {
  final map_ctrl.MapController mapController;
  final VoidCallback? onExpand;

  const BusMapWidget({
    super.key,
    required this.mapController,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mapController,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            child: Stack(
              children: [
                // ─── Map ───
                _buildMap(isDark, colorScheme),

                // ─── Overlay khi không có chuyến ───
                if (!mapController.hasActiveTrip && !mapController.isLoading)
                  _buildNoTripOverlay(context, isDark, colorScheme),

                // ─── Loading overlay ───
                if (mapController.isLoading)
                  _buildLoadingOverlay(context, isDark),

                // ─── Top info bar ───
                if (mapController.hasActiveTrip)
                  _buildTopInfoBar(context, isDark, colorScheme),

                // ─── Nút Mở rộng ───
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: onExpand,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSM,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.zoom_out_map_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Mở rộng',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bản đồ FlutterMap với polyline, station markers, bus marker.
  Widget _buildMap(bool isDark, ColorScheme colorScheme) {
    final polylinePoints = mapController.polylinePoints;
    final busPosition = mapController.currentBusPosition;
    final stations = mapController.orderedStations;
    final currentIdx = mapController.currentStationIndex;
    final center = mapController.mapCenter;

    // Tính initial camera fit nếu có polyline
    CameraFit? initialFit;
    if (polylinePoints.length >= 2) {
      try {
        final bounds = LatLngBounds.fromPoints(polylinePoints);
        initialFit = CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(30),
        );
      } catch (_) {}
    }

    return FlutterMap(
      key: ValueKey(mapController.selectedTrip?.id ?? 'no-trip'),
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
        initialCameraFit: initialFit,
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

        // ─── Polyline: full route (xám) ───
        if (polylinePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 4.0,
                color: isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFD1D5DB),
              ),
              // Polyline: đoạn đã đi (xanh) — hiển thị ngay khi trip bắt đầu
              if (stations.isNotEmpty && busPosition != null)
                _buildTraveledPolyline(colorScheme),
            ].whereType<Polyline>().toList(),
          ),

        // ─── Station markers ───
        if (stations.isNotEmpty)
          MarkerLayer(
            markers: _buildStationMarkers(stations, currentIdx),
          ),

        // ─── Bus marker ───
        if (busPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: busPosition,
                width: 40,
                height: 40,
                child: const BusMarkerWidget(),
              ),
            ],
          ),
      ],
    );
  }

  /// Polyline đoạn đã đi (xanh) — theo polyline thực tế.
  Polyline _buildTraveledPolyline(ColorScheme colorScheme) {
    final polyline = mapController.polylinePoints;
    final busPos = mapController.currentBusPosition;

    if (polyline.isEmpty || busPos == null) {
      return Polyline(points: [], strokeWidth: 0, color: Colors.transparent);
    }

    // Tìm điểm polyline gần nhất với bus hiện tại
    int closestIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < polyline.length; i++) {
      final dx = polyline[i].latitude - busPos.latitude;
      final dy = polyline[i].longitude - busPos.longitude;
      final d = dx * dx + dy * dy;
      if (d < minDist) {
        minDist = d;
        closestIdx = i;
      }
    }

    final traveledPoints = <LatLng>[
      ...polyline.sublist(0, closestIdx + 1),
      busPos,
    ];

    return Polyline(
      points: traveledPoints,
      strokeWidth: 4.0,
      color: const Color(0xFF4285F4),
    );
  }

  /// Station markers với trạng thái passed/current/upcoming.
  List<Marker> _buildStationMarkers(
    List stations,
    int currentIdx,
  ) {
    return List.generate(stations.length, (index) {
      final station = stations[index].station;
      final StationState state;

      // currentStation l\u00e0 tr\u1ea1m bus \u0111\u00e3 \u0111\u1ebfn \u2192 \u0111\u00e1nh d\u1ea5u passed
      if (index <= currentIdx) {
        state = StationState.passed;
      } else {
        state = StationState.upcoming;
      }

      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: 90,
        height: 55,
        child: StationMarkerWidget(
          name: station.name,
          index: index,
          state: state,
        ),
      );
    });
  }

  /// Overlay khi không có chuyến active — "Đang chờ chuyến đi".
  Widget _buildNoTripOverlay(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Positioned.fill(
      child: Container(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 24,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Đang chờ chuyến đi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bản đồ sẽ hiển thị khi tài xế bắt đầu chuyến',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Loading overlay.
  Widget _buildLoadingOverlay(BuildContext context, bool isDark) {
    return Positioned.fill(
      child: Container(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.3),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }

  /// Top info bar khi có chuyến active.
  Widget _buildTopInfoBar(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final trip = mapController.selectedTrip;
    if (trip == null) return const SizedBox.shrink();

    final routeName = trip.route?.name ?? '';
    final currentIdx = mapController.currentStationIndex;
    final totalStations = mapController.orderedStations.length;
    final nextStationName = currentIdx < totalStations
        ? mapController.orderedStations[currentIdx].station.name
        : 'Trạm cuối';

    return Positioned(
      left: 8,
      top: 8,
      right: 56,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    routeName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Tiếp: $nextStationName (${currentIdx + 1}/$totalStations)',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
