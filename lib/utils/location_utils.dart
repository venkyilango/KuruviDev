import 'package:geolocator/geolocator.dart';

class LocationUtils {

  static Future<Map<String, double>> getLocation() async {
    // 1️⃣ Check service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'LOCATION_SERVICE_DISABLED';
    }

    // 2️⃣ Check permission (iOS SAFE)
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw 'LOCATION_PERMISSION_DENIED';
    }

    // 3️⃣ Get location.
    // A time limit is essential: without one this waits forever when no fix is
    // available (indoors, or an emulator with no mock location), leaving the
    // caller stuck on a spinner. Fall back to the last known fix if we have one.
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      return {
        'lat': position.latitude,
        'lng': position.longitude,
      };
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return {
          'lat': last.latitude,
          'lng': last.longitude,
        };
      }
      throw 'LOCATION_TIMEOUT';
    }
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}