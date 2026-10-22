import 'dart:async';

import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';
import '../models/ai_prediction_model.dart';

import '../services/vehicle_service.dart';
import '../services/ai_service.dart';
import '../services/charging_service.dart';

class ChargingScreen extends StatefulWidget {
  const ChargingScreen({super.key});

  @override
  State<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends State<ChargingScreen> {
  VehicleModel? vehicle;

  AIPredictionModel? prediction;

  Timer? chargingTimer;

  bool isCharging = false;
  bool chargingCompleted = false;
  bool isSavingToDatabase = false;

  int simulatedBattery = 0;
  int chargingStartBattery = 0;
  int elapsedMinutes = 0;

  DateTime? chargingStartedAt;

  @override
  void initState() {
    super.initState();
    _loadChargingData();
  }

  // ============================================================
  // LOAD VEHICLE + AI PREDICTION
  // ============================================================

  void _loadChargingData() {
    final VehicleModel loadedVehicle =
    VehicleService.getVehicleData();

    final AIPredictionModel loadedPrediction =
    AIService().getPrediction(
      battery: loadedVehicle.currentBattery,
      capacity: loadedVehicle.batteryCapacity,
      chargerType: loadedVehicle.chargingType,
    );

    if (!mounted) return;

    setState(() {
      vehicle = loadedVehicle;
      prediction = loadedPrediction;

      simulatedBattery =
          loadedVehicle.currentBattery;

      chargingStartBattery =
          loadedVehicle.currentBattery;
    });
  }

  // ============================================================
  // START CHARGING
  // ============================================================

  void _startCharging() {
    if (vehicle == null) return;
    if (isCharging) return;
    if (isSavingToDatabase) return;

    setState(() {
      isCharging = true;
      chargingCompleted = false;
      isSavingToDatabase = false;

      chargingStartBattery =
          vehicle!.currentBattery;

      simulatedBattery =
          vehicle!.currentBattery;

      elapsedMinutes = 0;

      chargingStartedAt =
          DateTime.now();
    });

    chargingTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          // Demo:
          // 1 real second = 1 charging minute.
          elapsedMinutes++;

          if (simulatedBattery < 100) {
            simulatedBattery++;
          }

          if (simulatedBattery >= 100) {
            simulatedBattery = 100;

            timer.cancel();

            _completeCharging();
          }
        });
      },
    );
  }

  // ============================================================
  // STOP / FINISH CHARGING
  // ============================================================

  void _stopCharging() {
    if (!isCharging) return;
    if (isSavingToDatabase) return;

    chargingTimer?.cancel();

    _completeCharging();
  }

  // ============================================================
  // COMPLETE CHARGING + SAVE TO FIREBASE
  // ============================================================

  Future<void> _completeCharging() async {
    if (!mounted) return;

    if (!isCharging && chargingCompleted) {
      return;
    }

    chargingTimer?.cancel();

    setState(() {
      isCharging = false;
      chargingCompleted = true;
      isSavingToDatabase = true;
    });

    try {
      // ----------------------------------------------------------
      // CHECK VEHICLE
      // ----------------------------------------------------------

      if (vehicle == null) {
        throw Exception(
          'Vehicle information is missing.',
        );
      }

      // ----------------------------------------------------------
      // CHECK AI PREDICTION
      // ----------------------------------------------------------

      if (prediction == null) {
        throw Exception(
          'AI prediction is missing.',
        );
      }

      // ----------------------------------------------------------
      // CALCULATE FINAL VALUES
      // ----------------------------------------------------------

      final int endBattery =
          simulatedBattery;

      final int batteryDifference =
      (endBattery - chargingStartBattery)
          .clamp(0, 100);

      final double energyUsed =
          vehicle!.batteryCapacity *
              batteryDifference /
              100;

      final double cost =
          prediction!.estimatedCost;

      // ----------------------------------------------------------
      // SAVE DIRECTLY TO FIREBASE
      //
      // NO userId CHECK
      // NO vehicleId CHECK
      // NO PostgreSQL
      // ----------------------------------------------------------

      final Map<String, dynamic> result =
      await ChargingService
          .saveSessionToDatabase(
        stationName:
        prediction!.recommendedStation,

        chargerType:
        vehicle!.chargingType,

        energyUsed:
        energyUsed,

        chargingTime:
        elapsedMinutes,

        cost:
        cost,

        startBattery:
        chargingStartBattery,

        endBattery:
        endBattery,

        completed:
        true,
      );

      // ----------------------------------------------------------
      // FIREBASE SAVE SUCCESS
      // ----------------------------------------------------------

      if (!mounted) return;

      setState(() {
        isSavingToDatabase = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
          Colors.green,

          duration:
          const Duration(seconds: 4),

          content: Text(
            'Charging session saved successfully.\n'
                'Session ID: '
                '${result['session_id'] ?? 'Saved'}',
          ),
        ),
      );
    } catch (e) {
      // ----------------------------------------------------------
      // FIREBASE SAVE FAILED
      // ----------------------------------------------------------

      if (!mounted) return;

      setState(() {
        isSavingToDatabase = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
          Colors.red,

          duration:
          const Duration(seconds: 6),

          content: Text(
            'Data save failed:\n$e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // REFRESH VEHICLE
  // ============================================================

  void _refreshData() {
    if (isSavingToDatabase) return;

    chargingTimer?.cancel();

    final VehicleModel loadedVehicle =
    VehicleService.getVehicleData();

    final AIPredictionModel loadedPrediction =
    AIService().getPrediction(
      battery: loadedVehicle.currentBattery,
      capacity: loadedVehicle.batteryCapacity,
      chargerType: loadedVehicle.chargingType,
    );

    if (!mounted) return;

    setState(() {
      vehicle = loadedVehicle;
      prediction = loadedPrediction;

      simulatedBattery =
          loadedVehicle.currentBattery;

      chargingStartBattery =
          loadedVehicle.currentBattery;

      elapsedMinutes = 0;

      isCharging = false;
      chargingCompleted = false;
      isSavingToDatabase = false;

      chargingStartedAt = null;
    });
  }

  @override
  void dispose() {
    chargingTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (vehicle == null ||
        prediction == null) {
      return const Scaffold(
        backgroundColor:
        Color(0xff0B0F0D),

        body: Center(
          child:
          CircularProgressIndicator(
            color:
            Colors.greenAccent,
          ),
        ),
      );
    }

    final double batteryProgress =
        simulatedBattery / 100;

    final int batteryDifference =
    (simulatedBattery -
        chargingStartBattery)
        .clamp(0, 100);

    final double currentEnergy =
        vehicle!.batteryCapacity *
            batteryDifference /
            100;

    return Scaffold(
      backgroundColor:
      const Color(0xff0B0F0D),

      appBar: AppBar(
        backgroundColor:
        Colors.black,

        foregroundColor:
        Colors.white,

        title: const Text(
          'EV Charging',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
            isCharging ||
                isSavingToDatabase
                ? null
                : _refreshData,

            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // ==================================================
            // VEHICLE CARD
            // ==================================================

            Container(
              width:
              double.infinity,

              padding:
              const EdgeInsets.all(20),

              decoration:
              BoxDecoration(
                color:
                const Color(0xff151B18),

                borderRadius:
                BorderRadius.circular(22),

                border: Border.all(
                  color: Colors
                      .greenAccent
                      .withValues(
                    alpha: 0.25,
                  ),
                ),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,

                        decoration:
                        BoxDecoration(
                          color: Colors
                              .greenAccent
                              .withValues(
                            alpha: 0.12,
                          ),

                          borderRadius:
                          BorderRadius
                              .circular(
                            15,
                          ),
                        ),

                        child:
                        const Icon(
                          Icons
                              .directions_car,

                          color: Colors
                              .greenAccent,

                          size: 28,
                        ),
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [
                            Text(
                              vehicle!
                                  .vehicleName
                                  .isEmpty
                                  ? 'Your EV'
                                  : vehicle!
                                  .vehicleName,

                              style:
                              const TextStyle(
                                color:
                                Colors.white,

                                fontSize: 18,

                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              '${vehicle!.batteryCapacity} kWh Battery',

                              style:
                              const TextStyle(
                                color:
                                Colors.white54,

                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // BATTERY CARD
            // ==================================================

            Container(
              width:
              double.infinity,

              padding:
              const EdgeInsets.all(24),

              decoration:
              BoxDecoration(
                color:
                const Color(0xff151B18),

                borderRadius:
                BorderRadius.circular(22),
              ),

              child: Column(
                children: [
                  const Text(
                    'Current Battery',

                    style: TextStyle(
                      color:
                      Colors.white70,

                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  SizedBox(
                    width: 180,
                    height: 180,

                    child: Stack(
                      alignment:
                      Alignment.center,

                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,

                          child:
                          CircularProgressIndicator(
                            value:
                            batteryProgress,

                            strokeWidth:
                            14,

                            backgroundColor:
                            Colors.white10,

                            color:
                            Colors.greenAccent,
                          ),
                        ),

                        Column(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                          children: [
                            Text(
                              '$simulatedBattery%',

                              style:
                              const TextStyle(
                                color:
                                Colors.white,

                                fontSize: 34,

                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),

                            Text(
                              isCharging
                                  ? 'Charging'
                                  : chargingCompleted
                                  ? 'Completed'
                                  : 'Ready',

                              style: TextStyle(
                                color: isCharging ||
                                    chargingCompleted
                                    ? Colors
                                    .greenAccent
                                    : Colors
                                    .white54,

                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Text(
                    '${currentEnergy.toStringAsFixed(2)} kWh used',

                    style:
                    const TextStyle(
                      color:
                      Colors.white70,

                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // AI PREDICTION
            // ==================================================

            Container(
              width:
              double.infinity,

              padding:
              const EdgeInsets.all(18),

              decoration:
              BoxDecoration(
                color:
                const Color(0xff101814),

                borderRadius:
                BorderRadius.circular(18),

                border: Border.all(
                  color: Colors
                      .greenAccent
                      .withValues(
                    alpha: 0.20,
                  ),
                ),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,

                        color:
                        Colors.greenAccent,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      const Text(
                        'AI Charging Prediction',

                        style:
                        TextStyle(
                          color: Colors
                              .greenAccent,

                          fontSize: 16,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _predictionRow(
                    Icons.timer,
                    'Estimated Time',
                    '${prediction!.estimatedTime} min',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _predictionRow(
                    Icons.currency_rupee,
                    'Estimated Cost',
                    '₹${prediction!.estimatedCost.toStringAsFixed(2)}',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _predictionRow(
                    Icons.ev_station,
                    'Recommended Station',
                    prediction!
                        .recommendedStation,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _predictionRow(
                    Icons.analytics,
                    'AI Confidence',
                    '${prediction!.confidenceScore.toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // CHARGING INFORMATION
            // ==================================================

            Container(
              width:
              double.infinity,

              padding:
              const EdgeInsets.all(18),

              decoration:
              BoxDecoration(
                color:
                const Color(0xff151B18),

                borderRadius:
                BorderRadius.circular(18),
              ),

              child: Column(
                children: [
                  _infoRow(
                    Icons.bolt,
                    'Charging Type',
                    vehicle!.chargingType,
                  ),

                  const Divider(
                    color:
                    Colors.white12,

                    height: 24,
                  ),

                  _infoRow(
                    Icons.battery_std,
                    'Starting Battery',
                    '$chargingStartBattery%',
                  ),

                  const Divider(
                    color:
                    Colors.white12,

                    height: 24,
                  ),

                  _infoRow(
                    Icons
                        .battery_charging_full,
                    'Current Battery',
                    '$simulatedBattery%',
                  ),

                  const Divider(
                    color:
                    Colors.white12,

                    height: 24,
                  ),

                  _infoRow(
                    Icons.schedule,
                    'Charging Time',
                    '$elapsedMinutes min',
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ==================================================
            // FIREBASE STATUS
            // ==================================================

            if (isSavingToDatabase)
              Container(
                width:
                double.infinity,

                padding:
                const EdgeInsets.all(16),

                decoration:
                BoxDecoration(
                  color: Colors
                      .orange
                      .withValues(
                    alpha: 0.10,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),

                  border: Border.all(
                    color: Colors
                        .orange
                        .withValues(
                      alpha: 0.30,
                    ),
                  ),
                ),

                child: const Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,

                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,

                        color:
                        Colors.orange,
                      ),
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Text(
                        'Saving charging session...',

                        style: TextStyle(
                          color:
                          Colors.orange,

                          fontSize: 13,

                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (isSavingToDatabase)
              const SizedBox(
                height: 15,
              ),

            // ==================================================
            // START / STOP / NEW SESSION
            // ==================================================

            SizedBox(
              width:
              double.infinity,

              height: 54,

              child:
              ElevatedButton.icon(
                onPressed:
                isSavingToDatabase
                    ? null
                    : isCharging
                    ? _stopCharging
                    : chargingCompleted
                    ? _refreshData
                    : _startCharging,

                icon: Icon(
                  isCharging
                      ? Icons.stop
                      : chargingCompleted
                      ? Icons.refresh
                      : Icons.bolt,
                ),

                label: Text(
                  isCharging
                      ? 'Finish Charging'
                      : chargingCompleted
                      ? 'Start New Session'
                      : 'Start Charging',

                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,

                    fontSize: 16,
                  ),
                ),

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  isCharging
                      ? Colors.redAccent
                      : Colors
                      .greenAccent,

                  foregroundColor:
                  Colors.black,

                  disabledBackgroundColor:
                  Colors.grey,

                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 14,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // SUCCESS MESSAGE
            // ==================================================

            if (chargingCompleted &&
                !isSavingToDatabase)
              Container(
                width:
                double.infinity,

                padding:
                const EdgeInsets.all(16),

                decoration:
                BoxDecoration(
                  color: Colors
                      .greenAccent
                      .withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),

                  border: Border.all(
                    color: Colors
                        .greenAccent
                        .withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),

                child: const Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    Icon(
                      Icons.check_circle,

                      color:
                      Colors.greenAccent,
                    ),

                    SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        'Charging session completed and saved. You can view it in Energy Analytics.',

                        style:
                        TextStyle(
                          color:
                          Colors.white70,

                          fontSize: 13,

                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PREDICTION ROW
  // ============================================================

  Widget _predictionRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color:
          Colors.greenAccent,
          size: 22,
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Text(
            title,

            style:
            const TextStyle(
              color:
              Colors.white60,

              fontSize: 13,
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,

            textAlign:
            TextAlign.right,

            style:
            const TextStyle(
              color:
              Colors.white,

              fontSize: 13,

              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _infoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color:
          Colors.greenAccent,
          size: 25,
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: Text(
            title,

            style:
            const TextStyle(
              color:
              Colors.white60,

              fontSize: 13,
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,

            textAlign:
            TextAlign.right,

            style:
            const TextStyle(
              color:
              Colors.white,

              fontSize: 14,

              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}