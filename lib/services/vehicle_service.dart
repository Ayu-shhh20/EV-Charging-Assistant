import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle_model.dart';

class VehicleService {
  static VehicleModel? _vehicle;

  static const String _userIdKey = 'user_id';
  static const String _vehicleIdKey = 'vehicle_id';
  static const String _userNameKey = 'user_name';
  static const String _vehicleNameKey = 'vehicle_name';
  static const String _batteryCapacityKey = 'battery_capacity';
  static const String _currentBatteryKey = 'current_battery';
  static const String _rangeKey = 'range';
  static const String _chargingTypeKey = 'charging_type';

  // ---------------------------------------------------------
  // INITIALIZE LOCAL VEHICLE DATA
  // ---------------------------------------------------------

  static Future<void> initialize() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    final int? userId =
    prefs.getInt(_userIdKey);

    final int? vehicleId =
    prefs.getInt(_vehicleIdKey);

    final String userName =
        prefs.getString(_userNameKey) ?? '';

    final String vehicleName =
        prefs.getString(_vehicleNameKey) ?? '';

    final double batteryCapacity =
        prefs.getDouble(_batteryCapacityKey) ?? 40.5;

    final int currentBattery =
        prefs.getInt(_currentBatteryKey) ?? 80;

    final int range =
        prefs.getInt(_rangeKey) ?? 280;

    final String chargingType =
        prefs.getString(_chargingTypeKey) ??
            'Fast Charging';

    _vehicle = VehicleModel(
      userId: userId,
      vehicleId: vehicleId,
      userName: userName,
      vehicleName: vehicleName,
      batteryCapacity: batteryCapacity,
      currentBattery: currentBattery,
      range: range,
      chargingType: chargingType,
    );
  }

  // ---------------------------------------------------------
  // GET VEHICLE DATA
  // ---------------------------------------------------------

  static VehicleModel getVehicleData() {
    return _vehicle ??
        VehicleModel(
          userId: null,
          vehicleId: null,
          userName: '',
          vehicleName: '',
          batteryCapacity: 40.5,
          currentBattery: 80,
          range: 280,
          chargingType: 'Fast Charging',
        );
  }

  // ---------------------------------------------------------
  // SAVE VEHICLE DATA
  // IMPORTANT: Future<void>, NOT void
  // ---------------------------------------------------------

  static Future<void> saveVehicleData({
    int? userId,
    int? vehicleId,
    required String userName,
    required String vehicleName,
    required double batteryCapacity,
    required int currentBattery,
    required String chargingType,
  }) async {
    // Calculate estimated range
    final int estimatedRange =
    (batteryCapacity *
        currentBattery /
        100 *
        7)
        .round();

    // Update in-memory vehicle
    _vehicle = VehicleModel(
      userId: userId,
      vehicleId: vehicleId,
      userName: userName,
      vehicleName: vehicleName,
      batteryCapacity: batteryCapacity,
      currentBattery: currentBattery,
      range: estimatedRange,
      chargingType: chargingType,
    );

    // Get SharedPreferences
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    // Save IDs if available
    if (userId != null) {
      await prefs.setInt(
        _userIdKey,
        userId,
      );
    }

    if (vehicleId != null) {
      await prefs.setInt(
        _vehicleIdKey,
        vehicleId,
      );
    }

    // Save vehicle information
    await prefs.setString(
      _userNameKey,
      userName,
    );

    await prefs.setString(
      _vehicleNameKey,
      vehicleName,
    );

    await prefs.setDouble(
      _batteryCapacityKey,
      batteryCapacity,
    );

    await prefs.setInt(
      _currentBatteryKey,
      currentBattery,
    );

    await prefs.setInt(
      _rangeKey,
      estimatedRange,
    );

    await prefs.setString(
      _chargingTypeKey,
      chargingType,
    );
  }

  // ---------------------------------------------------------
  // GET USER ID
  // ---------------------------------------------------------

  static int? getUserId() {
    return _vehicle?.userId;
  }

  // ---------------------------------------------------------
  // GET VEHICLE ID
  // ---------------------------------------------------------

  static int? getVehicleId() {
    return _vehicle?.vehicleId;
  }

  // ---------------------------------------------------------
  // CLEAR LOCAL VEHICLE DATA
  // ---------------------------------------------------------

  static Future<void> clearVehicleData() async {
    _vehicle = null;

    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(_userIdKey);
    await prefs.remove(_vehicleIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_vehicleNameKey);
    await prefs.remove(_batteryCapacityKey);
    await prefs.remove(_currentBatteryKey);
    await prefs.remove(_rangeKey);
    await prefs.remove(_chargingTypeKey);
  }
}