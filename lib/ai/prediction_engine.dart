class PredictionEngine {
  // ============================================================
  // CHARGING TIME
  // ============================================================

  int predictChargingTime({
    required int currentBattery,
    required double batteryCapacity,
    required String chargerType,
    double? historicalAverageMinutesPerSession,
    double? historicalAverageEnergy,
  }) {
    final int safeBattery =
    currentBattery.clamp(0, 100);

    if (safeBattery >= 100) {
      return 0;
    }

    double chargingPower;

    if (chargerType == 'Fast Charging') {
      chargingPower = 50.0;
    } else if (chargerType == 'Slow Charging') {
      chargingPower = 7.0;
    } else {
      chargingPower = 22.0;
    }

    final double requiredEnergy =
        batteryCapacity *
            (100 - safeBattery) /
            100;

    if (requiredEnergy <= 0) {
      return 0;
    }

    final double actualEnergyRequired =
        requiredEnergy * 1.10;

    final double theoreticalHours =
        actualEnergyRequired /
            chargingPower;

    int predictedMinutes =
    (theoreticalHours * 60).round();

    // Historical adjustment.
    if (historicalAverageMinutesPerSession != null &&
        historicalAverageMinutesPerSession > 0 &&
        historicalAverageEnergy != null &&
        historicalAverageEnergy > 0) {
      final double historicalMinutesPerKwh =
          historicalAverageMinutesPerSession /
              historicalAverageEnergy;

      final double historicalPrediction =
          actualEnergyRequired *
              historicalMinutesPerKwh;

      predictedMinutes =
          ((predictedMinutes * 0.75) +
              (historicalPrediction * 0.25))
              .round();
    }

    if (predictedMinutes < 1) {
      predictedMinutes = 1;
    }

    return predictedMinutes;
  }

  // ============================================================
  // CHARGING COST
  // ============================================================

  double predictChargingCost({
    required double batteryCapacity,
    required int currentBattery,
    double electricityRate = 8.0,
    double? historicalAverageCostPerKwh,
  }) {
    final int safeBattery =
    currentBattery.clamp(0, 100);

    if (safeBattery >= 100) {
      return 0;
    }

    final double requiredEnergy =
        batteryCapacity *
            (100 - safeBattery) /
            100;

    if (requiredEnergy <= 0) {
      return 0;
    }

    final double actualEnergyRequired =
        requiredEnergy * 1.10;

    double rate = electricityRate;

    if (historicalAverageCostPerKwh != null &&
        historicalAverageCostPerKwh > 0) {
      rate =
          (electricityRate * 0.70) +
              (historicalAverageCostPerKwh * 0.30);
    }

    return actualEnergyRequired * rate;
  }

  // ============================================================
  // SMART STATION DATA
  // ============================================================

  List<Map<String, dynamic>> getStationData({
    required int battery,
    required String chargerType,
  }) {
    /*
     * These are currently predefined project stations.
     *
     * Later these can be replaced with live station data
     * from a database/API without changing the AI structure.
     */

    return [
      {
        'name': 'Tata Power EV Charging Station',
        'latitude': 19.13482,
        'longitude': 72.83745,
        'distance': 2.0,
        'chargerType': 'Fast Charging',
        'available': true,
        'costPerKwh': 8.0,
      },
      {
        'name': 'Jio-bp Pulse EV Charging Station',
        'latitude': 19.12670,
        'longitude': 72.84620,
        'distance': 3.5,
        'chargerType': 'Fast Charging',
        'available': true,
        'costPerKwh': 8.5,
      },
      {
        'name': 'Statiq EV Charging Station',
        'latitude': 19.14120,
        'longitude': 72.82980,
        'distance': 4.2,
        'chargerType': 'Fast Charging',
        'available': true,
        'costPerKwh': 8.2,
      },
      {
        'name': 'ChargeZone EV Charging Station',
        'latitude': 19.11950,
        'longitude': 72.85510,
        'distance': 5.8,
        'chargerType': 'Fast Charging',
        'available': true,
        'costPerKwh': 7.8,
      },
    ];
  }

  // ============================================================
  // SMART STATION SCORE
  // ============================================================

  double calculateStationScore({
    required double distance,
    required bool available,
    required String stationChargerType,
    required String userChargerType,
    required int battery,
    required double stationCostPerKwh,
    required bool previouslyUsed,
  }) {
    double score = 0;

    // ------------------------------------------------------------
    // AVAILABILITY
    // ------------------------------------------------------------

    if (available) {
      score += 30;
    } else {
      return 0;
    }

    // ------------------------------------------------------------
    // DISTANCE
    // ------------------------------------------------------------

    if (distance <= 2) {
      score += 30;
    } else if (distance <= 3) {
      score += 26;
    } else if (distance <= 5) {
      score += 20;
    } else if (distance <= 7) {
      score += 12;
    } else {
      score += 5;
    }

    // ------------------------------------------------------------
    // CHARGER COMPATIBILITY
    // ------------------------------------------------------------

    if (stationChargerType == userChargerType) {
      score += 20;
    } else {
      score += 8;
    }

    // ------------------------------------------------------------
    // BATTERY PRIORITY
    // ------------------------------------------------------------

    if (battery <= 20) {
      // Very low battery means distance becomes critical.
      if (distance <= 3) {
        score += 15;
      } else {
        score += 5;
      }
    } else if (battery <= 50) {
      // Medium battery balances distance and charger type.
      if (stationChargerType == userChargerType) {
        score += 12;
      } else {
        score += 6;
      }
    } else {
      // Higher battery gives the user more flexibility.
      score += 8;
    }

    // ------------------------------------------------------------
    // COST
    // ------------------------------------------------------------

    if (stationCostPerKwh <= 8.0) {
      score += 5;
    } else if (stationCostPerKwh <= 8.5) {
      score += 3;
    } else {
      score += 1;
    }

    // ------------------------------------------------------------
    // USER HISTORY
    // ------------------------------------------------------------

    // Give a small preference to stations previously used by
    // the same user.
    if (previouslyUsed) {
      score += 5;
    }

    if (score > 100) {
      score = 100;
    }

    return score;
  }

  // ============================================================
  // SMART STATION RECOMMENDATION
  // ============================================================

  Map<String, dynamic> recommendBestStation({
    required int battery,
    required String chargerType,
    List<dynamic> chargingHistory = const [],
  }) {
    final List<Map<String, dynamic>> stations =
    getStationData(
      battery: battery,
      chargerType: chargerType,
    );

    Map<String, dynamic>? bestStation;

    double bestScore = -1;

    for (final station in stations) {
      final String stationName =
      station['name'].toString();

      final bool previouslyUsed =
      chargingHistory.any(
            (session) {
          if (session is! Map) {
            return false;
          }

          final String sessionStation =
              session['station_name']
                  ?.toString() ??
                  '';

          return sessionStation
              .toLowerCase()
              .trim() ==
              stationName
                  .toLowerCase()
                  .trim();
        },
      );

      final double score =
      calculateStationScore(
        distance:
        (station['distance'] as num)
            .toDouble(),
        available:
        station['available'] == true,
        stationChargerType:
        station['chargerType'].toString(),
        userChargerType:
        chargerType,
        battery:
        battery,
        stationCostPerKwh:
        (station['costPerKwh'] as num)
            .toDouble(),
        previouslyUsed:
        previouslyUsed,
      );

      station['score'] = score;

      if (bestStation == null ||
          score > bestScore) {
        bestStation = station;
        bestScore = score;
      }
    }

    if (bestStation == null) {
      return {
        'name': 'No station available',
        'latitude': 0.0,
        'longitude': 0.0,
        'distance': 0.0,
        'chargerType': chargerType,
        'available': false,
        'costPerKwh': 0.0,
        'score': 0.0,
        'reason': 'No charging station is currently available.',
      };
    }

    String reason;

    final double selectedDistance =
    (bestStation['distance'] as num)
        .toDouble();

    final String selectedCharger =
    bestStation['chargerType'].toString();

    final bool selectedAvailable =
        bestStation['available'] == true;

    final bool selectedPreviouslyUsed =
    chargingHistory.any(
          (session) {
        if (session is! Map) {
          return false;
        }

        final String sessionStation =
            session['station_name']
                ?.toString() ??
                '';

        return sessionStation
            .toLowerCase()
            .trim() ==
            bestStation!['name']
                .toString()
                .toLowerCase()
                .trim();
      },
    );

    if (battery <= 20) {
      reason =
      'Selected because your battery is low and the station is relatively close.';
    } else if (selectedPreviouslyUsed) {
      reason =
      'Selected using your previous charging history and station compatibility.';
    } else if (selectedDistance <= 3) {
      reason =
      'Selected because it provides a nearby charging option compatible with your requirements.';
    } else if (selectedCharger == chargerType) {
      reason =
      'Selected because the charger type matches your vehicle charging preference.';
    } else if (!selectedAvailable) {
      reason =
      'No fully suitable station was available.';
    } else {
      reason =
      'Selected using distance, availability, charger compatibility, and cost.';
    }

    bestStation['reason'] = reason;

    return bestStation;
  }

  // ============================================================
  // OLD RECOMMENDATION METHOD
  // ============================================================
  //
  // Kept so existing code does not break.
  //
  // ============================================================

  String recommendCharger({
    required double distance,
    required bool available,
    required int battery,
    String chargerType = 'Fast Charging',
  }) {
    if (!available) {
      return 'No station available';
    }

    if (battery <= 20) {
      return 'Tata Power EV Charging Station';
    }

    if (battery <= 50) {
      return 'Jio-bp Pulse EV Charging Station';
    }

    if (distance < 5) {
      return 'Statiq EV Charging Station';
    }

    return 'ChargeZone EV Charging Station';
  }

  // ============================================================
  // AI CONFIDENCE
  // ============================================================

  double calculateConfidence({
    required int battery,
    required int historyCount,
    required String chargerType,
  }) {
    double confidence;

    if (battery <= 20) {
      confidence = 88.0;
    } else if (battery <= 50) {
      confidence = 86.0;
    } else {
      confidence = 84.0;
    }

    if (historyCount >= 1) {
      confidence += 3.0;
    }

    if (historyCount >= 3) {
      confidence += 3.0;
    }

    if (historyCount >= 5) {
      confidence += 2.0;
    }

    if (chargerType == 'Fast Charging') {
      confidence += 2.0;
    }

    if (confidence > 98.0) {
      confidence = 98.0;
    }

    return confidence;
  }
}