import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/child_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/map_controller.dart' as app;
import '../widgets/bus_marker_widget.dart';
import '../widgets/station_marker_widget.dart';
import '../widgets/trip_info_sheet_widget.dart';

/// Màn hình bản đồ theo dõi xe buýt real-time.
/// Hiển thị tuyến đường, các trạm, và vị trí xe buýt.
class MapScreen extends StatefulWidget {
  final app.MapController mapController;
  final ProfileController? profileController;
  final List<ChildModel> children;

  const MapScreen({
    super.key,
    required this.mapController,
    this.profileController,
    this.children = const [],
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _flutterMapController = MapController();

  @override
  void initState() {
    super.initState();
    // Không gọi loadActiveTrips() ở đây — ParentHomeScreen.initState()
    // đã gọi rồi và discovery polling đang chạy.
    // Chỉ reload nếu chưa có polling nào đang chạy.
    if (!widget.mapController.isPollingActive) {
      widget.mapController.loadActiveTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.mapController,
      builder: (context, _) {
        final controller = widget.mapController;

        if (controller.isLoading && !controller.hasActiveTrip) {
          return _buildLoading(context);
        }

        if (!controller.hasActiveTrip) {
          return _buildEmptyState(context);
        }

        return _buildMapView(context, controller);
      },
    );
  }

  /// Bản đồ chính với polyline, markers, và bottom sheet info.
  Widget _buildMapView(BuildContext context, app.MapController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Map ───
          FlutterMap(
            mapController: _flutterMapController,
            options: MapOptions(
              initialCenter: controller.mapCenter,
              initialZoom: 14.0,
            ),
            children: [
              // Tile layer
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: isDark
                    ? const ['a', 'b', 'c', 'd']
                    : const ['a', 'b', 'c'],
                userAgentPackageName: 'com.safewheels.mobile',
              ),
              // Polyline route: 2 layers (gray remaining + blue traveled)
              if (controller.polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Full route — gray
                    Polyline(
                      points: controller.polylinePoints,
                      strokeWidth: 4.0,
                      color: isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD1D5DB),
                    ),
                    // Traveled section — blue (hiển thị ngay khi trip bắt đầu)
                    if (controller.orderedStations.isNotEmpty &&
                        controller.currentBusPosition != null)
                      _buildTraveledPolyline(controller),
                  ].whereType<Polyline>().toList(),
                ),
              // Station markers
              MarkerLayer(
                markers: _buildStationMarkers(controller),
              ),
              // Bus marker
              if (controller.currentBusPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: controller.currentBusPosition!,
                      width: 150,
                      height: 50,
                      child: BusMarkerWidget(
                        licensePlate: controller.selectedTrip?.bus?.licensePlate,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ─── Top bar ───
          _buildTopBar(context, controller, isDark),

          // ─── Student selector (PARENT with ≥2 children) ───
          if (_isParentWithMultipleChildren)
            _buildStudentSelector(context, isDark),

          // ─── Next station overlay ───
          if (controller.orderedStations.isNotEmpty)
            Positioned(
              left: AppConstants.paddingMD,
              right: AppConstants.paddingMD,
              bottom: MediaQuery.of(context).size.height * 0.16 + 16,
              child: _buildNextStationCard(context, controller, isDark),
            ),

          // ─── Bottom sheet ───
          TripInfoSheetWidget(
            trip: controller.selectedTrip!,
            orderedStations: controller.orderedStations,
            currentStationIndex: controller.currentStationIndex,
          ),
        ],
      ),
    );
  }

  /// Kiểm tra user là PARENT với ≥2 con.
  bool get _isParentWithMultipleChildren =>
      widget.profileController?.isParent == true &&
      widget.children.length >= 2;

  /// Polyline đoạn đã đi (xanh) — theo polyline thực tế, không phải đường chim bay.
  Polyline _buildTraveledPolyline(app.MapController controller) {
    final polyline = controller.polylinePoints;
    final busPos = controller.currentBusPosition;

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

    // Lấy phần polyline từ đầu → điểm gần bus + vị trí bus
    final traveledPoints = <LatLng>[
      ...polyline.sublist(0, closestIdx + 1),
      busPos,
    ];

    return Polyline(
      points: traveledPoints,
      strokeWidth: 5.0,
      color: const Color(0xFF4285F4),
    );
  }

  /// Student selector chips cho PARENT.
  Widget _buildStudentSelector(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedId = widget.mapController.selectedStudentId;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 56,
      left: AppConstants.paddingMD,
      right: AppConstants.paddingMD,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingSM,
          vertical: AppConstants.paddingXS,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.children.map((child) {
              final isActive = selectedId == child.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    widget.mapController.selectStudentTrip(child.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSM,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: isActive
                              ? Colors.white.withValues(alpha: 0.3)
                              : colorScheme.primary.withValues(alpha: 0.15),
                          backgroundImage: child.avatarUrl != null
                              ? NetworkImage(child.avatarUrl!)
                              : null,
                          child: child.avatarUrl == null
                              ? Text(
                                  child.fullName.isNotEmpty
                                      ? child.fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.white
                                        : colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          child.fullName.split(' ').last,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Tạo danh sách Marker cho các trạm.
  List<Marker> _buildStationMarkers(app.MapController controller) {
    final stations = controller.orderedStations;
    final currentIndex = controller.currentStationIndex;

    return List.generate(stations.length, (index) {
      final station = stations[index].station;
      // currentStation là trạm bus đã đến → đánh dấu passed
      final StationState state;
      if (index <= currentIndex) {
        state = StationState.passed;
      } else {
        state = StationState.upcoming;
      }

      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: 120,
        height: 55,
        child: StationMarkerWidget(
          name: station.name,
          index: index,
          state: state,
        ),
      );
    });
  }

  /// Top bar với nút quay lại và fit bounds.
  Widget _buildTopBar(
    BuildContext context,
    app.MapController controller,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: AppConstants.paddingMD,
      right: AppConstants.paddingMD,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Refresh button
          _buildCircleButton(
            icon: Icons.refresh_rounded,
            onTap: () => controller.loadActiveTrips(),
            isDark: isDark,
            colorScheme: colorScheme,
          ),
          // Fit to route button
          _buildCircleButton(
            icon: Icons.center_focus_strong_rounded,
            onTap: () => _fitBounds(controller),
            isDark: isDark,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  /// Nút tròn bo góc.
  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: colorScheme.onSurface),
      ),
    );
  }

  /// Card hiển thị trạm tiếp theo.
  Widget _buildNextStationCard(
    BuildContext context,
    app.MapController controller,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final stations = controller.orderedStations;
    final currentIndex = controller.currentStationIndex;

    // Tìm trạm tiếp theo
    final nextIndex = currentIndex + 1;
    if (nextIndex >= stations.length) {
      return _buildArrivalCard(context, isDark);
    }
    final nextStation = stations[nextIndex].station;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSM,
        vertical: AppConstants.paddingSM,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Icon(
              Icons.location_on_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
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
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextStation.name,
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSM,
              vertical: AppConstants.paddingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Text(
              'Trạm ${nextIndex + 1}/${stations.length}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card khi xe đã đến trạm cuối.
  Widget _buildArrivalCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSM,
        vertical: AppConstants.paddingSM,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          Expanded(
            child: Text(
              'Xe đã đến trạm cuối',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fit camera vào toàn bộ tuyến.
  void _fitBounds(app.MapController controller) {
    final points = <LatLng>[];
    for (final s in controller.orderedStations) {
      points.add(LatLng(s.station.latitude, s.station.longitude));
    }
    if (controller.currentBusPosition != null) {
      points.add(controller.currentBusPosition!);
    }
    if (points.length < 2) return;

    final bounds = LatLngBounds.fromPoints(points);
    _flutterMapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  /// Loading indicator.
  Widget _buildLoading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMD),
            Text(
              'Đang tải bản đồ...',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state khi không có chuyến đi active.
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Bản đồ nền
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                AppConstants.mapDefaultLat,
                AppConstants.mapDefaultLng,
              ),
              initialZoom: AppConstants.mapDefaultZoom,
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
            ],
          ),
          // Overlay thông báo
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingXL,
              ),
              padding: const EdgeInsets.all(AppConstants.paddingLG),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus_outlined,
                      size: 32,
                      color: colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMD),
                  Text(
                    'Xe chưa khởi hành',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSM),
                  Text(
                    'Hiện tại chưa có chuyến xe nào đang hoạt động trên tuyến của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLG),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          widget.mapController.loadActiveTrips(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Tải lại'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMD),
                        ),
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
