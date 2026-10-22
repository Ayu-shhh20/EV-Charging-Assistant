class AIPredictionModel {
  final int estimatedTime;
  final double estimatedCost;

  final String recommendedStation;

  final double stationLatitude;
  final double stationLongitude;

  final double confidenceScore;

  // Number of previous charging sessions
  // used by the AI prediction.
  final int historyCount;

  // Whether historical charging data was
  // available for this prediction.
  final bool usedChargingHistory;

  // ============================================================
  // SMART STATION INFORMATION
  // ============================================================

  // Distance of the recommended station in kilometers.
  final double stationDistance;

  // Charger type available at the recommended station.
  final String recommendedChargerType;

  // Whether the recommended station is currently available.
  final bool stationAvailable;

  // AI score calculated for the recommended station.
  final double stationScore;

  // Short explanation of why the station was recommended.
  final String recommendationReason;

  AIPredictionModel({
    required this.estimatedTime,
    required this.estimatedCost,
    required this.recommendedStation,
    required this.stationLatitude,
    required this.stationLongitude,
    required this.confidenceScore,
    this.historyCount = 0,
    this.usedChargingHistory = false,

    // Smart station defaults.
    this.stationDistance = 0,
    this.recommendedChargerType = 'Fast Charging',
    this.stationAvailable = true,
    this.stationScore = 0,
    this.recommendationReason =
    'Recommended based on your current charging requirements.',
  });
}