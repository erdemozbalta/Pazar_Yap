import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationDataResult {
  final double latitude;
  final double longitude;
  final String city;
  final String district;
  final String neighborhood;
  final String fullAddress;
  final String title;

  LocationDataResult({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.fullAddress,
    required this.title,
  });
}

class LocationService {
  static Future<LocationDataResult> getCurrentLocation() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

      await Geolocator.openLocationSettings();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Konum izni verilmedi. Lütfen konum iznini onaylayınız.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception('Konum izni kalıcı olarak engellenmiş. Lütfen ayarlar menüsünden konum iznini açınız.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    final double lat = position.latitude;
    final double lng = position.longitude;

    String city = 'İstanbul';
    String district = 'İlçe';
    String neighborhood = 'Mahalle';
    String fullAddress = 'Enlem: ${lat.toStringAsFixed(4)}, Boylam: ${lng.toStringAsFixed(4)}';

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        city = (place.administrativeArea?.isNotEmpty == true)
            ? place.administrativeArea!
            : ((place.locality?.isNotEmpty == true) ? place.locality! : 'İstanbul');

        district = (place.subAdministrativeArea?.isNotEmpty == true)
            ? place.subAdministrativeArea!
            : ((place.subLocality?.isNotEmpty == true) ? place.subLocality! : (place.locality ?? 'İlçe'));

        neighborhood = (place.thoroughfare?.isNotEmpty == true)
            ? place.thoroughfare!
            : ((place.subLocality?.isNotEmpty == true) ? place.subLocality! : (place.name ?? 'Mahalle'));

        final street = place.street ?? place.thoroughfare ?? '';
        fullAddress = '$neighborhood ${street.isNotEmpty ? "$street " : ""}$district / $city';
      }
    } catch (_) {
      fullAddress = '$neighborhood, $district / $city';
    }

    return LocationDataResult(
      latitude: lat,
      longitude: lng,
      city: city,
      district: district,
      neighborhood: neighborhood,
      fullAddress: fullAddress,
      title: 'Mevcut Konumum',
    );
  }
}

