import '../models/charging_model.dart';
import 'firebase_service.dart';

class ChargingService {
  // =========================================================
  // LOCAL SESSION CACHE
  // =========================================================

  static final List<ChargingModel> _sessions = [];

  // =========================================================
  // GET CURRENT SESSIONS
  // =========================================================

  static List<ChargingModel> getChargingSessions() {
    return List.unmodifiable(_sessions);
  }

  // =========================================================
  // LOAD SESSIONS FROM FIREBASE
  // =========================================================

  static Future<List<ChargingModel>>
  loadChargingSessions() async {
    final List<ChargingModel> sessions =
    await FirebaseService.getChargingSessions();

    _sessions
      ..clear()
      ..addAll(sessions);

    return List.unmodifiable(_sessions);
  }

  // =========================================================
  // ADD LOCAL SESSION
  // =========================================================

  static void addChargingSession({
    required String stationName,
    required String chargerType,
    required double energyUsed,
    required int chargingTime,
    required double cost,
    required int startBattery,
    required int endBattery,
    bool completed = true,
    DateTime? dateTime,
  }) {
    _sessions.add(
      ChargingModel(
        stationName: stationName,
        chargerType: chargerType,
        energyUsed: energyUsed,
        chargingTime: chargingTime,
        cost: cost,
        startBattery: startBattery,
        endBattery: endBattery,
        completed: completed,
        dateTime: dateTime,
      ),
    );
  }

  // =========================================================
  // SAVE SESSION TO FIREBASE
  //
  // RETURNS Map<String, dynamic> TO KEEP COMPATIBILITY
  // WITH YOUR EXISTING CHARGING SCREEN.
  // =========================================================

  static Future<Map<String, dynamic>>
  saveSessionToDatabase({
    String? stationName,
    String? chargerType,
    int? userId,
    int? vehicleId,
    required double energyUsed,
    required int chargingTime,
    required double cost,
    required int startBattery,
    required int endBattery,
    bool completed = true,
  }) async {
    final String sessionId =
    await FirebaseService.saveChargingSession(
      stationName:
      stationName ?? 'AI EV Charging Station',
      chargerType:
      chargerType ?? 'Fast Charging',
      energyUsed: energyUsed,
      chargingTime: chargingTime,
      cost: cost,
      startBattery: startBattery,
      endBattery: endBattery,
      completed: completed,
    );

    // Add to local cache only after Firebase succeeds.
    addChargingSession(
      stationName:
      stationName ?? 'AI EV Charging Station',
      chargerType:
      chargerType ?? 'Fast Charging',
      energyUsed: energyUsed,
      chargingTime: chargingTime,
      cost: cost,
      startBattery: startBattery,
      endBattery: endBattery,
      completed: completed,
    );

    // Return the same type/structure expected
    // by the existing ChargingScreen.
    return {
      'success': true,
      'session_id': sessionId,
      'message':
      'Charging session saved successfully.',
    };
  }

  // =========================================================
  // REFRESH SESSIONS
  // =========================================================

  static Future<void> refreshSessions() async {
    await loadChargingSessions();
  }

  // =========================================================
  // TOTAL ENERGY
  // =========================================================

  static double getTotalEnergy() {
    return _sessions.fold(
      0,
          (sum, session) =>
      sum + session.energyUsed,
    );
  }

  // =========================================================
  // TOTAL COST
  // =========================================================

  static double getTotalCost() {
    return _sessions.fold(
      0,
          (sum, session) =>
      sum + session.cost,
    );
  }

  // =========================================================
  // SESSION COUNT
  // =========================================================

  static int getSessionCount() {
    return _sessions.length;
  }

  // =========================================================
  // TOTAL CHARGING TIME
  // =========================================================

  static int getTotalChargingTime() {
    return _sessions.fold(
      0,
          (sum, session) =>
      sum + session.chargingTime,
    );
  }

  // =========================================================
  // AVERAGE ENERGY
  // =========================================================

  static double getAverageEnergy() {
    if (_sessions.isEmpty) {
      return 0;
    }

    return getTotalEnergy() /
        _sessions.length;
  }

  // =========================================================
  // AVERAGE COST
  // =========================================================

  static double getAverageCost() {
    if (_sessions.isEmpty) {
      return 0;
    }

    return getTotalCost() /
        _sessions.length;
  }

  // =========================================================
  // CLEAR LOCAL CACHE
  // =========================================================

  static void clearLocalSessions() {
    _sessions.clear();
  }
}