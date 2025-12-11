import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService() {
    _init();
  }

  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _controller.stream;

  Future<void> _init() async {
    final permission = await _ensurePermission();
    if (!permission) return;
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(_controller.add);
  }

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
