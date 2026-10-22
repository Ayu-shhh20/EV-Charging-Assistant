import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/openstreetmap_service.dart';

class ChargingStationsScreen extends StatefulWidget {
  const ChargingStationsScreen({super.key});

  @override
  State<ChargingStationsScreen> createState() =>
      _ChargingStationsScreenState();
}

class _ChargingStationsScreenState
    extends State<ChargingStationsScreen> {
  final OpenStreetMapService _stationService =
  OpenStreetMapService();

  List<Map<String, dynamic>> stations = [];

  bool isLoading = true;
  String? errorMessage;

  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _loadNearbyStations();
  }

  // ============================================================
  // LOAD NEARBY STATIONS
  // ============================================================

  Future<void> _loadNearbyStations() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final Position position =
      await _getCurrentLocation();

      currentPosition = position;

      final List<Map<String, dynamic>> result =
      await _stationService.getNearbyChargingStations(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: 50000,
      );

      // Make absolutely sure the displayed list is
      // nearest station first.
      result.sort((a, b) {
        final double distanceA =
            (a['distanceKm'] as num?)?.toDouble() ??
                99999;

        final double distanceB =
            (b['distanceKm'] as num?)?.toDouble() ??
                99999;

        return distanceA.compareTo(distanceB);
      });

      if (!mounted) return;

      setState(() {
        stations = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<Position> _getCurrentLocation() async {
    final bool serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS.',
      );
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission was denied.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable it from phone settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings:
      const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // ============================================================
  // GET STATION NAME
  // ============================================================

  String _getStationName(
      Map<String, dynamic> station,
      ) {
    final String name =
        station['name']
            ?.toString()
            .trim() ??
            '';

    if (name.isNotEmpty) {
      return name;
    }

    return 'EV Charging Station';
  }

  // ============================================================
  // GET ADDRESS
  // ============================================================

  String _getAddress(
      Map<String, dynamic> station,
      ) {
    final String address =
        station['address']
            ?.toString()
            .trim() ??
            '';

    final String city =
        station['city']
            ?.toString()
            .trim() ??
            '';

    if (address.isNotEmpty &&
        city.isNotEmpty &&
        !address
            .toLowerCase()
            .contains(city.toLowerCase())) {
      return '$address, $city';
    }

    if (address.isNotEmpty) {
      return address;
    }

    if (city.isNotEmpty) {
      return city;
    }

    return 'Address not available';
  }

  // ============================================================
  // GET OPERATOR
  // ============================================================

  String _getOperator(
      Map<String, dynamic> station,
      ) {
    final String operator =
        station['operator']
            ?.toString()
            .trim() ??
            '';

    final String brand =
        station['brand']
            ?.toString()
            .trim() ??
            '';

    if (operator.isNotEmpty) {
      return operator;
    }

    if (brand.isNotEmpty) {
      return brand;
    }

    return 'Charging Network';
  }

  // ============================================================
  // GET CHARGER
  // ============================================================

  String _getCharger(
      Map<String, dynamic> station,
      ) {
    final String charger =
        station['charger']
            ?.toString()
            .trim() ??
            '';

    if (charger.isEmpty) {
      return 'EV Charger';
    }

    return charger;
  }

  // ============================================================
  // GET POWER
  // ============================================================

  String _getPower(
      Map<String, dynamic> station,
      ) {
    final String power =
        station['power']
            ?.toString()
            .trim() ??
            '';

    if (power.isEmpty) {
      return 'Power unavailable';
    }

    return power;
  }

  // ============================================================
  // GET DISTANCE
  // ============================================================

  double _getDistance(
      Map<String, dynamic> station,
      ) {
    return (station['distanceKm'] as num?)
        ?.toDouble() ??
        0;
  }

  // ============================================================
  // GET QUALITY SCORE
  // ============================================================

  int _getQualityScore(
      Map<String, dynamic> station,
      ) {
    return (station['qualityScore'] as num?)
        ?.toInt() ??
        0;
  }

  // ============================================================
  // GET RECOMMENDATION SCORE
  // ============================================================

  double _getRecommendationScore(
      Map<String, dynamic> station,
      ) {
    return (station['recommendationScore']
    as num?)
        ?.toDouble() ??
        0;
  }

  // ============================================================
  // GET STATUS
  // ============================================================

  bool _isOperational(
      Map<String, dynamic> station,
      ) {
    final String status =
        station['operational']
            ?.toString()
            .toLowerCase() ??
            '';

    if (status == 'no' ||
        status == 'false' ||
        status == 'closed' ||
        status == 'not operational') {
      return false;
    }

    return true;
  }

  // ============================================================
  // FORMAT DISTANCE
  // ============================================================

  String _formatDistance(
      double distance,
      ) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(2)} km';
  }

  // ============================================================
  // STATION CARD
  // ============================================================

  Widget _buildStationCard(
      Map<String, dynamic> station,
      int index,
      ) {
    final String name =
    _getStationName(station);

    final String address =
    _getAddress(station);

    final String operator =
    _getOperator(station);

    final String charger =
    _getCharger(station);

    final String power =
    _getPower(station);

    final double distance =
    _getDistance(station);

    final int qualityScore =
    _getQualityScore(station);

    final double recommendationScore =
    _getRecommendationScore(station);

    final bool operational =
    _isOperational(station);

    final String distanceText =
    _formatDistance(distance);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 15,
      ),
      padding:
      const EdgeInsets.all(17),
      decoration:
      BoxDecoration(
        color:
        const Color(0xff151B18),
        borderRadius:
        BorderRadius.circular(20),
        border:
        Border.all(
          color:
          Colors.greenAccent.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ======================================================
          // TOP ROW
          // ======================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration:
                BoxDecoration(
                  color:
                  Colors.greenAccent
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child:
                const Icon(
                  Icons.ev_station,
                  color:
                  Colors.greenAccent,
                  size: 28,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
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
                      height: 6,
                    ),

                    Text(
                      operator,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        color:
                        Colors.greenAccent,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.black26,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child:
                Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color:
                      Colors.greenAccent,
                      size: 14,
                    ),
                    const SizedBox(
                      width: 3,
                    ),
                    Text(
                      distanceText,
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 11,
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
            height: 14,
          ),

          // ======================================================
          // NEAREST BADGE
          // ======================================================

          if (index == 0)
            Container(
              margin:
              const EdgeInsets.only(
                bottom: 12,
              ),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.greenAccent
                    .withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                BorderRadius.circular(10),
                border:
                Border.all(
                  color:
                  Colors.greenAccent
                      .withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
              child:
              const Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons.near_me,
                    color:
                    Colors.greenAccent,
                    size: 15,
                  ),
                  SizedBox(
                    width: 6,
                  ),
                  Text(
                    'NEAREST STATION',
                    style:
                    TextStyle(
                      color:
                      Colors.greenAccent,
                      fontSize: 10,
                      fontWeight:
                      FontWeight.bold,
                      letterSpacing:
                      0.5,
                    ),
                  ),
                ],
              ),
            ),

          // ======================================================
          // ADDRESS
          // ======================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color:
                Colors.white54,
                size: 17,
              ),
              const SizedBox(
                width: 7,
              ),
              Expanded(
                child:
                Text(
                  address,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color:
                    Colors.white60,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          // ======================================================
          // DETAILS
          // ======================================================

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _buildInfoChip(
                Icons.bolt,
                charger,
              ),
              _buildInfoChip(
                Icons.electric_meter,
                power,
              ),
              _buildInfoChip(
                Icons.star,
                'Score $qualityScore',
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          // ======================================================
          // AI SCORE
          // ======================================================

          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color:
                Colors.greenAccent,
                size: 17,
              ),
              const SizedBox(
                width: 6,
              ),
              Text(
                'AI Score ${recommendationScore.toStringAsFixed(0)}',
                style:
                const TextStyle(
                  color:
                  Colors.white70,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ======================================================
          // STATUS
          // ======================================================

          Row(
            children: [
              Icon(
                operational
                    ? Icons.check_circle
                    : Icons.help_outline,
                color:
                operational
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                size: 18,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                operational
                    ? 'Operational'
                    : 'Status unknown',
                style:
                TextStyle(
                  color:
                  operational
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),

              const Spacer(),

              Text(
                '#${index + 1}',
                style:
                const TextStyle(
                  color:
                  Colors.white38,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CHIP
  // ============================================================

  Widget _buildInfoChip(
      IconData icon,
      String text,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.black.withValues(
          alpha: 0.20,
        ),
        borderRadius:
        BorderRadius.circular(9),
      ),
      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
            Colors.greenAccent,
            size: 14,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            text,
            style:
            const TextStyle(
              color:
              Colors.white70,
              fontSize: 11,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY VIEW
  // ============================================================

  Widget _buildEmptyView() {
    return Center(
      child:
      Padding(
        padding:
        const EdgeInsets.all(25),
        child:
        Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.ev_station,
              color:
              Colors.white38,
              size: 60,
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'No charging stations found',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                Colors.white,
                fontSize: 19,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 9,
            ),

            const Text(
              'No EV charging stations were returned within 50 km of your current location.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed:
              _loadNearbyStations,
              icon:
              const Icon(
                Icons.refresh,
              ),
              label:
              const Text(
                'Search Again',
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

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildErrorView() {
    return Center(
      child:
      Padding(
        padding:
        const EdgeInsets.all(25),
        child:
        Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              color:
              Colors.redAccent,
              size: 55,
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Unable to load charging stations',
              textAlign:
              TextAlign.center,
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
              errorMessage ??
                  'Something went wrong while loading nearby stations.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color:
                Colors.white60,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed:
              _loadNearbyStations,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xff0B0F0D),

      appBar: AppBar(
        backgroundColor:
        Colors.black,
        foregroundColor:
        Colors.white,

        title:
        const Text(
          'Nearby Charging Stations',
          style:
          TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
            isLoading
                ? null
                : _loadNearbyStations,
            icon:
            const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child:
        isLoading
            ? const Center(
          child:
          CircularProgressIndicator(
            color:
            Colors.greenAccent,
          ),
        )
            : errorMessage != null
            ? _buildErrorView()
            : stations.isEmpty
            ? _buildEmptyView()
            : RefreshIndicator(
          onRefresh:
          _loadNearbyStations,
          color:
          Colors.greenAccent,
          backgroundColor:
          const Color(
            0xff151B18,
          ),
          child:
          SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.all(
              16,
            ),
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // ==========================================
                // LOCATION HEADER
                // ==========================================

                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets.all(
                    17,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xff151B18,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                    border:
                    Border.all(
                      color:
                      Colors.greenAccent
                          .withValues(
                        alpha:
                        0.16,
                      ),
                    ),
                  ),
                  child:
                  Row(
                    children: [
                      Container(
                        width:
                        48,
                        height:
                        48,
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.greenAccent
                              .withValues(
                            alpha:
                            0.10,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                        child:
                        const Icon(
                          Icons.my_location,
                          color:
                          Colors.greenAccent,
                          size:
                          25,
                        ),
                      ),

                      const SizedBox(
                        width:
                        12,
                      ),

                      Expanded(
                        child:
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stations Near You',
                              style:
                              TextStyle(
                                color:
                                Colors.white,
                                fontSize:
                                18,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height:
                              5,
                            ),

                            Text(
                              '${stations.length} stations found within 50 km',
                              style:
                              const TextStyle(
                                color:
                                Colors.white54,
                                fontSize:
                                12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height:
                  20,
                ),

                // ==========================================
                // LIVE DATA
                // ==========================================

                Row(
                  children: [
                    Container(
                      width:
                      9,
                      height:
                      9,
                      decoration:
                      const BoxDecoration(
                        color:
                        Colors.greenAccent,
                        shape:
                        BoxShape.circle,
                      ),
                    ),

                    const SizedBox(
                      width:
                      7,
                    ),

                    const Text(
                      'Live OpenStreetMap results',
                      style:
                      TextStyle(
                        color:
                        Colors.greenAccent,
                        fontSize:
                        12,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                  16,
                ),

                // ==========================================
                // TITLE
                // ==========================================

                const Text(
                  'Nearby Charging Stations',
                  style:
                  TextStyle(
                    color:
                    Colors.white,
                    fontSize:
                    20,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                  5,
                ),

                const Text(
                  'Real stations are sorted from nearest to farthest using GPS distance.',
                  style:
                  TextStyle(
                    color:
                    Colors.white54,
                    fontSize:
                    12,
                  ),
                ),

                const SizedBox(
                  height:
                  16,
                ),

                // ==========================================
                // ALL STATIONS
                // ==========================================

                ...List.generate(
                  stations.length,
                      (index) {
                    return _buildStationCard(
                      stations[index],
                      index,
                    );
                  },
                ),

                const SizedBox(
                  height:
                  10,
                ),

                // ==========================================
                // INFORMATION
                // ==========================================

                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.orange
                        .withValues(
                      alpha:
                      0.06,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                    border:
                    Border.all(
                      color:
                      Colors.orange
                          .withValues(
                        alpha:
                        0.16,
                      ),
                    ),
                  ),
                  child:
                  const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color:
                        Colors.orange,
                        size:
                        18,
                      ),

                      SizedBox(
                        width:
                        8,
                      ),

                      Expanded(
                        child:
                        Text(
                          'Station information comes from OpenStreetMap. Charger availability, power and operating status depend on the information currently available in the map data.',
                          style:
                          TextStyle(
                            color:
                            Colors.white54,
                            fontSize:
                            11,
                            height:
                            1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height:
                  20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}