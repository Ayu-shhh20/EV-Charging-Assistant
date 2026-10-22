import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';
import '../models/ai_prediction_model.dart';
import '../models/charging_model.dart';

import '../services/vehicle_service.dart';
import '../services/ai_service.dart';
import '../services/firebase_service.dart';

import 'vehicle_input_screen.dart';
import 'map_screen.dart';
import 'nearby_places_screen.dart';
import 'energy_analytics_screen.dart';
import 'charging_stations_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AIService aiService = AIService();

  VehicleModel? vehicle;
  AIPredictionModel? prediction;

  bool isLoading = true;
  bool isPredicting = false;

  List<Map<String, dynamic>> chargingHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    await _loadVehicle();
    await _loadChargingHistory();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadVehicle() async {
    try {
      final VehicleModel localVehicle =
      VehicleService.getVehicleData();

      if (localVehicle.userName.isNotEmpty ||
          localVehicle.vehicleName.isNotEmpty) {
        vehicle = localVehicle;
      }

      final VehicleModel? firebaseVehicle =
      await FirebaseService.getVehicle();

      if (firebaseVehicle != null) {
        vehicle = firebaseVehicle;

        await VehicleService.saveVehicleData(
          userId: firebaseVehicle.userId,
          vehicleId: firebaseVehicle.vehicleId,
          userName: firebaseVehicle.userName,
          vehicleName: firebaseVehicle.vehicleName,
          batteryCapacity:
          firebaseVehicle.batteryCapacity,
          currentBattery:
          firebaseVehicle.currentBattery,
          chargingType:
          firebaseVehicle.chargingType,
        );
      }

      if (vehicle != null) {
        await _generatePrediction();
      }
    } catch (e) {
      debugPrint(
        'Vehicle loading error: $e',
      );
    }
  }

  Future<void> _loadChargingHistory() async {
    try {
      final List<ChargingModel> sessions =
      await FirebaseService.getChargingSessions();

      chargingHistory = sessions.map((session) {
        return <String, dynamic>{
          'station_name':
          session.stationName,
          'charger_type':
          session.chargerType,
          'energy_used':
          session.energyUsed,
          'charging_time':
          session.chargingTime,
          'cost':
          session.cost,
          'start_battery':
          session.startBattery,
          'end_battery':
          session.endBattery,
          'completed':
          session.completed,
          'session_time':
          session.dateTime.toIso8601String(),
        };
      }).toList();

      if (vehicle != null) {
        await _generatePrediction();
      }
    } catch (e) {
      debugPrint(
        'Charging history loading error: $e',
      );

      chargingHistory = [];
    }
  }

  Future<void> _generatePrediction() async {
    if (vehicle == null) {
      return;
    }

    if (mounted) {
      setState(() {
        isPredicting = true;
      });
    }

    try {
      final AIPredictionModel result =
      aiService.getPrediction(
        battery: vehicle!.currentBattery,
        capacity: vehicle!.batteryCapacity,
        chargerType: vehicle!.chargingType,
        chargingHistory: chargingHistory,
      );

      if (!mounted) return;

      setState(() {
        prediction = result;
      });
    } catch (e) {
      debugPrint(
        'AI prediction error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isPredicting = false;
        });
      }
    }
  }
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    await _loadHomeData();

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _openVehicleInput() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const VehicleInputScreen(),
      ),
    );

    await _refreshData();
  }

  void _openChargingStations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const ChargingStationsScreen(),
      ),
    );
  }

  void _openAIChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const AIChatScreen(),
      ),
    );
  }

  void _openNearbyPlaces() {
    if (prediction == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const MapScreen(),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NearbyPlacesScreen(
              chargingMinutes:
              prediction!.estimatedTime,
              stationLatitude:
              prediction!.stationLatitude,
              stationLongitude:
              prediction!.stationLongitude,
              stationName:
              prediction!.recommendedStation,
            ),
      ),
    );
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const MapScreen(),
      ),
    );
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const EnergyAnalyticsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xff0B0F0D),

      appBar: AppBar(
        backgroundColor:
        const Color(0xff0B0F0D),
        foregroundColor:
        Colors.white,
        elevation: 0,

        title: const Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'AI EV Charging Assistant',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Smart charging made simple',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'AI Assistant',
            onPressed: _openAIChat,
            icon: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.greenAccent,
            ),
          ),

          IconButton(
            tooltip: 'Refresh',
            onPressed:
            isLoading
                ? null
                : _refreshData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.greenAccent,
        backgroundColor:
        const Color(0xff151B18),

        child: isLoading
            ? ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height:
              MediaQuery.of(context)
                  .size
                  .height *
                  0.35,
            ),
            const Center(
              child:
              CircularProgressIndicator(
                color:
                Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Loading your EV data...',
                style: TextStyle(
                  color:
                  Colors.white70,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        )
            : ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),

            const SizedBox(height: 16),

            _buildVehicleCard(),

            const SizedBox(height: 16),

            _buildBatteryCard(),

            const SizedBox(height: 16),

            _buildPredictionCard(),

            const SizedBox(height: 20),

            const Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildQuickActions(),

            const SizedBox(height: 20),

            _buildAIChatBanner(),

            const SizedBox(height: 20),

            _buildHistorySummary(),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final String name =
    vehicle?.userName.isNotEmpty == true
        ? vehicle!.userName
        : 'EV Driver';

    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade900,
            const Color(0xff14231B),
          ],
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
        ),
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: Colors.greenAccent
              .withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.greenAccent
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.electric_car,
              color:
              Colors.greenAccent,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name 👋',
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ready for a smarter EV journey?',
                  style: TextStyle(
                    color: Colors.white70,
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

  Widget _buildVehicleCard() {
    if (vehicle == null ||
        vehicle!.vehicleName.isEmpty) {
      return GestureDetector(
        onTap: _openVehicleInput,
        child: Container(
          padding:
          const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
            const Color(0xff151B18),
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: Colors.greenAccent
                  .withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding:
                const EdgeInsets.all(12),
                decoration:
                BoxDecoration(
                  color: Colors.greenAccent
                      .withValues(alpha: 0.10),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color:
                  Colors.greenAccent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add your EV',
                      style: TextStyle(
                        color:
                        Colors.white,
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Enter your vehicle details to unlock AI predictions.',
                      style: TextStyle(
                        color:
                        Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color:
                Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
        const Color(0xff151B18),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white
              .withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent
                  .withValues(alpha: 0.10),
              borderRadius:
              BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.electric_car,
              color:
              Colors.greenAccent,
              size: 30,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle!.vehicleName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${vehicle!.batteryCapacity.toStringAsFixed(1)} kWh • ${vehicle!.chargingType}',
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                    Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: _openVehicleInput,
            icon: const Icon(
              Icons.edit_outlined,
              color:
              Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryCard() {
    final int battery =
        vehicle?.currentBattery ?? 0;

    final double progress =
    (battery / 100)
        .clamp(0.0, 1.0);

    Color batteryColor =
        Colors.greenAccent;

    if (battery <= 20) {
      batteryColor =
          Colors.redAccent;
    } else if (battery <= 40) {
      batteryColor =
          Colors.orangeAccent;
    }

    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
        const Color(0xff151B18),
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: batteryColor
              .withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_charging_full,
                color:
                Colors.greenAccent,
              ),
              const SizedBox(width: 8),
              const Text(
                'Current Battery',
                style: TextStyle(
                  color:
                  Colors.white70,
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$battery%',
                style: TextStyle(
                  color: batteryColor,
                  fontSize: 25,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),
            child:
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
              Colors.white10,
              valueColor:
              AlwaysStoppedAnimation<
                  Color>(
                batteryColor,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.route,
                size: 17,
                color:
                Colors.white54,
              ),
              const SizedBox(width: 6),
              Text(
                'Estimated range: ${vehicle?.range ?? 0} km',
                style:
                const TextStyle(
                  color:
                  Colors.white60,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          if (battery <= 20) ...[
            const SizedBox(height: 12),
            Container(
              padding:
              const EdgeInsets.all(10),
              decoration:
              BoxDecoration(
                color: Colors.redAccent
                    .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color:
                    Colors.redAccent,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Low battery. Consider charging soon.',
                      style: TextStyle(
                        color:
                        Colors.redAccent,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredictionCard() {
    if (isPredicting) {
      return Container(
        padding:
        const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
          const Color(0xff151B18),
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child:
              CircularProgressIndicator(
                strokeWidth: 2.5,
                color:
                Colors.greenAccent,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'AI is analyzing your charging data...',
              style: TextStyle(
                color:
                Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (prediction == null) {
      return Container(
        padding:
        const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:
          const Color(0xff151B18),
          borderRadius:
          BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color:
              Colors.greenAccent,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add your EV details to get AI charging predictions.',
                style: TextStyle(
                  color:
                  Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xff12351F),
            const Color(0xff151B18),
          ],
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
        ),
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent
              .withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.all(8),
                decoration:
                BoxDecoration(
                  color: Colors.greenAccent
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color:
                  Colors.greenAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI Charging Prediction',
                  style: TextStyle(
                    color:
                    Colors.white,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${prediction!.confidenceScore.toStringAsFixed(0)}% confidence',
                style:
                const TextStyle(
                  color:
                  Colors.greenAccent,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child:
                _predictionMetric(
                  icon: Icons.timer_outlined,
                  title: 'Charge Time',
                  value:
                  '${prediction!.estimatedTime} min',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                _predictionMetric(
                  icon:
                  Icons.currency_rupee,
                  title: 'Est. Cost',
                  value:
                  '₹${prediction!.estimatedCost.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding:
            const EdgeInsets.all(13),
            decoration:
            BoxDecoration(
              color: Colors.black
                  .withValues(alpha: 0.15),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.ev_station,
                  color:
                  Colors.greenAccent,
                  size: 23,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommended Station',
                        style: TextStyle(
                          color:
                          Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        prediction!
                            .recommendedStation,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize: 14,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.battery_std,
                color:
                Colors.white54,
                size: 17,
              ),
              const SizedBox(width: 5),
              Text(
                '${prediction!.historyCount} previous charging sessions used',
                style:
                const TextStyle(
                  color:
                  Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _predictionMetric({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(13),
      decoration:
      BoxDecoration(
        color: Colors.black
            .withValues(alpha: 0.15),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
            Colors.greenAccent,
            size: 21,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color:
              Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
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

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                icon:
                Icons.ev_station,
                title:
                'Charging Stations',
                subtitle:
                'Find nearby stations',
                onTap:
                _openChargingStations,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                icon:
                Icons.smart_toy_outlined,
                title:
                'AI Assistant',
                subtitle:
                'Ask your EV AI',
                onTap:
                _openAIChat,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                icon:
                Icons.explore_outlined,
                title:
                'Nearby Places',
                subtitle:
                'Explore while charging',
                onTap:
                _openNearbyPlaces,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                icon:
                Icons.map_outlined,
                title:
                'Smart Route',
                subtitle:
                'Plan your EV route',
                onTap:
                _openMap,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                icon:
                Icons.analytics_outlined,
                title:
                'Energy Analytics',
                subtitle:
                'View charging history',
                onTap:
                _openAnalytics,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _quickActionCard(
                icon:
                Icons.edit_note,
                title:
                'Vehicle Details',
                subtitle:
                'Update your EV',
                onTap:
                _openVehicleInput,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
      const Color(0xff151B18),
      borderRadius:
      BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(17),
        child: Container(
          padding:
          const EdgeInsets.all(15),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(17),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: 0.07),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.all(9),
                decoration:
                BoxDecoration(
                  color: Colors.greenAccent
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color:
                  Colors.greenAccent,
                  size: 23,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                title,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIChatBanner() {
    return GestureDetector(
      onTap: _openAIChat,
      child: Container(
        padding:
        const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade900,
              const Color(0xff12351F),
            ],
          ),
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: Colors.greenAccent
                .withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding:
              const EdgeInsets.all(11),
              decoration:
              BoxDecoration(
                color: Colors.greenAccent
                    .withValues(alpha: 0.12),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color:
                Colors.greenAccent,
                size: 28,
              ),
            ),

            const SizedBox(width: 13),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help with your EV?',
                    style: TextStyle(
                      color:
                      Colors.white,
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Chat with your AI EV Charging Assistant',
                    style: TextStyle(
                      color:
                      Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              color:
              Colors.greenAccent,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySummary() {
    final int sessions =
        chargingHistory.length;

    double totalEnergy = 0;
    double totalCost = 0;

    for (final session
    in chargingHistory) {
      totalEnergy +=
          (session['energy_used']
          as num?)
              ?.toDouble() ??
              0;

      totalCost +=
          (session['cost'] as num?)
              ?.toDouble() ??
              0;
    }

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color:
        const Color(0xff151B18),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white
              .withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color:
                Colors.greenAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Charging History',
                  style: TextStyle(
                    color:
                    Colors.white,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed:
                _openAnalytics,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color:
                    Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child:
                _historyMetric(
                  title: 'Sessions',
                  value:
                  '$sessions',
                ),
              ),
              Expanded(
                child:
                _historyMetric(
                  title: 'Energy',
                  value:
                  '${totalEnergy.toStringAsFixed(1)} kWh',
                ),
              ),
              Expanded(
                child:
                _historyMetric(
                  title: 'Total Cost',
                  value:
                  '₹${totalCost.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyMetric({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color:
            Colors.greenAccent,
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color:
            Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}