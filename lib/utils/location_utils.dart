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

    // 3️⃣ Get location
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return {
      'lat': position.latitude,
      'lng': position.longitude,
    };
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}