import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class ChargingStationService {
  static const String geoapifyApiKey =
      'a99d525b2e704f5c9256e35c0f3dc22e';

  static const String openChargeMapApiKey =
      'ea0cada6-67ad-4061-81f7-887c7f4bb1f2';

  static const double radiusKm = 10.0;

  Future<List<Map<String, dynamic>>> getNearbyStations({
    required double latitude,
    required double longitude,
  }) async {
    final results = await Future.wait([
      _geoapify(latitude, longitude),
      _openChargeMap(latitude, longitude),
    ]);

    final stations = <Map<String, dynamic>>[
      ...results[0],
      ...results[1],
    ];

    final unique = <Map<String, dynamic>>[];

    for (final station in stations) {
      final lat = _double(station['_latitude']);
      final lon = _double(station['_longitude']);

      if (lat == null || lon == null) {
        continue;
      }

      bool duplicate = false;

      for (final old in unique) {
        final oldLat = _double(old['_latitude']);
        final oldLon = _double(old['_longitude']);

        if (oldLat == null || oldLon == null) {
          continue;
        }

        if (_distanceKm(
          lat,
          lon,
          oldLat,
          oldLon,
        ) <
            0.08) {
          duplicate = true;
          break;
        }
      }

      if (!duplicate) {
        unique.add(station);
      }
    }

    unique.sort((a, b) {
      final da = _double(a['_distanceKm']) ?? 99999;
      final db = _double(b['_distanceKm']) ?? 99999;
      return da.compareTo(db);
    });

    return unique.take(50).toList();
  }

  Future<List<Map<String, dynamic>>> _geoapify(
      double latitude,
      double longitude,
      ) async {
    final url = Uri.parse(
      'https://api.geoapify.com/v2/places',
    ).replace(
      queryParameters: {
        'apiKey': geoapifyApiKey,
        'categories':
        'service.vehicle.charging_station',
        'filter':
        'circle:$longitude,$latitude,${radiusKm * 1000}',
        'bias':
        'proximity:$longitude,$latitude',
        'limit': '100',
        'lang': 'en',
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return [];
      }

      final json = jsonDecode(response.body);

      if (json is! Map<String, dynamic>) {
        return [];
      }

      final features = json['features'];

      if (features is! List) {
        return [];
      }

      final stations = <Map<String, dynamic>>[];

      for (final feature in features) {
        if (feature is! Map<String, dynamic>) {
          continue;
        }

        final properties = feature['properties'];

        if (properties is! Map<String, dynamic>) {
          continue;
        }

        final lat = _double(properties['lat']);
        final lon = _double(properties['lon']);

        if (lat == null || lon == null) {
          continue;
        }

        final distance = _distanceKm(
          latitude,
          longitude,
          lat,
          lon,
        );

        if (distance > radiusKm) {
          continue;
        }

        String name =
        _string(properties['name']);

        if (name.isEmpty) {
          name =
              _string(
                properties['address_line1'],
              );
        }

        if (name.isEmpty) {
          name = 'EV Charging Station';
        }

        String address =
        _string(
          properties['formatted'],
        );

        if (address.isEmpty) {
          address =
              _string(
                properties['address_line1'],
              );
        }

        String operator =
        _string(
          properties['operator'],
        );

        if (operator.isEmpty) {
          operator =
              _string(
                properties['brand'],
              );
        }

        if (operator.isEmpty) {
          operator =
              _string(
                properties['network'],
              );
        }

        final charger =
        _geoCharger(properties);

        final power =
        _geoPower(properties);

        bool operational = true;

        if (properties['operational'] == false ||
            properties['operational'] == 'no' ||
            properties['operational'] == 'closed') {
          operational = false;
        }

        stations.add({
          'AddressInfo': {
            'Title': name,
            'AddressLine1': address,
            'Town': _string(properties['city']),
            'StateOrProvince':
            _string(properties['state']),
            'Latitude': lat,
            'Longitude': lon,
          },
          'StatusType': {
            'IsOperational': operational,
          },
          '_distanceKm': distance,
          '_qualityScore':
          _quality(
            operator,
            charger,
            power,
            distance,
          ),
          '_chargerName': charger,
          '_powerKW': power,
          '_operatorName': operator,
          '_address': address,
          '_town':
          _string(properties['city']),
          '_state':
          _string(properties['state']),
          '_latitude': lat,
          '_longitude': lon,
          '_isOperational': operational,
          '_capacity':
          _int(properties['capacity']),
          '_openingHours':
          _string(
            properties['opening_hours'],
          ),
          '_placeId':
          _string(properties['place_id']),
          '_source': 'Geoapify',
        });
      }

      return stations;
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _openChargeMap(
      double latitude,
      double longitude,
      ) async {
    final url = Uri.parse(
      'https://api.openchargemap.io/v3/poi/',
    ).replace(
      queryParameters: {
        'output': 'json',
        'countrycode': 'IN',
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'distance': radiusKm.toString(),
        'distanceunit': 'KM',
        'maxresults': '100',
        'compact': 'false',
        'verbose': 'false',
        'key': openChargeMapApiKey,
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return [];
      }

      final json = jsonDecode(response.body);

      if (json is! List) {
        return [];
      }

      final stations = <Map<String, dynamic>>[];

      for (final item in json) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final addressInfo = item['AddressInfo'];

        if (addressInfo is! Map<String, dynamic>) {
          continue;
        }

        final lat =
        _double(addressInfo['Latitude']);

        final lon =
        _double(addressInfo['Longitude']);

        if (lat == null || lon == null) {
          continue;
        }

        final distance = _distanceKm(
          latitude,
          longitude,
          lat,
          lon,
        );

        if (distance > radiusKm) {
          continue;
        }

        final name =
        _string(
          addressInfo['Title'],
        ).isEmpty
            ? 'EV Charging Station'
            : _string(
          addressInfo['Title'],
        );

        final address =
        _ocmAddress(addressInfo);

        final charger =
        _ocmCharger(item);

        final power =
        _ocmPower(item);

        bool operational = true;

        final status = item['StatusType'];

        if (status is Map<String, dynamic>) {
          if (status['IsOperational'] == false) {
            operational = false;
          }
        }

        String operator = '';

        final operatorInfo =
        item['OperatorInfo'];

        if (operatorInfo
        is Map<String, dynamic>) {
          operator =
              _string(
                operatorInfo['Title'],
              );
        }

        stations.add({
          'AddressInfo': {
            'Title': name,
            'AddressLine1': address,
            'Town':
            _string(
              addressInfo['Town'],
            ),
            'StateOrProvince':
            _string(
              addressInfo['StateOrProvince'],
            ),
            'Latitude': lat,
            'Longitude': lon,
          },
          'StatusType': {
            'IsOperational': operational,
          },
          '_distanceKm': distance,
          '_qualityScore':
          _quality(
            operator,
            charger,
            power,
            distance,
          ),
          '_chargerName': charger,
          '_powerKW': power,
          '_operatorName': operator,
          '_address': address,
          '_town':
          _string(
            addressInfo['Town'],
          ),
          '_state':
          _string(
            addressInfo['StateOrProvince'],
          ),
          '_latitude': lat,
          '_longitude': lon,
          '_isOperational': operational,
          '_capacity':
          _int(item['NumberOfPoints']),
          '_openingHours': '',
          '_placeId':
          _string(item['ID']),
          '_source': 'OpenChargeMap',
        });
      }

      return stations;
    } catch (_) {
      return [];
    }
  }

  String _geoCharger(
      Map<String, dynamic> p,
      ) {
    final chargers = <String>[];

    final datasource = p['datasource'];

    if (datasource is Map<String, dynamic>) {
      final raw = datasource['raw'];

      if (raw is Map<String, dynamic>) {
        _connector(
          chargers,
          raw['socket:type2_combo'],
          'CCS / Type 2 Combo',
        );

        _connector(
          chargers,
          raw['socket:type2'],
          'Type 2',
        );

        _connector(
          chargers,
          raw['socket:chademo'],
          'CHAdeMO',
        );

        _connector(
          chargers,
          raw['socket:type1'],
          'Type 1',
        );
      }
    }

    if (chargers.isEmpty) {
      return 'EV Charger';
    }

    return chargers.join(' + ');
  }

  void _connector(
      List<String> list,
      dynamic value,
      String name,
      ) {
    if (value == null) {
      return;
    }

    final text = value.toString();

    if (text.isEmpty ||
        text == '0' ||
        text == 'false' ||
        text == 'no') {
      return;
    }

    if (!list.contains(name)) {
      list.add(name);
    }
  }

  double? _geoPower(
      Map<String, dynamic> p,
      ) {
    final values = [
      p['charging_output'],
      p['power'],
      p['power_kw'],
      p['capacity_kw'],
      p['max_power'],
    ];

    for (final value in values) {
      final number = _power(value);

      if (number != null && number > 0) {
        return number;
      }
    }

    final datasource = p['datasource'];

    if (datasource is Map<String, dynamic>) {
      final raw = datasource['raw'];

      if (raw is Map<String, dynamic>) {
        final values = [
          raw['charging_output'],
          raw['power'],
          raw['power_kw'],
          raw['capacity_kw'],
          raw['max_power'],
        ];

        for (final value in values) {
          final number = _power(value);

          if (number != null && number > 0) {
            return number;
          }
        }
      }
    }

    return null;
  }

  double? _power(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final match = RegExp(
      r'(\d+(?:\.\d+)?)',
    ).firstMatch(
      value.toString(),
    );

    if (match == null) {
      return null;
    }

    return double.tryParse(
      match.group(1)!,
    );
  }

  String _ocmCharger(
      Map<String, dynamic> item,
      ) {
    final connections =
    item['Connections'];

    if (connections is! List) {
      return 'EV Charger';
    }

    final names = <String>[];

    for (final connection in connections) {
      if (connection
      is! Map<String, dynamic>) {
        continue;
      }

      final type =
      connection['ConnectionType'];

      if (type is Map<String, dynamic>) {
        final name =
        _string(type['Title']);

        if (name.isNotEmpty &&
            !names.contains(name)) {
          names.add(name);
        }
      }

      final level =
      connection['Level'];

      if (level is Map<String, dynamic>) {
        final name =
        _string(level['Title']);

        if (name.isNotEmpty &&
            !names.contains(name)) {
          names.add(name);
        }
      }
    }

    if (names.isEmpty) {
      return 'EV Charger';
    }

    return names.join(' + ');
  }

  double? _ocmPower(
      Map<String, dynamic> item,
      ) {
    final connections =
    item['Connections'];

    if (connections is! List) {
      return null;
    }

    double? highest;

    for (final connection in connections) {
      if (connection
      is! Map<String, dynamic>) {
        continue;
      }

      final power =
      _double(
        connection['PowerKW'],
      );

      if (power != null &&
          (highest == null ||
              power > highest)) {
        highest = power;
      }
    }

    return highest;
  }

  String _ocmAddress(
      Map<String, dynamic> info,
      ) {
    final parts = <String>[];

    void add(dynamic value) {
      final text = _string(value);

      if (text.isNotEmpty &&
          !parts.contains(text)) {
        parts.add(text);
      }
    }

    add(info['AddressLine1']);
    add(info['AddressLine2']);
    add(info['Town']);
    add(info['StateOrProvince']);
    add(info['Postcode']);

    return parts.join(', ');
  }

  int _quality(
      String operator,
      String charger,
      double? power,
      double distance,
      ) {
    int score = 50;

    if (operator.isNotEmpty) {
      score += 15;
    }

    if (charger != 'EV Charger') {
      score += 10;
    }

    if (power != null && power > 0) {
      score += 10;
    }

    if (distance <= 1) {
      score += 20;
    } else if (distance <= 2) {
      score += 15;
    } else if (distance <= 5) {
      score += 10;
    }

    return min(score, 100);
  }

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  double? _double(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  int? _int(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  double _distanceKm(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const earthRadius = 6371.0;

    final dLat =
        (lat2 - lat1) * pi / 180;

    final dLon =
        (lon2 - lon1) * pi / 180;

    final a =
        sin(dLat / 2) *
            sin(dLat / 2) +
            cos(lat1 * pi / 180) *
                cos(lat2 * pi / 180) *
                sin(dLon / 2) *
                sin(dLon / 2);

    final c =
        2 *
            atan2(
              sqrt(a),
              sqrt(1 - a),
            );

    return earthRadius * c;
  }
}