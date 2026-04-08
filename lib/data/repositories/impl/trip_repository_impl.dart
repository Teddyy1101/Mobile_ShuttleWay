import '../../../data/models/trip_model.dart';
import '../../../data/sources/trip_api.dart';
import '../trip_repository.dart';

/// Triển khai [TripRepository] bằng API.
class ApiTripRepository implements TripRepository {
  final TripApi _tripApi;

  ApiTripRepository(this._tripApi);

  @override
  Future<List<TripModel>> getMyActiveTrips() {
    return _tripApi.getMyActiveTrips();
  }

  @override
  Future<TripModel> getTripTracking(String tripId) {
    return _tripApi.getTripTracking(tripId);
  }

  @override
  Future<List<TripModel>> getMySchedule(String date, {String? studentId}) {
    return _tripApi.getMySchedule(date, studentId: studentId);
  }
}
