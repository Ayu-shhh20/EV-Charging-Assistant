
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class OpenStreetMapService {
  static final Map<String, _CacheEntry> _cache = {};

  static const Duration cacheDuration = Duration(minutes: 5);

  static const List<String> _overpassServers = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  ];

  Future<List<Map<String, dynamic>>> getNearbyChargingStations({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    final double radiusMeters = radius.clamp(1000, 30000).toDouble();

    final String cacheKey =
        '${latitude.toStringAsFixed(3)}_'
        '${longitude.toStringAsFixed(3)}_'
        '${radiusMeters.toInt()}';

    final _CacheEntry? cached = _cache[cacheKey];

    if (cached != null &&
        DateTime.now().difference(cached.createdAt) < cacheDuration) {
      debugPrint('Returning cached OSM charging stations.');
      return List<Map<String, dynamic>>.from(cached.data);
    }

    _cache.remove(cacheKey);

    final String query = '''
[out:json][timeout:12];
nwr["amenity"="charging_station"]
(around:${radiusMeters.toInt()},$latitude,$longitude);
out center tags;
''';

    debugPrint('Searching real OSM charging stations...');
    debugPrint('GPS: $latitude, $longitude');
    debugPrint('Radius: ${(radiusMeters / 1000).toStringAsFixed(1)} km');

    String lastError = 'No charging stations found in this area.';

    // Try servers individually to avoid sending three requests at once.
    for (final String server in _overpassServers) {
      try {
        debugPrint('Trying Overpass server: $server');

        final List<Map<String, dynamic>> result =
        await _requestFromServer(
          server: server,
          query: query,
          userLatitude: latitude,
          userLongitude: longitude,
        ).timeout(const Duration(seconds: 15));

        debugPrint('Server returned ${result.length} stations.');

        if (result.isNotEmpty) {
          result.sort((a, b) {
            final double distanceA =
                (a['distanceKm'] as num?)?.toDouble() ?? double.infinity;
            final double distanceB =
                (b['distanceKm'] as num?)?.toDouble() ?? double.infinity;
            return distanceA.compareTo(distanceB);
          });

          _cache[cacheKey] = _CacheEntry(
            data: List<Map<String, dynamic>>.from(result),
            createdAt: DateTime.now(),
          );

          debugPrint('Found ${result.length} real charging stations.');
          return result;
        }

        lastError = 'No charging stations were returned by $server.';
      } on TimeoutException {
        lastError = 'The charging station server timed out.';
        debugPrint('$server timed out. Trying the next server.');
      } catch (e) {
        lastError = e.toString().replaceFirst('Exception: ', '');
        debugPrint('$server failed: $lastError');
      }
    }

    throw Exception(
      'Unable to retrieve charging stations. '
          '$lastError Check your internet connection and try again.',
    );
  }

  Future<List<Map<String, dynamic>>> _requestFromServer({
    required String server,
    required String query,
    required double userLatitude,
    required double userLongitude,
  }) async {
    final http.Response response = await http
        .post(
      Uri.parse(server),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'AI-EV-Charging-Assistant/1.0',
      },
      body: {'data': query},
    )
        .timeout(const Duration(seconds: 13));

    debugPrint('$server returned HTTP ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Server returned HTTP ${response.statusCode}.');
    }

    if (response.body.isEmpty) {
      throw Exception('The charging station server returned an empty response.');
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid response from the charging station server.');
    }

    final dynamic rawElements = decoded['elements'];

    if (rawElements is! List) {
      throw Exception('The response did not contain station data.');
    }

    return _parseStations(
      rawElements,
      userLatitude,
      userLongitude,
    );
  }

  List<Map<String, dynamic>> _parseStations(
      List<dynamic> elements,
      double userLatitude,
      double userLongitude,
      ) {
    final List<Map<String, dynamic>> stations = [];
    final Set<String> seen = {};

    for (final dynamic element in elements) {
      if (element is! Map) continue;

      final Map<String, dynamic> item =
      Map<String, dynamic>.from(element);

      final Map<String, dynamic> tags = item['tags'] is Map
          ? Map<String, dynamic>.from(item['tags'])
          : <String, dynamic>{};

      double? stationLatitude;
      double? stationLongitude;

      if (item['lat'] is num && item['lon'] is num) {
        stationLatitude = (item['lat'] as num).toDouble();
        stationLongitude = (item['lon'] as num).toDouble();
      }

      final dynamic center = item['center'];

      if ((stationLatitude == null || stationLongitude == null) &&
          center is Map &&
          center['lat'] is num &&
          center['lon'] is num) {
        stationLatitude = (center['lat'] as num).toDouble();
        stationLongitude = (center['lon'] as num).toDouble();
      }

      if (stationLatitude == null || stationLongitude == null) continue;

      final String uniqueKey =
          '${stationLatitude.toStringAsFixed(5)}_'
          '${stationLongitude.toStringAsFixed(5)}';

      if (!seen.add(uniqueKey)) continue;

      final String name = _tagValue(tags, ['name'], 'EV Charging Station');
      final String operatorName = _tagValue(
        tags,
        ['operator', 'brand'],
        'EV Charging Network',
      );

      String charger = 'EV Charger';

      if (tags['socket:ccs2'] != null || tags['socket:ccs'] != null) {
        charger = 'CCS';
      } else if (tags['socket:chademo'] != null) {
        charger = 'CHAdeMO';
      } else if (tags['socket:type2'] != null) {
        charger = 'Type 2';
      } else if (tags['socket:type1'] != null) {
        charger = 'Type 1';
      }

      final String power = _tagValue(
        tags,
        ['charge:power', 'maxpower', 'capacity'],
        'Power not listed',
      );

      final List<String> addressParts = [];

      for (final String key in [
        'addr:housenumber',
        'addr:street',
        'addr:neighbourhood',
        'addr:suburb',
        'addr:city',
      ]) {
        final String value = tags[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) addressParts.add(value);
      }

      final double distanceMeters = Geolocator.distanceBetween(
        userLatitude,
        userLongitude,
        stationLatitude,
        stationLongitude,
      );

      final double qualityScore = _calculateQuality(tags);

      stations.add({
        'name': name,
        'operator': operatorName,
        'brand': tags['brand']?.toString() ?? '',
        'address': addressParts.isEmpty
            ? 'Address not listed in OpenStreetMap'
            : addressParts.join(', '),
        'city': tags['addr:city']?.toString() ?? '',
        'charger': charger,
        'power': power,
        'latitude': stationLatitude,
        'longitude': stationLongitude,
        'distanceKm': distanceMeters / 1000,
        'qualityScore': qualityScore,
        'recommendationScore': qualityScore,
        'operational': tags['operational']?.toString() ??
            tags['opening_hours']?.toString() ??
            'unknown',
        'isFallback': false,
        'source': 'OpenStreetMap',
      });
    }

    return stations;
  }

  String _tagValue(
      Map<String, dynamic> tags,
      List<String> keys,
      String fallback,
      ) {
    for (final String key in keys) {
      final String value = tags[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  double _calculateQuality(Map<String, dynamic> tags) {
    double score = 60;

    if (tags['operator'] != null) score += 10;
    if (tags['brand'] != null) score += 5;
    if (tags['capacity'] != null) score += 5;
    if (tags['charge:power'] != null || tags['maxpower'] != null) {
      score += 5;
    }
    if (tags['socket:type2'] != null ||
        tags['socket:ccs'] != null ||
        tags['socket:ccs2'] != null) {
      score += 5;
    }
    if (tags['opening_hours'] != null) score += 5;
    if (tags['access'] != null) score += 5;

    return score.clamp(0, 100).toDouble();
  }

  static void clearCache() {
    _cache.clear();
    debugPrint('EV station cache cleared.');
  }
}

class _CacheEntry {
  final List<Map<String, dynamic>> data;
  final DateTime createdAt;

  _CacheEntry({
    required this.data,
    required this.createdAt,
  });
}
