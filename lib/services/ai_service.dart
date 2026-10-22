import '../models/ai_prediction_model.dart';
import '../ai/prediction_engine.dart';

class AIService {
  final PredictionEngine engine =
  PredictionEngine();

  // ============================================================
  // GET AI PREDICTION
  // ============================================================

  AIPredictionModel getPrediction({
    int battery = 78,
    double capacity = 40.5,
    String chargerType = 'Fast Charging',

    // Previous PostgreSQL charging sessions.
    List<dynamic> chargingHistory = const [],
  }) {
    // ============================================================
    // HISTORY ANALYSIS
    // ============================================================

    final int historyCount =
        chargingHistory.length;

    double totalHistoricalEnergy = 0;
    double totalHistoricalCost = 0;
    int totalHistoricalTime = 0;

    for (final dynamic session
    in chargingHistory) {
      if (session is! Map) {
        continue;
      }

      final double energy =
          double.tryParse(
            session['energy_used']
                ?.toString() ??
                '0',
          ) ??
              0;

      final double cost =
          double.tryParse(
            session['cost']
                ?.toString() ??
                '0',
          ) ??
              0;

      final int time =
          int.tryParse(
            session['charging_time']
                ?.toString() ??
                '0',
          ) ??
              0;

      if (energy > 0) {
        totalHistoricalEnergy += energy;
      }

      if (cost > 0) {
        totalHistoricalCost += cost;
      }

      if (time > 0) {
        totalHistoricalTime += time;
      }
    }

    // ============================================================
    // HISTORICAL AVERAGES
    // ============================================================

    double? averageHistoricalEnergy;
    double? averageHistoricalCost;
    double? averageHistoricalTime;
    double? historicalCostPerKwh;

    if (historyCount > 0) {
      if (totalHistoricalEnergy > 0) {
        averageHistoricalEnergy =
            totalHistoricalEnergy /
                historyCount;
      }

      if (totalHistoricalCost > 0) {
        averageHistoricalCost =
            totalHistoricalCost /
                historyCount;
      }

      if (totalHistoricalTime > 0) {
        averageHistoricalTime =
            totalHistoricalTime /
                historyCount;
      }

      if (totalHistoricalEnergy > 0 &&
          totalHistoricalCost > 0) {
        historicalCostPerKwh =
            totalHistoricalCost /
                totalHistoricalEnergy;
      }
    }

    // ============================================================
    // AI CHARGING TIME
    // ============================================================

    final int chargingTime =
    engine.predictChargingTime(
      currentBattery: battery,
      batteryCapacity: capacity,
      chargerType: chargerType,
      historicalAverageMinutesPerSession:
      averageHistoricalTime,
      historicalAverageEnergy:
      averageHistoricalEnergy,
    );

    // ============================================================
    // AI CHARGING COST
    // ============================================================

    final double cost =
    engine.predictChargingCost(
      batteryCapacity: capacity,
      currentBattery: battery,
      historicalAverageCostPerKwh:
      historicalCostPerKwh,
    );

    // ============================================================
    // SMART STATION RECOMMENDATION
    // ============================================================

    final Map<String, dynamic> station =
    engine.recommendBestStation(
      battery: battery,
      chargerType: chargerType,
      chargingHistory: chargingHistory,
    );

    final String recommendedStation =
        station['name']?.toString() ??
            'No station available';

    final double stationLatitude =
        (station['latitude'] as num?)
            ?.toDouble() ??
            0.0;

    final double stationLongitude =
        (station['longitude'] as num?)
            ?.toDouble() ??
            0.0;

    final double stationDistance =
        (station['distance'] as num?)
            ?.toDouble() ??
            0.0;

    final String recommendedChargerType =
        station['chargerType']?.toString() ??
            chargerType;

    final bool stationAvailable =
        station['available'] == true;

    final double stationScore =
        (station['score'] as num?)
            ?.toDouble() ??
            0.0;

    final String recommendationReason =
        station['reason']?.toString() ??
            'Recommended based on your current charging requirements.';

    // ============================================================
    // AI CONFIDENCE
    // ============================================================

    double confidence =
    engine.calculateConfidence(
      battery: battery,
      historyCount: historyCount,
      chargerType: chargerType,
    );

    // Smart station selection gives the prediction
    // a small additional confidence boost.
    if (stationScore >= 80) {
      confidence += 2;
    } else if (stationScore >= 60) {
      confidence += 1;
    }

    if (confidence > 98) {
      confidence = 98;
    }

    // ============================================================
    // RETURN AI RESULT
    // ============================================================

    return AIPredictionModel(
      estimatedTime: chargingTime,
      estimatedCost: cost,

      recommendedStation:
      recommendedStation,

      stationLatitude:
      stationLatitude,

      stationLongitude:
      stationLongitude,

      confidenceScore:
      confidence,

      historyCount:
      historyCount,

      usedChargingHistory:
      historyCount > 0,

      stationDistance:
      stationDistance,

      recommendedChargerType:
      recommendedChargerType,

      stationAvailable:
      stationAvailable,

      stationScore:
      stationScore,

      recommendationReason:
      recommendationReason,
    );
  }
}