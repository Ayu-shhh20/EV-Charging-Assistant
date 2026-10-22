import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/openstreetmap_service.dart';
import 'nearby_places_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() =>
      _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final OpenStreetMapService _stationService =
  OpenStreetMapService();

  Position? currentPosition;

  List<Map<String, dynamic>> stations = [];

  bool isLoading = true;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    _loadStations();
  }

  // ==========================================================
  // LOAD STATIONS
  // ==========================================================

  Future<void> _loadStations() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // --------------------------------------------------------
      // LOCATION
      // --------------------------------------------------------

      final Position position =
      await _getCurrentLocation();

      currentPosition = position;

      debugPrint(
        'Map GPS: '
            '${position.latitude}, '
            '${position.longitude}',
      );

      // --------------------------------------------------------
      // STATIONS
      // --------------------------------------------------------

      final List<Map<String, dynamic>>
      result =
      await _stationService
          .getNearbyChargingStations(
        latitude: position.latitude,
        longitude: position.longitude,

        // 30 KM
        radius: 30000,
      );

      // --------------------------------------------------------
      // SORT NEAREST FIRST
      // --------------------------------------------------------

      result.sort(
            (a, b) {
          final double distanceA =
              (a['distanceKm'] as num?)
                  ?.toDouble() ??
                  double.infinity;

          final double distanceB =
              (b['distanceKm'] as num?)
                  ?.toDouble() ??
                  double.infinity;

          return distanceA.compareTo(
            distanceB,
          );
        },
      );

      if (!mounted) return;

      setState(() {
        stations = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'MAP STATION ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage =
            e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ==========================================================
  // GET LOCATION
  // ==========================================================

  Future<Position> _getCurrentLocation()
  async {
    final bool serviceEnabled =
    await Geolocator
        .isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'GPS is turned off. Please enable location services.',
      );
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.denied) {
      throw Exception(
        'Location permission was denied.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it from phone settings.',
      );
    }

    return await Geolocator
        .getCurrentPosition(
      locationSettings:
      const LocationSettings(
        accuracy:
        LocationAccuracy.medium,
      ),
    ).timeout(
      const Duration(seconds: 10),
    );
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _refreshStations()
  async {
    OpenStreetMapService.clearCache();

    await _loadStations();
  }

  // ==========================================================
  // NAVIGATE
  // ==========================================================

  Future<void> _navigateToStation(
      Map<String, dynamic> station,
      ) async {
    final double? latitude =
    (station['latitude'] as num?)
        ?.toDouble();

    final double? longitude =
    (station['longitude'] as num?)
        ?.toDouble();

    if (latitude == null ||
        longitude == null) {
      _showMessage(
        'Station coordinates are unavailable.',
      );

      return;
    }

    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/'
          '?api=1'
          '&destination=$latitude,$longitude'
          '&travelmode=driving',
    );

    try {
      final bool opened =
      await launchUrl(
        url,
        mode:
        LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage(
          'Unable to open Google Maps.',
        );
      }
    } catch (e) {
      debugPrint(
        'Google Maps error: $e',
      );

      _showMessage(
        'Unable to open Google Maps.',
      );
    }
  }

  // ==========================================================
  // EXPLORE NEARBY
  // ==========================================================

  Future<void> _exploreNearby(
      Map<String, dynamic> station,
      ) async {
    final double? latitude =
    (station['latitude'] as num?)
        ?.toDouble();

    final double? longitude =
    (station['longitude'] as num?)
        ?.toDouble();

    if (latitude == null ||
        longitude == null) {
      _showMessage(
        'Station coordinates are unavailable.',
      );

      return;
    }

    final String stationName =
        station['name']?.toString() ??
            'EV Charging Station';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NearbyPlacesScreen(
              chargingMinutes: 30,
              stationLatitude: latitude,
              stationLongitude: longitude,
              stationName: stationName,
            ),
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ==========================================================
  // DISTANCE
  // ==========================================================

  String _formatDistance(
      double distance,
      ) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(2)} km';
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.green,
            ),
            SizedBox(height: 18),
            Text(
              'Finding nearby charging stations...',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Getting real stations near your location',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return _buildError();
    }

    if (stations.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh:
      _refreshStations,
      color: Colors.green,
      child: ListView.builder(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(14),
        itemCount:
        stations.length + 1,
        itemBuilder:
            (context, index) {
          if (index == 0) {
            return _buildHeader();
          }

          return _buildStationCard(
            stations[index - 1],
            index - 1,
          );
        },
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.all(10),
            decoration:
            BoxDecoration(
              color:
              Colors.green.shade50,
              shape:
              BoxShape.circle,
            ),
            child: Icon(
              Icons.ev_station,
              color:
              Colors.green.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nearby EV Stations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stations.length} real stations within 30 km',
                  style:
                  const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATION CARD
  // ==========================================================

  Widget _buildStationCard(
      Map<String, dynamic> station,
      int index,
      ) {
    final String name =
        station['name']?.toString() ??
            'EV Charging Station';

    final String operator =
        station['operator']?.toString() ??
            'EV Charging Network';

    final String address =
        station['address']?.toString() ??
            'Location available';

    final String charger =
        station['charger']?.toString() ??
            'EV Charger';

    final String power =
        station['power']?.toString() ??
            'Available';

    final double distance =
        (station['distanceKm'] as num?)
            ?.toDouble() ??
            0;

    final double quality =
        (station['qualityScore'] as num?)
            ?.toDouble() ??
            0;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: index == 0
            ? Border.all(
          color:
          Colors.green.shade400,
          width: 1.5,
        )
            : null,
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          if (index == 0)
            Container(
              margin:
              const EdgeInsets.only(
                bottom: 10,
              ),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.green.shade100,
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                'NEAREST STATION',
                style: TextStyle(
                  color:
                  Colors.green.shade800,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.all(10),
                decoration:
                BoxDecoration(
                  color:
                  Colors.green.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  Icons.ev_station,
                  color:
                  Colors.green.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      operator,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                        Colors.green.shade700,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDistance(
                  distance,
                ),
                style: TextStyle(
                  color:
                  Colors.green.shade700,
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(
                Icons.electric_bolt,
                charger,
              ),
              _infoChip(
                Icons.power,
                power,
              ),
              _infoChip(
                Icons.star_outline,
                'Quality '
                    '${quality.toStringAsFixed(0)}%',
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child:
                ElevatedButton.icon(
                  onPressed: () {
                    _navigateToStation(
                      station,
                    );
                  },
                  icon: const Icon(
                    Icons.navigation,
                    size: 18,
                  ),
                  label:
                  const Text(
                    'Navigate',
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.green.shade700,
                    foregroundColor:
                    Colors.white,
                    elevation: 0,
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                OutlinedButton.icon(
                  onPressed: () {
                    _exploreNearby(
                      station,
                    );
                  },
                  icon: Icon(
                    Icons.explore_outlined,
                    size: 18,
                    color:
                    Colors.green.shade700,
                  ),
                  label: Text(
                    'Explore Nearby',
                    style: TextStyle(
                      color:
                      Colors.green.shade700,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  style:
                  OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                      Colors.green.shade700,
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFO CHIP
  // ==========================================================

  Widget _infoChip(
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
        Colors.grey.shade100,
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color:
            Colors.green.shade700,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style:
            const TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color:
              Colors.red.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load stations',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage.isEmpty
                  ? 'Unable to get real charging stations right now.'
                  : errorMessage,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
              _loadStations,
              icon:
              const Icon(Icons.refresh),
              label:
              const Text('Try Again'),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.green.shade700,
                foregroundColor:
                Colors.white,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh:
      _refreshStations,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
            MediaQuery.of(context)
                .size
                .height *
                0.30,
          ),
          const Icon(
            Icons.ev_station,
            size: 70,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'No charging stations found.',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Pull down to search again.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text(
          'Nearby Charging Stations',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
        backgroundColor:
        Colors.green.shade700,
        foregroundColor:
        Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed:
            isLoading
                ? null
                : _refreshStations,
            icon:
            const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}