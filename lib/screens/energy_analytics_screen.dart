import 'package:flutter/material.dart';

import '../models/charging_model.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import '../services/charging_service.dart';

class EnergyAnalyticsScreen extends StatefulWidget {
  const EnergyAnalyticsScreen({
    super.key,
  });

  @override
  State<EnergyAnalyticsScreen> createState() =>
      _EnergyAnalyticsScreenState();
}

class _EnergyAnalyticsScreenState
    extends State<EnergyAnalyticsScreen> {
  List<ChargingModel> sessions = [];

  bool isLoading = true;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    loadAnalytics();
  }

  // ============================================================
  // LOAD ANALYTICS FROM FIREBASE
  // ============================================================

  Future<void> loadAnalytics() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });
      }

      // Load charging sessions from Firebase.
      final List<ChargingModel> loadedSessions =
      await ChargingService.loadChargingSessions();

      if (!mounted) {
        return;
      }

      setState(() {
        sessions = loadedSessions;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // TOTAL ENERGY
  // ============================================================

  double getTotalEnergy() {
    double total = 0;

    for (final ChargingModel session in sessions) {
      total += session.energyUsed;
    }

    return total;
  }

  // ============================================================
  // TOTAL COST
  // ============================================================

  double getTotalCost() {
    double total = 0;

    for (final ChargingModel session in sessions) {
      total += session.cost;
    }

    return total;
  }

  // ============================================================
  // TOTAL TIME
  // ============================================================

  int getTotalTime() {
    int total = 0;

    for (final ChargingModel session in sessions) {
      total += session.chargingTime;
    }

    return total;
  }

  // ============================================================
  // AVERAGE ENERGY
  // ============================================================

  double getAverageEnergy() {
    if (sessions.isEmpty) {
      return 0;
    }

    return getTotalEnergy() / sessions.length;
  }

  // ============================================================
  // AVERAGE COST
  // ============================================================

  double getAverageCost() {
    if (sessions.isEmpty) {
      return 0;
    }

    return getTotalCost() / sessions.length;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xff0B0F0D),

      appBar: AppBar(
        backgroundColor:
        Colors.black,

        foregroundColor:
        Colors.white,

        title: const Text(
          'Energy Analytics',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
            isLoading
                ? null
                : loadAnalytics,

            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
        child:
        CircularProgressIndicator(
          color:
          Colors.greenAccent,
        ),
      )
          : errorMessage.isNotEmpty
          ? buildError()
          : RefreshIndicator(
        color:
        Colors.greenAccent,

        onRefresh:
        loadAnalytics,

        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding:
          const EdgeInsets.all(
            16,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              buildHeader(),

              const SizedBox(
                height: 20,
              ),

              buildSummary(),

              const SizedBox(
                height: 25,
              ),

              const Text(
                'Charging History',
                style:
                TextStyle(
                  color:
                  Colors.white,

                  fontSize: 20,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              if (sessions.isEmpty)
                buildEmptyState()
              else
                for (
                int index = 0;
                index < sessions.length;
                index++
                )
                  buildSessionCard(
                    sessions[index],
                    index,
                  ),

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget buildHeader() {
    final VehicleModel vehicle =
    VehicleService.getVehicleData();

    final String name =
    vehicle.userName.trim().isEmpty
        ? 'User'
        : vehicle.userName;

    final String vehicleName =
    vehicle.vehicleName.trim().isEmpty
        ? 'Your EV'
        : vehicle.vehicleName;

    return Container(
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

        border:
        Border.all(
          color: Colors
              .greenAccent
              .withValues(
            alpha: 0.25,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,

            decoration:
            BoxDecoration(
              color: Colors
                  .greenAccent
                  .withValues(
                alpha: 0.12,
              ),

              borderRadius:
              BorderRadius.circular(
                16,
              ),
            ),

            child: const Icon(
              Icons.analytics,
              color:
              Colors.greenAccent,
              size: 30,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  '$name\'s Energy Analytics',

                  style:
                  const TextStyle(
                    color:
                    Colors.white,

                    fontSize: 18,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  vehicleName,

                  style:
                  const TextStyle(
                    color:
                    Colors.greenAccent,

                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget buildSummary() {
    final double totalEnergy =
    getTotalEnergy();

    final double totalCost =
    getTotalCost();

    final int totalTime =
    getTotalTime();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: summaryCard(
                Icons.bolt,
                'Total Energy',
                '${totalEnergy.toStringAsFixed(1)} kWh',
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: summaryCard(
                Icons.currency_rupee,
                'Total Cost',
                '₹${totalCost.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        Row(
          children: [
            Expanded(
              child: summaryCard(
                Icons.ev_station,
                'Sessions',
                '${sessions.length}',
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: summaryCard(
                Icons.schedule,
                'Total Time',
                '$totalTime min',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        Row(
          children: [
            Expanded(
              child: summaryCard(
                Icons.electric_bolt,
                'Avg Energy',
                '${getAverageEnergy().toStringAsFixed(1)} kWh',
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: summaryCard(
                Icons.payments,
                'Avg Cost',
                '₹${getAverageCost().toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget summaryCard(
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(16),

      decoration:
      BoxDecoration(
        color:
        const Color(0xff151B18),

        borderRadius:
        BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            color:
            Colors.greenAccent,
            size: 25,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            title,

            style:
            const TextStyle(
              color:
              Colors.white54,

              fontSize: 12,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            value,

            style:
            const TextStyle(
              color:
              Colors.white,

              fontSize: 17,

              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SESSION CARD
  // ============================================================

  Widget buildSessionCard(
      ChargingModel session,
      int index,
      ) {
    final int startBattery =
        session.startBattery;

    final int endBattery =
        session.endBattery;

    final double energy =
        session.energyUsed;

    final double cost =
        session.cost;

    final int time =
        session.chargingTime;

    final bool completed =
        session.completed;

    return Container(
      width:
      double.infinity,

      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
      const EdgeInsets.all(18),

      decoration:
      BoxDecoration(
        color:
        const Color(0xff151B18),

        borderRadius:
        BorderRadius.circular(18),

        border:
        Border.all(
          color:
          Colors.white10,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,

                decoration:
                BoxDecoration(
                  color: Colors
                      .greenAccent
                      .withValues(
                    alpha: 0.10,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),

                child: const Icon(
                  Icons.ev_station,
                  color:
                  Colors.greenAccent,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    Text(
                      'Charging Session #${index + 1}',

                      style:
                      const TextStyle(
                        color:
                        Colors.white,

                        fontSize: 16,

                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      formatDate(
                        session.dateTime,
                      ),

                      style:
                      const TextStyle(
                        color:
                        Colors.white54,

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                BoxDecoration(
                  color: completed
                      ? Colors
                      .greenAccent
                      .withValues(
                    alpha: 0.10,
                  )
                      : Colors.orange
                      .withValues(
                    alpha: 0.10,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                child: Text(
                  completed
                      ? 'Completed'
                      : 'Incomplete',

                  style: TextStyle(
                    color: completed
                        ? Colors
                        .greenAccent
                        : Colors.orange,

                    fontSize: 11,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // Station
          Row(
            children: [
              const Icon(
                Icons.ev_station,
                color:
                Colors.greenAccent,
                size: 20,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    const Text(
                      'Station',

                      style:
                      TextStyle(
                        color:
                        Colors.white38,

                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      session.stationName,

                      style:
                      const TextStyle(
                        color:
                        Colors.white,

                        fontSize: 13,

                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          // Charger type
          Row(
            children: [
              const Icon(
                Icons.bolt,
                color:
                Colors.greenAccent,
                size: 20,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    const Text(
                      'Charger Type',

                      style:
                      TextStyle(
                        color:
                        Colors.white38,

                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      session.chargerType,

                      style:
                      const TextStyle(
                        color:
                        Colors.white,

                        fontSize: 13,

                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Row(
            children: [
              Expanded(
                child: sessionInfo(
                  Icons.battery_std,
                  'Battery',
                  '$startBattery% → $endBattery%',
                ),
              ),

              Expanded(
                child: sessionInfo(
                  Icons.bolt,
                  'Energy',
                  '${energy.toStringAsFixed(1)} kWh',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          Row(
            children: [
              Expanded(
                child: sessionInfo(
                  Icons.schedule,
                  'Time',
                  '$time min',
                ),
              ),

              Expanded(
                child: sessionInfo(
                  Icons.currency_rupee,
                  'Cost',
                  '₹${cost.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SESSION INFORMATION
  // ============================================================

  Widget sessionInfo(
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
          size: 20,
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,

            children: [
              Text(
                title,

                style:
                const TextStyle(
                  color:
                  Colors.white38,

                  fontSize: 11,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                value,

                style:
                const TextStyle(
                  color:
                  Colors.white,

                  fontSize: 13,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget buildEmptyState() {
    return Container(
      width:
      double.infinity,

      padding:
      const EdgeInsets.all(30),

      decoration:
      BoxDecoration(
        color:
        const Color(0xff151B18),

        borderRadius:
        BorderRadius.circular(18),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            color:
            Colors.white38,
            size: 55,
          ),

          SizedBox(
            height: 15,
          ),

          Text(
            'No Charging Records Yet',

            style:
            TextStyle(
              color:
              Colors.white,

              fontSize: 17,

              fontWeight:
              FontWeight.bold,
            ),
          ),

          SizedBox(
            height: 8,
          ),

          Text(
            'Complete a charging session and your charging history will appear here.',

            textAlign:
            TextAlign.center,

            style:
            TextStyle(
              color:
              Colors.white54,

              fontSize: 13,

              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(25),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline,
              color:
              Colors.redAccent,
              size: 55,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'Unable to Load Analytics',

              style:
              TextStyle(
                color:
                Colors.white,

                fontSize: 18,

                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              errorMessage,

              textAlign:
              TextAlign.center,

              style:
              const TextStyle(
                color:
                Colors.white54,

                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed:
              loadAnalytics,

              icon:
              const Icon(
                Icons.refresh,
              ),

              label:
              const Text(
                'Try Again',
              ),

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.greenAccent,

                foregroundColor:
                Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}