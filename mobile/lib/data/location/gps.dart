import 'package:geolocator/geolocator.dart';

class GpsFix {
  const GpsFix({this.lat, this.lng, this.status = 'unavailable'});

  final double? lat;
  final double? lng;
  final String status;
}

Future<GpsFix> captureGps() async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return const GpsFix();
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return const GpsFix();
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(timeLimit: Duration(seconds: 6)),
    );
    final mocked = position.isMocked;
    return GpsFix(
      lat: position.latitude,
      lng: position.longitude,
      status: mocked ? 'mocked' : 'ok',
    );
  } catch (_) {
    return const GpsFix();
  }
}
