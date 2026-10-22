import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/places_service.dart';

class NearbyPlacesScreen extends StatefulWidget {
  final int chargingMinutes;
  final double stationLatitude;
  final double stationLongitude;
  final String stationName;

  const NearbyPlacesScreen({
    super.key,
    required this.chargingMinutes,
    required this.stationLatitude,
    required this.stationLongitude,
    required this.stationName,
  });

  @override
  State<NearbyPlacesScreen> createState() =>
      _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState
    extends State<NearbyPlacesScreen> {
  final PlacesService placesService =
  PlacesService();

  List<Map<String, dynamic>> places = [];

  bool loading = true;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    _loadPlaces();
  }

  // ============================================================
  // LOAD NEARBY PLACES
  // ============================================================

  Future<void> _loadPlaces() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      final List<Map<String, dynamic>> result =
      await placesService
          .getPlacesNearChargingStation(
        latitude: widget.stationLatitude,
        longitude: widget.stationLongitude,
        chargingMinutes: widget.chargingMinutes,
      )
          .timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        places = result;
        loading = false;
      });
    } catch (e) {
      debugPrint(
        'Nearby places error: $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
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
  // REFRESH
  // ============================================================

  Future<void> _refreshPlaces() async {
    await _loadPlaces();
  }

  // ============================================================
  // NAVIGATE TO PLACE
  // ============================================================

  Future<void> _navigateToPlace(
      Map<String, dynamic> place) async {
    final double? latitude =
    (place['latitude'] as num?)?.toDouble();

    final double? longitude =
    (place['longitude'] as num?)?.toDouble();

    final String placeName =
        place['name']?.toString() ??
            'Nearby Place';

    if (latitude == null ||
        longitude == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location coordinates are not available.',
          ),
        ),
      );

      return;
    }

    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/'
          '?api=1'
          '&destination=$latitude,$longitude'
          '&travelmode=walking',
    );

    try {
      final bool launched =
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open Google Maps for $placeName.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Google Maps navigation error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open Google Maps.',
          ),
        ),
      );
    }
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

        elevation: 0,

        title: const Text(
          'Nearby Places',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
            loading
                ? null
                : _refreshPlaces,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.greenAccent,
            ),

            SizedBox(height: 20),

            Text(
              'Finding nearby places...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Finding useful places while your EV charges',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    if (places.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh:
      _refreshPlaces,

      color:
      Colors.greenAccent,

      backgroundColor:
      const Color(0xff151B18),

      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        padding:
        const EdgeInsets.all(16),

        children: [
          _buildStationHeader(),

          const SizedBox(height: 14),

          _buildChargingInfo(),

          const SizedBox(height: 16),

          Text(
            '${places.length} nearby places',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ...places.map(
                (place) =>
                _buildPlaceCard(place),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATION HEADER
  // ============================================================

  Widget _buildStationHeader() {
    return Container(
      padding:
      const EdgeInsets.all(17),

      decoration:
      BoxDecoration(
        color:
        const Color(0xff151B18),

        borderRadius:
        BorderRadius.circular(18),

        border: Border.all(
          color:
          Colors.greenAccent
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
              color:
              Colors.greenAccent
                  .withValues(alpha: 0.12),

              shape:
              BoxShape.circle,
            ),

            child: const Icon(
              Icons.ev_station,
              color:
              Colors.greenAccent,
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
                  'Charging Station',
                  style: TextStyle(
                    color:
                    Colors.white54,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.stationName,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
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
  // CHARGING INFORMATION
  // ============================================================

  Widget _buildChargingInfo() {
    return Container(
      padding:
      const EdgeInsets.all(15),

      decoration:
      BoxDecoration(
        color:
        const Color(0xff151B18),

        borderRadius:
        BorderRadius.circular(16),

        border: Border.all(
          color:
          Colors.white
              .withValues(alpha: 0.08),
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.bolt,
            color:
            Colors.greenAccent,
            size: 25,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                const Text(
                  'Estimated charging time',
                  style: TextStyle(
                    color:
                    Colors.white54,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${widget.chargingMinutes} minutes',
                  style: const TextStyle(
                    color:
                    Colors.white,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.explore,
            color:
            Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PLACE CARD
  // ============================================================

  Widget _buildPlaceCard(
      Map<String, dynamic> place) {
    final String name =
    (place['name'] ??
        'Unknown Place')
        .toString();

    final String type =
    (place['type'] ??
        'Place')
        .toString();

    final double distance =
        (place['distanceKm']
        as num?)
            ?.toDouble() ??
            0;

    final int walkingMinutes =
        (place['walkingMinutes']
        as num?)
            ?.toInt() ??
            0;

    final bool recommended =
        place['recommended'] ==
            true;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
      const EdgeInsets.all(16),

      decoration:
      BoxDecoration(
        color:
        const Color(0xff151B18),

        borderRadius:
        BorderRadius.circular(18),

        border: Border.all(
          color: recommended
              ? Colors.greenAccent
              : Colors.white12,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
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
                  Colors.greenAccent
                      .withValues(alpha: 0.10),

                  borderRadius:
                  BorderRadius.circular(12),
                ),

                child: Icon(
                  _getPlaceIcon(type),
                  color:
                  Colors.greenAccent,
                  size: 27,
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
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      type,
                      style:
                      const TextStyle(
                        color:
                        Colors.greenAccent,
                        fontSize: 13,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color:
                          Colors.white54,
                          size: 16,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          _formatDistance(
                            distance,
                          ),
                          style:
                          const TextStyle(
                            color:
                            Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Icon(
                          Icons.directions_walk,
                          color:
                          Colors.white54,
                          size: 16,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          '$walkingMinutes min walk',
                          style:
                          const TextStyle(
                            color:
                            Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    if (recommended)
                      Container(
                        margin:
                        const EdgeInsets.only(
                          top: 9,
                        ),

                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),

                        decoration:
                        BoxDecoration(
                          color:
                          Colors.greenAccent
                              .withValues(
                            alpha: 0.10,
                          ),

                          borderRadius:
                          BorderRadius.circular(
                            8,
                          ),
                        ),

                        child:
                        const Text(
                          '✓ Recommended during charging',
                          style:
                          TextStyle(
                            color:
                            Colors.greenAccent,
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // NAVIGATE BUTTON
          // ======================================================

          SizedBox(
            width: double.infinity,

            child: ElevatedButton.icon(
              onPressed: () {
                _navigateToPlace(
                  place,
                );
              },

              icon: const Icon(
                Icons.navigation,
                size: 19,
              ),

              label: const Text(
                'Navigate',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 14,
                ),
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

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PLACE ICON
  // ============================================================

  IconData _getPlaceIcon(
      String type) {
    final String value =
    type.toLowerCase();

    if (value.contains('cafe') ||
        value.contains('coffee')) {
      return Icons.local_cafe;
    }

    if (value.contains('restaurant') ||
        value.contains('food')) {
      return Icons.restaurant;
    }

    if (value.contains('shop') ||
        value.contains('mall') ||
        value.contains('market')) {
      return Icons.shopping_bag;
    }

    if (value.contains('hotel') ||
        value.contains('hostel')) {
      return Icons.hotel;
    }

    if (value.contains('fuel') ||
        value.contains('petrol') ||
        value.contains('gas')) {
      return Icons.local_gas_station;
    }

    if (value.contains('store')) {
      return Icons.store;
    }

    if (value.contains('hospital') ||
        value.contains('medical')) {
      return Icons.local_hospital;
    }

    if (value.contains('bank')) {
      return Icons.account_balance;
    }

    if (value.contains('parking')) {
      return Icons.local_parking;
    }

    return Icons.place;
  }

  // ============================================================
  // DISTANCE FORMAT
  // ============================================================

  String _formatDistance(
      double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(2)} km';
  }

  // ============================================================
  // EMPTY VIEW
  // ============================================================

  Widget _buildEmptyView() {
    return RefreshIndicator(
      onRefresh:
      _refreshPlaces,

      color:
      Colors.greenAccent,

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
            Icons.explore_off,
            color:
            Colors.white38,
            size: 70,
          ),

          const SizedBox(height: 18),

          const Center(
            child: Text(
              'No nearby places found.',
              style: TextStyle(
                color:
                Colors.white,
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Padding(
              padding:
              EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: Text(
                'Pull down to search again.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color:
                  Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildErrorView() {
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
              Colors.redAccent
                  .withValues(
                alpha: 0.8,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load nearby places',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                Colors.white,
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              errorMessage.isEmpty
                  ? 'Please try again.'
                  : errorMessage,
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                color:
                Colors.white54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed:
              _refreshPlaces,

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
}