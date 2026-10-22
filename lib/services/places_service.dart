import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String primaryServer =
      'https://overpass-api.de/api/interpreter';

  static const String backupServer =
      'https://overpass.kumi.systems/api/interpreter';

  static List<Map<String, dynamic>>? _cachedPlaces;

  static double? _cachedLatitude;
  static double? _cachedLongitude;

  static DateTime? _cacheTime;

  static const Duration cacheDuration =
  Duration(minutes: 5);

  Future<List<Map<String, dynamic>>>
  getPlacesNearChargingStation({
    required double latitude,
    required double longitude,
    required int chargingMinutes,
  }) async {
    debugPrint(
      '==========================================',
    );
    debugPrint(
      'FAST NEARBY PLACES SEARCH',
    );
    debugPrint(
      'Latitude: $latitude',
    );
    debugPrint(
      'Longitude: $longitude',
    );
    debugPrint(
      'Charging time: $chargingMinutes',
    );
    debugPrint(
      '==========================================',
    );

    // -------------------------------------------------
    // RETURN CACHE IF AVAILABLE
    // -------------------------------------------------

    if (_isCacheValid(
      latitude,
      longitude,
    )) {
      debugPrint(
        'Returning cached nearby places.',
      );

      return _cachedPlaces!;
    }

    // -------------------------------------------------
    // SMALLER 1 KM SEARCH
    // -------------------------------------------------

    const double radius = 1000;

    final String query = '''
[out:json][timeout:10];

(
  nwr["amenity"~"cafe|restaurant|fast_food|food_court|pharmacy|hospital|clinic|bank|atm|parking|fuel"](around:$radius,$latitude,$longitude);

  nwr["shop"~"supermarket|mall|convenience|bakery|department_store"](around:$radius,$latitude,$longitude);

  nwr["tourism"~"hotel|hostel|guest_house"](around:$radius,$latitude,$longitude);

  nwr["leisure"~"park|fitness_centre"](around:$radius,$latitude,$longitude);

  nwr["amenity"~"cinema|theatre|library"](around:$radius,$latitude,$longitude);
);

out center tags;
''';

    // -------------------------------------------------
    // FIRST FAST REQUEST
    // -------------------------------------------------

    try {
      final List<Map<String, dynamic>> result =
      await _requestPlaces(
        primaryServer,
        query,
        latitude,
        longitude,
        chargingMinutes,
      );

      if (result.isNotEmpty) {
        _saveCache(
          latitude,
          longitude,
          result,
        );

        return result;
      }
    } catch (e) {
      debugPrint(
        'Primary places server failed: $e',
      );
    }

    // -------------------------------------------------
    // SMALL BACKUP REQUEST
    // -------------------------------------------------

    debugPrint(
      'Trying backup nearby places server...',
    );

    try {
      final List<Map<String, dynamic>> result =
      await _requestPlaces(
        backupServer,
        query,
        latitude,
        longitude,
        chargingMinutes,
      );

      if (result.isNotEmpty) {
        _saveCache(
          latitude,
          longitude,
          result,
        );

        return result;
      }
    } catch (e) {
      debugPrint(
        'Backup places server failed: $e',
      );
    }

    // -------------------------------------------------
    // LOCAL DEMO FALLBACK
    // -------------------------------------------------

    debugPrint(
      'Using local nearby places fallback.',
    );

    final List<Map<String, dynamic>>
    fallbackPlaces =
    _createFallbackPlaces(
      latitude,
      longitude,
      chargingMinutes,
    );

    _saveCache(
      latitude,
      longitude,
      fallbackPlaces,
    );

    return fallbackPlaces;
  }

  // ===================================================
  // REQUEST
  // ===================================================

  Future<List<Map<String, dynamic>>>
  _requestPlaces(
      String server,
      String query,
      double latitude,
      double longitude,
      int chargingMinutes,
      ) async {
    debugPrint(
      'Requesting places from:',
    );

    debugPrint(server);

    final http.Response response =
    await http
        .post(
      Uri.parse(server),
      headers: {
        'Accept': 'application/json',
        'Content-Type':
        'application/x-www-form-urlencoded',
        'User-Agent':
        'AI-EV-Charging-Assistant/1.0',
      },
      body: {
        'data': query,
      },
    )
        .timeout(
      const Duration(seconds: 8),
    );

    debugPrint(
      'Places HTTP status: '
          '${response.statusCode}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Overpass HTTP ${response.statusCode}',
      );
    }

    final Map<String, dynamic> data =
    jsonDecode(response.body);

    final List<dynamic> elements =
        data['elements'] ?? [];

    debugPrint(
      'Places received: ${elements.length}',
    );

    final List<Map<String, dynamic>>
    result = [];

    final Set<String> seen =
    <String>{};

    for (final dynamic rawElement
    in elements) {
      if (rawElement
      is! Map<String, dynamic>) {
        continue;
      }

      final Map<String, dynamic>
      element = rawElement;

      final Map<String, dynamic> tags =
      Map<String, dynamic>.from(
        element['tags'] ?? {},
      );

      final String name =
      (tags['name'] ?? '')
          .toString()
          .trim();

      if (name.isEmpty) {
        continue;
      }

      double? placeLatitude;
      double? placeLongitude;

      // -----------------------------
      // NODE
      // -----------------------------

      if (element['lat'] != null &&
          element['lon'] != null) {
        placeLatitude =
            (element['lat'] as num)
                .toDouble();

        placeLongitude =
            (element['lon'] as num)
                .toDouble();
      }

      // -----------------------------
      // WAY / RELATION
      // -----------------------------

      if (placeLatitude == null ||
          placeLongitude == null) {
        final dynamic center =
        element['center'];

        if (center is Map &&
            center['lat'] != null &&
            center['lon'] != null) {
          placeLatitude =
              (center['lat'] as num)
                  .toDouble();

          placeLongitude =
              (center['lon'] as num)
                  .toDouble();
        }
      }

      if (placeLatitude == null ||
          placeLongitude == null) {
        continue;
      }

      // -----------------------------
      // DUPLICATE CHECK
      // -----------------------------

      final String uniqueKey =
          '$name-'
          '${placeLatitude.toStringAsFixed(5)}-'
          '${placeLongitude.toStringAsFixed(5)}';

      if (seen.contains(uniqueKey)) {
        continue;
      }

      seen.add(uniqueKey);

      // -----------------------------
      // TYPE
      // -----------------------------

      final String type =
      _getPlaceType(tags);

      // -----------------------------
      // DISTANCE
      // -----------------------------

      final double distanceMeters =
      Geolocator.distanceBetween(
        latitude,
        longitude,
        placeLatitude,
        placeLongitude,
      );

      final double distanceKm =
          distanceMeters / 1000;

      // -----------------------------
      // WALKING TIME
      // -----------------------------

      final int walkingMinutes =
      (distanceMeters / 80).ceil();

      final int roundTripMinutes =
          walkingMinutes * 2;

      // -----------------------------
      // RECOMMENDATION
      // -----------------------------

      bool recommended = false;

      if (chargingMinutes > 0 &&
          roundTripMinutes <=
              chargingMinutes) {
        recommended = true;
      }

      if (distanceMeters <= 300 &&
          chargingMinutes >= 10) {
        recommended = true;
      }

      // -----------------------------
      // ADDRESS
      // -----------------------------

      final String address =
      _buildAddress(tags);

      result.add({
        'name': name,
        'type': type,
        'latitude': placeLatitude,
        'longitude': placeLongitude,
        'distanceKm': distanceKm,
        'walkingMinutes':
        walkingMinutes,
        'roundTripMinutes':
        roundTripMinutes,
        'recommended':
        recommended,
        'address': address,
      });
    }

    // -------------------------------------------------
    // SORT
    // -------------------------------------------------

    result.sort(
          (a, b) {
        final double aDistance =
        (a['distanceKm'] as num)
            .toDouble();

        final double bDistance =
        (b['distanceKm'] as num)
            .toDouble();

        return aDistance.compareTo(
          bDistance,
        );
      },
    );

    // -------------------------------------------------
    // PUT RECOMMENDED PLACES FIRST
    // -------------------------------------------------

    result.sort(
          (a, b) {
        final bool aRecommended =
            a['recommended'] == true;

        final bool bRecommended =
            b['recommended'] == true;

        if (aRecommended &&
            !bRecommended) {
          return -1;
        }

        if (!aRecommended &&
            bRecommended) {
          return 1;
        }

        final double aDistance =
        (a['distanceKm'] as num)
            .toDouble();

        final double bDistance =
        (b['distanceKm'] as num)
            .toDouble();

        return aDistance.compareTo(
          bDistance,
        );
      },
    );

    // -------------------------------------------------
    // LIMIT RESULTS
    // -------------------------------------------------

    if (result.length > 20) {
      return result.sublist(0, 20);
    }

    return result;
  }

  // ===================================================
  // CACHE
  // ===================================================

  bool _isCacheValid(
      double latitude,
      double longitude,
      ) {
    if (_cachedPlaces == null ||
        _cacheTime == null ||
        _cachedLatitude == null ||
        _cachedLongitude == null) {
      return false;
    }

    final Duration age =
    DateTime.now().difference(
      _cacheTime!,
    );

    if (age > cacheDuration) {
      return false;
    }

    final double distance =
    Geolocator.distanceBetween(
      latitude,
      longitude,
      _cachedLatitude!,
      _cachedLongitude!,
    );

    return distance < 500;
  }

  void _saveCache(
      double latitude,
      double longitude,
      List<Map<String, dynamic>> places,
      ) {
    _cachedPlaces = places;
    _cachedLatitude = latitude;
    _cachedLongitude = longitude;
    _cacheTime = DateTime.now();

    debugPrint(
      'Nearby places cached.',
    );
  }

  // ===================================================
  // FALLBACK DATA
  // ===================================================

  List<Map<String, dynamic>>
  _createFallbackPlaces(
      double latitude,
      double longitude,
      int chargingMinutes,
      ) {
    return [
      {
        'name': 'Nearby Cafe',
        'type': 'Cafe',
        'latitude': latitude + 0.0010,
        'longitude': longitude + 0.0005,
        'distanceKm': 0.12,
        'walkingMinutes': 2,
        'roundTripMinutes': 4,
        'recommended': chargingMinutes >= 5,
        'address': 'Nearby charging area',
      },
      {
        'name': 'Nearby Restaurant',
        'type': 'Restaurant',
        'latitude': latitude + 0.0020,
        'longitude': longitude - 0.0010,
        'distanceKm': 0.25,
        'walkingMinutes': 4,
        'roundTripMinutes': 8,
        'recommended': chargingMinutes >= 10,
        'address': 'Nearby charging area',
      },
      {
        'name': 'Nearby Supermarket',
        'type': 'Supermarket',
        'latitude': latitude - 0.0020,
        'longitude': longitude + 0.0010,
        'distanceKm': 0.31,
        'walkingMinutes': 5,
        'roundTripMinutes': 10,
        'recommended': chargingMinutes >= 12,
        'address': 'Nearby charging area',
      },
      {
        'name': 'Nearby Pharmacy',
        'type': 'Pharmacy',
        'latitude': latitude + 0.0030,
        'longitude': longitude + 0.0015,
        'distanceKm': 0.42,
        'walkingMinutes': 6,
        'roundTripMinutes': 12,
        'recommended': chargingMinutes >= 15,
        'address': 'Nearby charging area',
      },
      {
        'name': 'Nearby Fuel Station',
        'type': 'Fuel Station',
        'latitude': latitude - 0.0030,
        'longitude': longitude - 0.0010,
        'distanceKm': 0.48,
        'walkingMinutes': 7,
        'roundTripMinutes': 14,
        'recommended': chargingMinutes >= 18,
        'address': 'Nearby charging area',
      },
    ];
  }

  // ===================================================
  // TYPE
  // ===================================================

  String _getPlaceType(
      Map<String, dynamic> tags,
      ) {
    final String amenity =
        tags['amenity']?.toString() ?? '';

    final String shop =
        tags['shop']?.toString() ?? '';

    final String tourism =
        tags['tourism']?.toString() ?? '';

    final String leisure =
        tags['leisure']?.toString() ?? '';

    if (amenity == 'cafe') {
      return 'Cafe';
    }

    if (amenity == 'restaurant') {
      return 'Restaurant';
    }

    if (amenity == 'fast_food') {
      return 'Fast Food';
    }

    if (amenity == 'food_court') {
      return 'Food Court';
    }

    if (shop == 'supermarket') {
      return 'Supermarket';
    }

    if (shop == 'mall') {
      return 'Shopping Mall';
    }

    if (shop == 'department_store') {
      return 'Department Store';
    }

    if (shop == 'convenience') {
      return 'Convenience Store';
    }

    if (shop == 'bakery') {
      return 'Bakery';
    }

    if (amenity == 'hospital') {
      return 'Hospital';
    }

    if (amenity == 'clinic') {
      return 'Medical Clinic';
    }

    if (amenity == 'pharmacy') {
      return 'Pharmacy';
    }

    if (tourism == 'hotel') {
      return 'Hotel';
    }

    if (tourism == 'hostel') {
      return 'Hostel';
    }

    if (amenity == 'fuel') {
      return 'Fuel Station';
    }

    if (amenity == 'cinema') {
      return 'Cinema';
    }

    if (amenity == 'theatre') {
      return 'Theatre';
    }

    if (leisure == 'park') {
      return 'Park';
    }

    if (leisure == 'fitness_centre') {
      return 'Gym';
    }

    if (amenity == 'bank') {
      return 'Bank';
    }

    if (amenity == 'atm') {
      return 'ATM';
    }

    if (amenity == 'parking') {
      return 'Parking';
    }

    if (amenity == 'library') {
      return 'Library';
    }

    return 'Place';
  }

  // ===================================================
  // ADDRESS
  // ===================================================

  String _buildAddress(
      Map<String, dynamic> tags,
      ) {
    final List<String> parts = [];

    final String house =
        tags['addr:housenumber']
            ?.toString()
            .trim() ??
            '';

    final String street =
        tags['addr:street']
            ?.toString()
            .trim() ??
            '';

    final String area =
        tags['addr:suburb']
            ?.toString()
            .trim() ??
            '';

    final String city =
        tags['addr:city']
            ?.toString()
            .trim() ??
            '';

    if (house.isNotEmpty) {
      parts.add(house);
    }

    if (street.isNotEmpty) {
      parts.add(street);
    }

    if (area.isNotEmpty) {
      parts.add(area);
    }

    if (city.isNotEmpty) {
      parts.add(city);
    }

    return parts.join(', ');
  }

  // ===================================================
  // CLEAR CACHE
  // ===================================================

  static void clearCache() {
    _cachedPlaces = null;
    _cachedLatitude = null;
    _cachedLongitude = null;
    _cacheTime = null;
  }
}