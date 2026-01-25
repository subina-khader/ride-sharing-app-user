import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteHelper {
  // Fetch route from OSRM (Open Source Routing Machine)
  static Future<Map<String, dynamic>> getRoute(
      LatLng start, LatLng end) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'];
          final distance = route['distance']; // in meters
          final duration = route['duration']; // in seconds

          // Convert coordinates to LatLng
          List<LatLng> routePoints = [];
          for (var coord in geometry) {
            routePoints.add(LatLng(coord[1], coord[0]));
          }

          return {
            'points': routePoints,
            'distance': distance / 1000, // Convert to kilometers
            'duration': duration / 60, // Convert to minutes
            'success': true,
          };
        }
      }

      return {
        'success': false,
        'error': 'Could not fetch route',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Calculate fare based on distance and vehicle type
  static double calculateFare(double distanceInKm, String vehicleType) {
    // Base fare
    double baseFare = 0;
    // Per kilometer rate
    double perKmRate = 0;

    switch (vehicleType.toLowerCase()) {
      case 'bike':
        baseFare = 20.0;
        perKmRate = 8.0;
        break;
      case 'cng':
      case 'auto':
        baseFare = 30.0;
        perKmRate = 12.0;
        break;
      case 'car':
      default:
        baseFare = 50.0;
        perKmRate = 15.0;
        break;
    }

    // Calculate total fare
    double fare = baseFare + (distanceInKm * perKmRate);

    // Round to 2 decimal places
    return double.parse(fare.toStringAsFixed(2));
  }

  // Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceInKm.toStringAsFixed(2)} km';
  }

  // Format duration for display
  static String formatDuration(double durationInMinutes) {
    if (durationInMinutes < 60) {
      return '${durationInMinutes.toStringAsFixed(0)} min';
    }
    int hours = durationInMinutes ~/ 60;
    int minutes = (durationInMinutes % 60).toInt();
    return '${hours}h ${minutes}min';
  }
}