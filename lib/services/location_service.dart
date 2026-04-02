import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// STEP 1: Check and request permission
  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }
  }

  /// STEP 2: Get current position
  Future<Position> getCurrentLocation() async {
    await _checkPermission();

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  
  /// STEP 3: Convert coordinates → readable address
  Future<String> getAddressFromCoordinates(Position position) async {
    try {
      // Validate coordinates
      if (position.latitude == 0 && position.longitude == 0) {
        return "Invalid coordinates";
      }

      List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return "Unknown location";
      }

      final place = placemarks.first;

      // Build readable address
      return _formatAddress(place);

    } catch (e) {
      return "Address unavailable";
    }
  }

  /// STEP 4: Format address (clean output)
  String _formatAddress(Placemark place) {
    return [
      place.name,
      place.locality,
      place.administrativeArea,
      place.country
    ]
        .where((element) => element != null && element.isNotEmpty)
        .join(", ");
  }

  /// STEP 5: Combined method (optional helper)
  Future<Map<String, dynamic>> getFullLocationData() async {
    final position = await getCurrentLocation();

    final address = await getAddressFromCoordinates(position);

    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
      "address": address,
    };
  }
}