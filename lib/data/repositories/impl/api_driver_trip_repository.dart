import '../../../data/models/trip_model.dart';
import '../../../data/sources/driver_trip_api.dart';
import '../driver_trip_repository.dart';

class ApiDriverTripRepository implements DriverTripRepository {
  final DriverTripApi _driverTripApi;

  ApiDriverTripRepository(this._driverTripApi);

  @override
  Future<List<TripModel>> getMyDriverTrips({String? date}) {
    return _driverTripApi.getMyDriverTrips(date: date);
  }

  @override
  Future<TripModel> startTrip(String tripId) {
    return _driverTripApi.startTrip(tripId);
  }

  @override
  Future<TripModel> updateStation(String tripId, int nextStationIndex) {
    return _driverTripApi.updateStation(tripId, nextStationIndex);
  }

  @override
  Future<TripModel> completeTrip(String tripId) {
    return _driverTripApi.completeTrip(tripId);
  }

  @override
  Future<Map<String, dynamic>> getStudentsAtStation(
    String tripId,
    String stationId,
  ) {
    return _driverTripApi.getStudentsAtStation(tripId, stationId);
  }

  @override
  Future<Map<String, dynamic>> getTripAttendances(String tripId) {
    return _driverTripApi.getTripAttendances(tripId);
  }

  @override
  Future<Map<String, dynamic>> markAttendance(
    String tripId,
    String studentId,
    String status,
  ) {
    return _driverTripApi.markAttendance(tripId, studentId, status);
  }

  @override
  Future<Map<String, dynamic>> verifyTicket(
    String tripId,
    String ticketId,
  ) {
    return _driverTripApi.verifyTicket(tripId, ticketId);
  }

  @override
  Future<Map<String, dynamic>> getStationSummary(String tripId) {
    return _driverTripApi.getStationSummary(tripId);
  }

  @override
  Future<void> simulateTrip(String tripId) {
    return _driverTripApi.simulateTrip(tripId);
  }
}
