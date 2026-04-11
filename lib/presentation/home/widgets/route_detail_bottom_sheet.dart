import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/trip_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class RouteDetailBottomSheet extends StatelessWidget {
  final TripModel trip;

  const RouteDetailBottomSheet({super.key, required this.trip});

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      if (index >= len) break;
      do {
        if (index >= len) break;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      // OSRM uses 1E5 precision
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final route = trip.route;
    if (route == null) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('Không có dữ liệu tuyến đường.'),
      );
    }

    final polylinePoints = route.encodedPolyline != null 
        ? _decodePolyline(route.encodedPolyline!) 
        : <LatLng>[];

    final stationMarkers = route.stations.map((s) {
      return Marker(
        point: LatLng(s.station.latitude, s.station.longitude),
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${s.orderIndex}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }).toList();

    // Tính bound để map tự zoom
    LatLngBounds? bounds;
    if (polylinePoints.isNotEmpty) {
      bounds = LatLngBounds.fromPoints(polylinePoints);
    } else if (route.stations.isNotEmpty) {
      bounds = LatLngBounds.fromPoints(
        route.stations.map((s) => LatLng(s.station.latitude, s.station.longitude)).toList()
      );
    } else {
      bounds = LatLngBounds.fromPoints([const LatLng(AppConstants.mapDefaultLat, AppConstants.mapDefaultLng)]);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXL)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG, vertical: AppConstants.paddingSM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiết lộ trình',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tuyến: ${route.routeCode} • ${route.totalDistance ?? 0} km',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusLG)),
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(40.0),
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
                  if (polylinePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: polylinePoints,
                          strokeWidth: 4.5,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: stationMarkers,
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
