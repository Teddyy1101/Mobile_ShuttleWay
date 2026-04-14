import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/polyline_decoder.dart';
import '../../../data/models/trip_model.dart';
import '../controllers/driver_home_controller.dart';

class DriverTripDetailScreen extends StatefulWidget {
  final List<TripModel> allTrips;
  final int initialTripIndex;
  final DriverHomeController controller;

  const DriverTripDetailScreen({
    super.key,
    required this.allTrips,
    required this.initialTripIndex,
    required this.controller,
  });

  @override
  State<DriverTripDetailScreen> createState() => _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState extends State<DriverTripDetailScreen> {
  late int _currentIndex;
  bool _showMap = false;

  /// Tổng hợp số HS đón/trả tại mỗi trạm: stationId → {pickUpCount, dropOffCount}
  Map<String, dynamic> _stationSummary = {};
  bool _isSummaryLoading = false;

  TripModel get _currentTrip => widget.allTrips[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTripIndex;
    _loadStationSummary();
  }

  /// Fetch station summary từ backend.
  Future<void> _loadStationSummary() async {
    setState(() => _isSummaryLoading = true);
    final data = await widget.controller.getStationSummary(_currentTrip.id);
    if (mounted) {
      setState(() {
        _stationSummary = data;
        _isSummaryLoading = false;
      });
    }
  }

  void _onTripChanged(int index) {
    setState(() {
      _currentIndex = index;
      _stationSummary = {};
    });
    _loadStationSummary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // ─── App Bar giống màn hình đặt vé ───
          _buildAppBar(theme, isDark, backgroundColor),

          // ─── Trip Switcher ───
          if (widget.allTrips.length > 1)
            _TripSwitcher(
              trips: widget.allTrips,
              currentIndex: _currentIndex,
              onChanged: _onTripChanged,
            ),

          // ─── Trip Info Header ───
          _TripInfoHeader(trip: _currentTrip),

          const SizedBox(height: AppConstants.paddingSM),

          // ─── Content: Station list hoặc Map ───
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showMap
                  ? _TripMapView(
                      key: ValueKey('map_${_currentTrip.id}'),
                      trip: _currentTrip,
                    )
                  : _StationListView(
                      key: ValueKey('list_${_currentTrip.id}'),
                      trip: _currentTrip,
                      stationSummary: _stationSummary,
                      isSummaryLoading: _isSummaryLoading,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// App Bar giống màn hình đặt vé (học sinh / phụ huynh).
  Widget _buildAppBar(ThemeData theme, bool isDark, Color bgColor) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXS,
          vertical: AppConstants.paddingSM,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                color: theme.colorScheme.onSurface,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: const CircleBorder(),
              ),
            ),
            Expanded(
              child: Text(
                'Chi tiết chuyến đi',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Nút toggle bản đồ / danh sách
            IconButton(
              onPressed: () => setState(() => _showMap = !_showMap),
              icon: Icon(
                _showMap ? Icons.list_rounded : Icons.map_rounded,
                color: theme.colorScheme.primary,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: const CircleBorder(),
              ),
              tooltip: _showMap ? 'Xem danh sách trạm' : 'Xem bản đồ',
            ),
          ],
        ),
      ),
    );
  }
}

// TRIP SWITCHER — Thanh chuyển đổi giữa các chuyến trong ngày
class _TripSwitcher extends StatelessWidget {
  final List<TripModel> trips;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _TripSwitcher({
    required this.trips,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingSM,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(4),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          final isSelected = index == currentIndex;
          final time = _formatTime(trip.route?.estimatedTime);
          final direction =
              trip.direction == 'PICK_UP' ? 'Đón' : 'Trả';

          return GestureDetector(
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              alignment: Alignment.center,
              child: Text(
                '$direction • $time',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// TRIP INFO HEADER — Thông tin tổng quan chuyến đi
class _TripInfoHeader extends StatelessWidget {
  final TripModel trip;

  const _TripInfoHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routeName = trip.route?.name ?? 'N/A';
    final licensePlate = trip.bus?.licensePlate ?? 'N/A';
    final stationCount = trip.route?.stations.length ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tuyến $routeName',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSM),
          // Dùng Wrap thay vì Row để tránh overflow trên màn hình nhỏ
          Wrap(
            spacing: AppConstants.paddingSM,
            runSpacing: AppConstants.paddingXS,
            children: [
              _buildInfoChip(
                Icons.directions_bus_filled,
                licensePlate,
                colorScheme.primary,
                colorScheme,
              ),
              _buildInfoChip(
                Icons.people_alt_rounded,
                '${trip.attendanceCount} HS',
                AppColors.success,
                colorScheme,
              ),
              _buildInfoChip(
                Icons.pin_drop_rounded,
                '$stationCount trạm',
                AppColors.warning,
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    Color accentColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// STATION LIST VIEW — Danh sách trạm theo thứ tự (kèm số HS đón/trả)
class _StationListView extends StatelessWidget {
  final TripModel trip;
  final Map<String, dynamic> stationSummary;
  final bool isSummaryLoading;

  const _StationListView({
    super.key,
    required this.trip,
    required this.stationSummary,
    this.isSummaryLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final stations = _getOrderedStations();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (stations.isEmpty) {
      return Center(
        child: Text(
          'Chưa có trạm nào',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingSM,
      ),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        final isFirst = index == 0;
        final isLast = index == stations.length - 1;

        // Lấy số HS đón/trả tại trạm này từ summary
        final summaryEntry = stationSummary[station.station.id];
        int pickUpCount = 0;
        int dropOffCount = 0;
        if (summaryEntry is Map) {
          pickUpCount = (summaryEntry['pickUpCount'] as num?)?.toInt() ?? 0;
          dropOffCount = (summaryEntry['dropOffCount'] as num?)?.toInt() ?? 0;
        }

        return _StationTimelineItem(
          station: station,
          index: index,
          isFirst: isFirst,
          isLast: isLast,
          isDark: isDark,
          colorScheme: colorScheme,
          pickUpCount: pickUpCount,
          dropOffCount: dropOffCount,
          isSummaryLoading: isSummaryLoading,
        );
      },
    );
  }

  List<TripRouteStationModel> _getOrderedStations() {
    final stations = List<TripRouteStationModel>.from(
      trip.route?.stations ?? [],
    );
    if (trip.isDropOff) {
      stations.sort((a, b) => b.orderIndex.compareTo(a.orderIndex));
    } else {
      stations.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }
    return stations;
  }
}

/// Item trong timeline trạm dừng — hiển thị badge số HS đón/trả.
class _StationTimelineItem extends StatelessWidget {
  final TripRouteStationModel station;
  final int index;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final ColorScheme colorScheme;
  final int pickUpCount;
  final int dropOffCount;
  final bool isSummaryLoading;

  const _StationTimelineItem({
    required this.station,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    required this.colorScheme,
    this.pickUpCount = 0,
    this.dropOffCount = 0,
    this.isSummaryLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isFirst
        ? AppColors.success
        : isLast
            ? AppColors.error
            : colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Timeline column ───
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Line above dot
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                // Dot
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: dotColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: dotColor,
                      ),
                    ),
                  ),
                ),
                // Line below dot
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.paddingSM),
          // ─── Station card ───
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppConstants.paddingSM),
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(
                  color: isFirst || isLast
                      ? dotColor.withValues(alpha: 0.3)
                      : isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isFirst
                            ? Icons.trip_origin
                            : isLast
                                ? Icons.flag_rounded
                                : Icons.location_on_outlined,
                        size: 18,
                        color: dotColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          station.station.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Thông tin trạm + badge số HS
                  Row(
                    children: [
                      Text(
                        'Trạm ${index + 1} • ${isFirst ? 'Điểm xuất phát' : isLast ? 'Điểm kết thúc' : 'Trạm dừng'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const Spacer(),
                      // Badge số HS đón (xanh lá)
                      if (!isSummaryLoading && pickUpCount > 0)
                        _buildStudentBadge(
                          Icons.login_rounded,
                          '$pickUpCount đón',
                          AppColors.success,
                        ),
                      if (pickUpCount > 0 && dropOffCount > 0)
                        const SizedBox(width: 6),
                      // Badge số HS trả (cam)
                      if (!isSummaryLoading && dropOffCount > 0)
                        _buildStudentBadge(
                          Icons.logout_rounded,
                          '$dropOffCount trả',
                          AppColors.warning,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Badge nhỏ hiển thị số HS đón/trả.
  Widget _buildStudentBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// TRIP MAP VIEW — Bản đồ OSM hiển thị tuyến đường + trạm
class _TripMapView extends StatelessWidget {
  final TripModel trip;

  const _TripMapView({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final stations = _getOrderedStations();
    final polylinePoints = _decodePolyline();

    if (stations.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dữ liệu tuyến đường',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppConstants.radiusLG),
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: _getMapCenter(stations),
          initialZoom: 13.5,
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
          // Polyline tuyến đường
          if (polylinePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: polylinePoints,
                  strokeWidth: 4.0,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
              ],
            ),
          // Station markers
          MarkerLayer(
            markers: _buildStationMarkers(stations, colorScheme),
          ),
        ],
      ),
    );
  }

  List<TripRouteStationModel> _getOrderedStations() {
    final stations = List<TripRouteStationModel>.from(
      trip.route?.stations ?? [],
    );
    if (trip.isDropOff) {
      stations.sort((a, b) => b.orderIndex.compareTo(a.orderIndex));
    } else {
      stations.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }
    return stations;
  }

  List<LatLng> _decodePolyline() {
    final route = trip.route;
    if (route == null) return [];

    if (route.encodedPolyline != null && route.encodedPolyline!.isNotEmpty) {
      var points = PolylineDecoder.decode(route.encodedPolyline);
      if (trip.isDropOff) points = points.reversed.toList();
      return points;
    }

    final stations = _getOrderedStations();
    return stations
        .map((s) => LatLng(s.station.latitude, s.station.longitude))
        .toList();
  }

  LatLng _getMapCenter(List<TripRouteStationModel> stations) {
    if (stations.isEmpty) {
      return LatLng(AppConstants.mapDefaultLat, AppConstants.mapDefaultLng);
    }
    double sumLat = 0, sumLng = 0;
    for (final s in stations) {
      sumLat += s.station.latitude;
      sumLng += s.station.longitude;
    }
    return LatLng(sumLat / stations.length, sumLng / stations.length);
  }

  List<Marker> _buildStationMarkers(
    List<TripRouteStationModel> stations,
    ColorScheme colorScheme,
  ) {
    return List.generate(stations.length, (index) {
      final station = stations[index].station;
      final isFirst = index == 0;
      final isLast = index == stations.length - 1;
      final markerColor = isFirst
          ? AppColors.success
          : isLast
              ? AppColors.error
              : colorScheme.primary;

      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: 120,
        height: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: markerColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: markerColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${index + 1}. ${station.name}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    });
  }
}
