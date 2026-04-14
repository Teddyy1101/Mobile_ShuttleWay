import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/utils/polyline_decoder.dart';
import '../../../data/models/trip_model.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../widgets/bus_marker_widget.dart';
import '../widgets/station_marker_widget.dart';
import '../widgets/attendance_bottom_sheet.dart';
import '../widgets/trip_attendance_list_sheet.dart';

class DriverMapScreen extends StatefulWidget {
  final DriverHomeController driverHomeController;
  final SocketService socketService;

  const DriverMapScreen({
    super.key,
    required this.driverHomeController,
    required this.socketService,
  });

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final MapController _mapController = MapController();

  List<LatLng> _polylinePoints = [];
  List<TripRouteStationModel> _orderedStations = [];
  /// Index polyline gần nhất với mỗi trạm (dùng để detect đến trạm chính xác).
  List<int> _stationPolyIndices = [];
  int _currentPolyIdx = 0;
  LatLng? _busPosition;
  Timer? _moveTimer;
  bool _isMoving = false;
  int _nextStationIdx = 0;
  bool _isStarting = false;
  bool _hasFittedBounds = false;
  bool _reachedLastStation = false;

  /// Khoảng cách di chuyển mỗi tick (mét).
  static const double _moveStepMeters = 5.0;

  /// Interval giữa các tick (ms) — càng nhỏ càng mượt.
  static const int _moveIntervalMs = 80;

  /// Thời điểm emit socket gần nhất (để throttle ~500ms).
  DateTime _lastEmitTime = DateTime(2000);

  @override
  void dispose() {
    _moveTimer?.cancel();
    _cleanupSocket();
    super.dispose();
  }

  void _cleanupSocket() {
    final trip = widget.driverHomeController.activeTrip;
    if (trip != null) {
      widget.socketService.leaveTrip(trip.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.driverHomeController,
      builder: (context, _) {
        final ctrl = widget.driverHomeController;
        final mapTrip = ctrl.mapTrip;

        if (mapTrip == null) {
          return _buildNoActiveTrip(context);
        }

        // Khi có trip mới → chuẩn bị dữ liệu
        _prepareDataIfNeeded(mapTrip);

        return _buildMapView(context, mapTrip, ctrl);
      },
    );
  }

  /// Chuẩn bị polyline + stations nếu chưa có.
  void _prepareDataIfNeeded(TripModel trip) {
    if (_polylinePoints.isEmpty) {
      _orderedStations = _getOrderedStations(trip);
      _polylinePoints = _decodePolyline(trip);

      // Tính polyline index gần nhất cho mỗi trạm
      _computeStationPolyIndices();

      if (_orderedStations.isNotEmpty && _busPosition == null) {
        // Nếu trip đang IN_PROGRESS → khôi phục trạng thái từ currentStation
        if (trip.status.toUpperCase() == 'IN_PROGRESS' && trip.currentStation > 0) {
          _restoreFromCurrentStation(trip);
        } else {
          // Đặt bus ở trạm đầu tiên
          _busPosition = LatLng(
            _orderedStations.first.station.latitude,
            _orderedStations.first.station.longitude,
          );
          _nextStationIdx = 0;
        }
      }
    }
  }

  /// Khôi phục vị trí bus + trạng thái khi quay lại tab bản đồ.
  void _restoreFromCurrentStation(TripModel trip) {
    // currentStation là index trạm mà xe đã đến (0-based)
    final restoredIdx = trip.currentStation;

    if (restoredIdx >= _orderedStations.length) {
      // Đã đến trạm cuối
      final lastStation = _orderedStations.last;
      _busPosition = LatLng(
        lastStation.station.latitude,
        lastStation.station.longitude,
      );
      _nextStationIdx = _orderedStations.length;
      _reachedLastStation = true;
      // Cập nhật polyline index
      if (_stationPolyIndices.isNotEmpty) {
        _currentPolyIdx = _stationPolyIndices.last;
      }
    } else {
      // Đặt bus ở trạm đã đến
      final currentStation = _orderedStations[restoredIdx];
      _busPosition = LatLng(
        currentStation.station.latitude,
        currentStation.station.longitude,
      );
      _nextStationIdx = restoredIdx + 1;
      // Cập nhật polyline index
      if (restoredIdx < _stationPolyIndices.length) {
        _currentPolyIdx = _stationPolyIndices[restoredIdx];
      }
    }
  }

  /// Tính vị trí polyline gần nhất với mỗi trạm (dùng để detect đến trạm).
  void _computeStationPolyIndices() {
    _stationPolyIndices = [];
    if (_polylinePoints.isEmpty || _orderedStations.isEmpty) return;

    const dist = Distance();
    for (final rs in _orderedStations) {
      final stationPos = LatLng(rs.station.latitude, rs.station.longitude);
      int closestIdx = 0;
      double closestDist = double.infinity;

      for (int i = 0; i < _polylinePoints.length; i++) {
        final d = dist.as(LengthUnit.Meter, stationPos, _polylinePoints[i]);
        if (d < closestDist) {
          closestDist = d;
          closestIdx = i;
        }
      }
      _stationPolyIndices.add(closestIdx);
    }
  }

  /// Xác định phase hiện tại.
  _MapPhase _getPhase(DriverHomeController ctrl) {
    if (_reachedLastStation) return _MapPhase.finished;
    if (ctrl.activeTrip != null) return _MapPhase.running;
    if (ctrl.pendingTrip != null) return _MapPhase.preview;
    return _MapPhase.preview;
  }

  /// Dashboard bản đồ chính.
  Widget _buildMapView(
    BuildContext context,
    TripModel trip,
    DriverHomeController ctrl,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final phase = _getPhase(ctrl);

    // Auto-fit bounds lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasFittedBounds && _polylinePoints.length >= 2) {
        _fitBounds();
        _hasFittedBounds = true;
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // ─── Map ───
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _getMapCenter(),
              initialZoom: 14.0,
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

              // ─── Polyline layers ───
              if (_polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: _buildPolylines(isDark, phase),
                ),

              // ─── Station markers ───
              MarkerLayer(
                markers: _buildStationMarkers(),
              ),

              // ─── Bus marker ───
              if (_busPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _busPosition!,
                      width: 50,
                      height: 50,
                      child: const BusMarkerWidget(),
                    ),
                  ],
                ),
            ],
          ),

          _buildTopBar(context, isDark, colorScheme, trip, phase),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(context, trip, isDark, phase),
          ),

          if (phase == _MapPhase.running || phase == _MapPhase.finished)
            Positioned(
              right: AppConstants.paddingMD,
              bottom: 220,
              child: _buildAttendanceListButton(context, trip, isDark),
            ),
        ],
      ),
    );
  }

  // POLYLINE — xám + xanh progressive
  List<Polyline> _buildPolylines(bool isDark, _MapPhase phase) {
    final polylines = <Polyline>[];

    // Layer dưới: toàn bộ tuyến màu xám
    polylines.add(Polyline(
      points: _polylinePoints,
      strokeWidth: 5.0,
      color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
    ));

    // Layer trên: đoạn đã đi màu xanh
    if (_busPosition != null && _currentPolyIdx > 0) {
      final traveledPts = _polylinePoints.sublist(0, _currentPolyIdx + 1);
      // Thêm vị trí bus hiện tại (có thể nằm giữa 2 điểm)
      traveledPts.add(_busPosition!);

      if (traveledPts.length >= 2) {
        polylines.add(Polyline(
          points: traveledPts,
          strokeWidth: 5.0,
          color: const Color(0xFF4285F4),
        ));
      }
    }

    return polylines;
  }

  Widget _buildTopBar(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    TripModel trip,
    _MapPhase phase,
  ) {
    final phaseName = switch (phase) {
      _MapPhase.preview => 'Xem trước tuyến',
      _MapPhase.running => _isMoving ? 'Đang di chuyển...' : 'Chờ tại trạm',
      _MapPhase.finished => 'Đã đến trạm cuối',
    };

    final dotColor = switch (phase) {
      _MapPhase.preview => AppColors.warning,
      _MapPhase.running => _isMoving ? AppColors.success : AppColors.warning,
      _MapPhase.finished => AppColors.success,
    };

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: AppConstants.paddingMD,
      right: AppConstants.paddingMD,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${trip.route?.name ?? ''} · $phaseName',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildCircleButton(
            icon: Icons.zoom_out_map_rounded,
            onTap: _fitBounds,
            isDark: isDark,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

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

  /// Nút mở danh sách điểm danh toàn chuyến trên bản đồ.
  Widget _buildAttendanceListButton(
    BuildContext context,
    TripModel trip,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        showTripAttendanceList(
          context: context,
          tripId: trip.id,
          tripName: trip.route?.name ?? 'Chuyến đi',
          controller: widget.driverHomeController,
        );
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.format_list_bulleted_rounded,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    TripModel trip,
    bool isDark,
    _MapPhase phase,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        MediaQuery.of(context).padding.bottom + AppConstants.paddingMD,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          switch (phase) {
            _MapPhase.preview =>
              _buildPreviewContent(context, trip),
            _MapPhase.running =>
              _buildRunningContent(context, trip),
            _MapPhase.finished =>
              _buildFinishedContent(context, trip),
          },
        ],
      ),
    );
  }

  // ─── Phase: PREVIEW ───

  Widget _buildPreviewContent(BuildContext context, TripModel trip) {
    final colorScheme = Theme.of(context).colorScheme;
    final directionLabel =
        trip.direction == 'PICK_UP' ? 'Đón học sinh' : 'Trả học sinh';
    final firstStation = _orderedStations.isNotEmpty
        ? _orderedStations.first.station.name
        : 'N/A';
    final lastStation = _orderedStations.isNotEmpty
        ? _orderedStations.last.station.name
        : 'N/A';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_bus_filled,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.route?.name ?? 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$directionLabel · ${_orderedStations.length} trạm',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.trip_origin,
                      size: 14, color: Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      firstStation,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_forward,
                      size: 14,
                      color:
                          colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(width: 4),
                  const Icon(Icons.location_on,
                      size: 14, color: Color(0xFFEA4335)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lastStation,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Nút CHẠY DEMO ───
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isStarting ? null : () => _handlePlayStart(trip.id),
            icon: _isStarting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 28),
            label: Text(_isStarting ? 'Đang khởi hành...' : 'CHẠY DEMO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Phase: RUNNING ───

  Widget _buildRunningContent(BuildContext context, TripModel trip) {
    final colorScheme = Theme.of(context).colorScheme;

    // Đang di chuyển → hiển thị info trạm đang hướng đến
    if (_isMoving) {
      return _buildMovingInfo(context);
    }

    // Dừng tại trạm → hiển thị nút Tiếp tục
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStoppedAtStationInfo(context),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleContinue(trip.id),
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              _nextStationIdx >= _orderedStations.length
                  ? 'KẾT THÚC CHUYẾN'
                  : 'TIẾP TỤC',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _nextStationIdx >= _orderedStations.length
                  ? AppColors.success
                  : colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Info khi bus đang di chuyển.
  Widget _buildMovingInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_nextStationIdx >= _orderedStations.length) {
      return const SizedBox.shrink();
    }
    final nextStation = _orderedStations[_nextStationIdx];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐANG ĐI ĐẾN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextStation.station.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_nextStationIdx + 1}/${_orderedStations.length}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Info khi bus dừng tại trạm.
  Widget _buildStoppedAtStationInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Nếu _nextStationIdx == 0 → bus đang ở trạm đầu tiên (chưa di chuyển)
    final stoppedIdx = _nextStationIdx > 0 ? _nextStationIdx - 1 : 0;
    final stationName = stoppedIdx >= 0 && stoppedIdx < _orderedStations.length
        ? _orderedStations[stoppedIdx].station.name
        : 'Trạm';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded,
                size: 24, color: AppColors.warning),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ĐÃ ĐẾN TRẠM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stationName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${stoppedIdx + 1}/${_orderedStations.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Phase: FINISHED ───

  Widget _buildFinishedContent(BuildContext context, TripModel trip) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_rounded,
                    size: 24, color: AppColors.success),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ĐÃ ĐẾN TRẠM CUỐI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bấm nút bên dưới để hoàn thành chuyến',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleCompleteTrip(trip.id),
            icon: const Icon(Icons.flag_rounded, size: 22),
            label: const Text('KẾT THÚC CHUYẾN'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // EMPTY STATE
  Widget _buildNoActiveTrip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
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
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusLG),
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
                    'Chưa bắt đầu chuyến',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSM),
                  Text(
                    'Bấm "Bắt đầu chuyến" ở trang chủ để khởi hành.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.5,
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

  /// Bấm CHẠY DEMO → gọi API startTrip → điểm danh trạm đầu → xe chạy.
  Future<void> _handlePlayStart(String tripId) async {
    setState(() => _isStarting = true);

    final ctrl = widget.driverHomeController;
    final success = await ctrl.startTrip(tripId);

    if (!success || !mounted) {
      if (mounted) setState(() => _isStarting = false);
      return;
    }

    ctrl.clearPendingTrip();

    // Kết nối socket và join room để broadcast vị trí cho parent/student
    await widget.socketService.connect();
    widget.socketService.joinTrip(tripId);

    // Gọi API updateStation(0) cho trạm đầu tiên
    ctrl.updateStation(tripId, 0).catchError((_) => false);

    // Cập nhật _nextStationIdx nhưng GIỮ _isStarting = true
    // để tránh flash panel "ĐÃ ĐẾN TRẠM"
    _nextStationIdx = 1;

    // Mở bottom sheet điểm danh trạm đầu → chờ đóng sheet
    if (_orderedStations.isNotEmpty && mounted) {
      await showAttendanceSheet(
        context: context,
        tripId: tripId,
        stationId: _orderedStations.first.station.id,
        stationName: _orderedStations.first.station.name,
        controller: ctrl,
      );
    }

    // Sau khi đóng sheet → tắt loading + bắt đầu chạy
    if (mounted) {
      setState(() => _isStarting = false);
      _startMoving();
    }
  }

  /// Bấm TIẾP TỤC → tiếp tục di chuyển (API updateStation đã gọi khi đến trạm).
  Future<void> _handleContinue(String tripId) async {
    // Nếu đã qua hết các trạm → hoàn thành
    if (_nextStationIdx >= _orderedStations.length) {
      _handleCompleteTrip(tripId);
      return;
    }

    // Tiếp tục di chuyển (API updateStation đã gọi lúc icon đến trạm)
    _startMoving();
  }

  /// Bấm KẾT THÚC CHUYẾN.
  Future<void> _handleCompleteTrip(String tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn thành chuyến?'),
        content: const Text('Bạn có chắc muốn hoàn thành chuyến đi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _moveTimer?.cancel();
      widget.socketService.leaveTrip(tripId);

      final success =
          await widget.driverHomeController.completeTrip(tripId);
      if (success && mounted) {
        setState(() {
          _busPosition = null;
          _currentPolyIdx = 0;
          _polylinePoints = [];
          _orderedStations = [];
          _stationPolyIndices = [];
          _hasFittedBounds = false;
          _reachedLastStation = false;
          _isMoving = false;
          _nextStationIdx = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chuyến đi đã hoàn thành!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  /// Bắt đầu di chuyển bus.
  void _startMoving() {
    _moveTimer?.cancel();
    setState(() => _isMoving = true);

    _moveTimer = Timer.periodic(
      const Duration(milliseconds: _moveIntervalMs),
      (_) => _moveBusTick(),
    );
  }

  /// Dừng bus (đến trạm).
  void _stopMoving() {
    _moveTimer?.cancel();
    if (mounted) {
      setState(() => _isMoving = false);
    }
  }

  /// Hiển thị màn hình điểm danh khi xe đến trạm.
  void _triggerAttendance(TripRouteStationModel routeStation) {
    final trip = widget.driverHomeController.activeTrip;
    if (trip == null || !mounted) return;

    // Dùng addPostFrameCallback để tránh gọi showModalBottomSheet
    // trong khi setState đang chạy.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAttendanceSheet(
        context: context,
        tripId: trip.id,
        stationId: routeStation.station.id,
        stationName: routeStation.station.name,
        controller: widget.driverHomeController,
      );
    });
  }

  /// Mỗi tick: di chuyển bus tiến lên _moveStepMeters trên polyline.
  void _moveBusTick() {
    if (!mounted || _polylinePoints.isEmpty) {
      _stopMoving();
      return;
    }

    // Đã đi hết polyline
    if (_currentPolyIdx >= _polylinePoints.length - 1) {
      _stopMoving();
      setState(() => _reachedLastStation = true);
      return;
    }

    // Tính vị trí tiếp theo
    const dist = Distance();
    double remainingStep = _moveStepMeters;
    var currentPos = _busPosition ?? _polylinePoints[_currentPolyIdx];
    var idx = _currentPolyIdx;

    while (remainingStep > 0 && idx < _polylinePoints.length - 1) {
      final nextPt = _polylinePoints[idx + 1];
      final segDist = dist.as(LengthUnit.Meter, currentPos, nextPt);

      if (segDist <= remainingStep) {
        // Đi hết đoạn này → nhảy sang đoạn tiếp
        remainingStep -= segDist;
        currentPos = nextPt;
        idx++;
      } else {
        // Đi một phần đoạn này → nội suy
        final fraction = remainingStep / segDist;
        final newLat =
            currentPos.latitude + (nextPt.latitude - currentPos.latitude) * fraction;
        final newLng =
            currentPos.longitude + (nextPt.longitude - currentPos.longitude) * fraction;
        currentPos = LatLng(newLat, newLng);
        remainingStep = 0;
      }
    }

    // Kiểm tra xem đã đến trạm tiếp theo chưa (dựa trên polyline index)
    if (_nextStationIdx < _orderedStations.length &&
        _nextStationIdx < _stationPolyIndices.length) {
      final targetPolyIdx = _stationPolyIndices[_nextStationIdx];

      if (idx >= targetPolyIdx) {
        // Snap vào vị trí trạm
        final nextStation = _orderedStations[_nextStationIdx];
        currentPos = LatLng(
          nextStation.station.latitude,
          nextStation.station.longitude,
        );
        final arrivedStationIdx = _nextStationIdx;
        _nextStationIdx++;

        // Gọi API updateStation ngay khi đến trạm → FCM gửi ngay lập tức
        final trip = widget.driverHomeController.activeTrip;
        if (trip != null) {
          widget.driverHomeController
              .updateStation(trip.id, arrivedStationIdx)
              .catchError((_) => false);
        }

        // Kiểm tra xem đó có phải trạm cuối không
        if (_nextStationIdx >= _orderedStations.length) {
          setState(() {
            _busPosition = currentPos;
            _currentPolyIdx = idx;
            _reachedLastStation = true;
          });
          _stopMoving();

          // Chiều đón (PICK_UP): trạm cuối là trường → không cần điểm danh
          // Chiều về (DROP_OFF): trạm cuối vẫn cần điểm danh trả HS
          final trip = widget.driverHomeController.activeTrip;
          if (trip != null && trip.isDropOff) {
            _triggerAttendance(nextStation);
          }
          return;
        }

        // Dừng tại trạm → chờ bấm Tiếp tục
        setState(() {
          _busPosition = currentPos;
          _currentPolyIdx = idx;
        });
        _stopMoving();
        // Hiển thị màn hình điểm danh
        _triggerAttendance(nextStation);
        return;
      }
    }

    // Cập nhật vị trí
    if (mounted) {
      setState(() {
        _busPosition = currentPos;
        _currentPolyIdx = idx;
      });

      // Emit vị trí qua socket cho parent/student (throttle ~500ms)
      final now = DateTime.now();
      if (now.difference(_lastEmitTime).inMilliseconds >= 500) {
        _lastEmitTime = now;
        final trip = widget.driverHomeController.activeTrip;
        if (trip != null) {
          widget.socketService.emitLocation(
            trip.id,
            currentPos.latitude,
            currentPos.longitude,
          );
        }
      }
    }
  }

  List<TripRouteStationModel> _getOrderedStations(TripModel trip) {
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

  List<LatLng> _decodePolyline(TripModel trip) {
    final route = trip.route;
    if (route == null) return [];

    if (route.encodedPolyline != null && route.encodedPolyline!.isNotEmpty) {
      var points = PolylineDecoder.decode(route.encodedPolyline);
      if (trip.isDropOff) points = points.reversed.toList();
      return points;
    }

    final stations = _getOrderedStations(trip);
    return stations
        .map((s) => LatLng(s.station.latitude, s.station.longitude))
        .toList();
  }

  LatLng _getMapCenter() {
    if (_orderedStations.isEmpty) {
      return const LatLng(21.0285, 105.8542);
    }
    double sumLat = 0, sumLng = 0;
    for (final s in _orderedStations) {
      sumLat += s.station.latitude;
      sumLng += s.station.longitude;
    }
    return LatLng(
      sumLat / _orderedStations.length,
      sumLng / _orderedStations.length,
    );
  }

  List<Marker> _buildStationMarkers() {
    return List.generate(_orderedStations.length, (index) {
      final station = _orderedStations[index].station;
      final StationState state;

      // Trạm đã đi qua: index < _nextStationIdx
      // Trạm hiện tại (bus đang ở hoặc vừa đến): index == _nextStationIdx - 1
      // Trạm chưa đến: index >= _nextStationIdx
      if (index < _nextStationIdx - 1) {
        state = StationState.passed;
      } else if (index == _nextStationIdx - 1 && !_isMoving) {
        state = StationState.current;
      } else if (index < _nextStationIdx) {
        state = StationState.passed;
      } else {
        state = StationState.upcoming;
      }

      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: 100,
        height: 55,
        child: StationMarkerWidget(
          name: station.name,
          index: index,
          state: state,
        ),
      );
    });
  }

  void _fitBounds() {
    final points = <LatLng>[];

    for (final s in _orderedStations) {
      points.add(LatLng(s.station.latitude, s.station.longitude));
    }
    points.addAll(_polylinePoints);

    if (_busPosition != null) {
      points.add(_busPosition!);
    }

    if (points.length < 2) return;

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 100, 40, 280),
        ),
      );
    } catch (_) {}
  }
}

/// Phase hiển thị trên bản đồ.
enum _MapPhase { preview, running, finished }
