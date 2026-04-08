import 'package:latlong2/latlong.dart';

/// Decode chuỗi Google Encoded Polyline thành danh sách tọa độ [LatLng].
///
/// Thuật toán chuẩn:
/// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
class PolylineDecoder {
  PolylineDecoder._();

  /// Decode [encoded] polyline string thành `List<LatLng>`.
  /// Trả về danh sách rỗng nếu chuỗi null hoặc rỗng.
  static List<LatLng> decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return [];

    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
