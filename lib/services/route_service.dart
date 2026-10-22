import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RouteService {
  Future<RouteResult?> getRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    try {
      final String url =
          'https://router.project-osrm.org/route/v1/driving/'
          '$startLongitude,$startLatitude;'
          '$endLongitude,$endLatitude'
          '?overview=full&geometries=geojson';

      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data =
      jsonDecode(response.body);

      if (data['code'] != 'Ok') {
        return null;
      }

      final List routes = data['routes'];

      if (routes.isEmpty) {
        return null;
      }

      final Map<String, dynamic> route =
      routes[0] as Map<String, dynamic>;

      final double distanceKm =
          (route['distance'] as num).toDouble() / 1000;

      final double durationMinutes =
          (route['duration'] as num).toDouble() / 60;

      final List coordinates =
      route['geometry']['coordinates'];

      final List<LatLng> points =
      coordinates.map<LatLng>((coordinate) {
        return LatLng(
          (coordinate[1] as num).toDouble(),
          (coordinate[0] as num).toDouble(),
        );
      }).toList();

      return RouteResult(
        points: points,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
      );
    } catch (e) {
      print('Route error: $e');
      return null;
    }
  }
}