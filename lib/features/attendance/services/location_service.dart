import 'package:geolocator/geolocator.dart';

import '../../../core/api/api_exception.dart';

/// A GPS fix enriched with the mock-location flag, ready to send to the API.
class GpsReading {
  GpsReading({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isMock,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMock;
}

/// Wraps geolocator: handles permission, service checks and reads the current
/// position including the `isMocked` flag used for anti-fake-GPS.
class LocationService {
  Future<GpsReading> current() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw ApiException(
        'Layanan lokasi (GPS) tidak aktif. Aktifkan GPS lalu coba lagi.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw ApiException('Izin lokasi ditolak. Berikan izin untuk presensi.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw ApiException(
        'Izin lokasi diblokir permanen. Aktifkan dari pengaturan aplikasi.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );

    return GpsReading(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      isMock: position.isMocked,
    );
  }
}
