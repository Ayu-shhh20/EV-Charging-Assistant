import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ==========================================
  // BACKEND URL
  // ==========================================

  // Android Emulator:
  // 10.0.2.2 points to your Windows localhost.

  static const String baseUrl =
      'http://192.168.1.39:8080/AIEVBackend/api';

  // If you run Flutter on the same Windows PC
  // instead of Android Emulator, use:
  //
  // static const String baseUrl =
  //     'http://localhost:8080/AIEVBackend/api';

  // ==========================================
  // USERS
  // ==========================================

  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to fetch users: ${response.statusCode}',
    );
  }

  static Future<Map<String, dynamic>> createUser(
      String userName,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_name': userName,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to create user: '
          '${response.statusCode} ${response.body}',
    );
  }

  // ==========================================
  // VEHICLES
  // ==========================================

  static Future<List<dynamic>> getVehicles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to fetch vehicles: ${response.statusCode}',
    );
  }

  static Future<Map<String, dynamic>> createVehicle({
    required int userId,
    required String vehicleName,
    required double batteryCapacity,
    required int currentBattery,
    required String chargingType,
    int? estimatedRange,
  }) async {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'vehicle_name': vehicleName,
      'battery_capacity': batteryCapacity,
      'current_battery': currentBattery,
      'charging_type': chargingType,
    };

    if (estimatedRange != null) {
      data['estimated_range'] = estimatedRange;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/vehicles'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to create vehicle: '
          '${response.statusCode} ${response.body}',
    );
  }

  // ==========================================
  // CHARGING SESSIONS
  // ==========================================

  static Future<List<dynamic>>
  getChargingSessions() async {

    final response = await http.get(
      Uri.parse('$baseUrl/charging-sessions'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to fetch charging sessions: '
          '${response.statusCode}',
    );
  }

  static Future<Map<String, dynamic>>
  createChargingSession({
    required int userId,
    required int vehicleId,
    int? stationId,
    required int startBattery,
    required int endBattery,
    required double energyUsed,
    required int chargingTime,
    required double cost,
    bool completed = true,
  }) async {

    final Map<String, dynamic> data = {
      'user_id': userId,
      'vehicle_id': vehicleId,
      'start_battery': startBattery,
      'end_battery': endBattery,
      'energy_used': energyUsed,
      'charging_time': chargingTime,
      'cost': cost,
      'completed': completed,
    };

    if (stationId != null) {
      data['station_id'] = stationId;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/charging-sessions'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to create charging session: '
          '${response.statusCode} ${response.body}',
    );
  }
}