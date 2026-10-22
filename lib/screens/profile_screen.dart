import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import 'vehicle_input_screen.dart';

class profileScreen extends StatefulWidget {
  const profileScreen({super.key});

  @override
  State<profileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<profileScreen> {

  VehicleModel? vehicle;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  void _loadVehicle() {
    setState(() {
      vehicle =
          VehicleService.getVehicleData();
    });
  }

  Future<void> _editProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const VehicleInputScreen(),
      ),
    );

    _loadVehicle();
  }

  @override
  Widget build(BuildContext context) {

    if (vehicle == null) {
      return const Scaffold(
        backgroundColor:
        Color(0xff0B0F0D),

        body: Center(
          child:
          CircularProgressIndicator(
            color: Colors.greenAccent,
          ),
        ),
      );
    }

    final String displayName =
    vehicle!.userName.isEmpty
        ? 'User'
        : vehicle!.userName;

    final String displayVehicle =
    vehicle!.vehicleName.isEmpty
        ? 'Vehicle Not Set'
        : vehicle!.vehicleName;

    return Scaffold(
      backgroundColor:
      const Color(0xff0B0F0D),

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,

        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // PROFILE HEADER
            Container(
              width: double.infinity,

              padding:
              const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color:
                const Color(0xff151B18),

                borderRadius:
                BorderRadius.circular(22),

                border: Border.all(
                  color: Colors.greenAccent
                      .withValues(alpha: 0.25),
                ),
              ),

              child: Column(
                children: [

                  Container(
                    width: 80,
                    height: 80,

                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape.circle,

                      color: Colors
                          .greenAccent
                          .withValues(
                        alpha: 0.12,
                      ),

                      border: Border.all(
                        color:
                        Colors.greenAccent,
                        width: 2,
                      ),
                    ),

                    child: const Icon(
                      Icons.person,
                      color:
                      Colors.greenAccent,
                      size: 42,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Text(
                    displayName,
                    style:
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    displayVehicle,
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

            const SizedBox(
              height: 22,
            ),

            // EDIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,

              child:
              ElevatedButton.icon(
                onPressed:
                _editProfile,

                icon: const Icon(
                  Icons.edit,
                ),

                label: const Text(
                  'Edit Profile & Vehicle',
                ),

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.greenAccent,

                  foregroundColor:
                  Colors.black,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                  ),

                  textStyle:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // VEHICLE INFORMATION
            const Text(
              'Vehicle Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Container(
              width: double.infinity,

              padding:
              const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color:
                const Color(0xff151B18),

                borderRadius:
                BorderRadius.circular(18),
              ),

              child: Column(
                children: [

                  _infoRow(
                    Icons.directions_car,
                    'Vehicle',
                    displayVehicle,
                  ),

                  const Divider(
                    color: Colors.white12,
                    height: 24,
                  ),

                  _infoRow(
                    Icons.battery_charging_full,
                    'Battery Capacity',
                    '${vehicle!.batteryCapacity} kWh',
                  ),

                  const Divider(
                    color: Colors.white12,
                    height: 24,
                  ),

                  _infoRow(
                    Icons.battery_std,
                    'Current Battery',
                    '${vehicle!.currentBattery}%',
                  ),

                  const Divider(
                    color: Colors.white12,
                    height: 24,
                  ),

                  _infoRow(
                    Icons.speed,
                    'Estimated Range',
                    '${vehicle!.range} km',
                  ),

                  const Divider(
                    color: Colors.white12,
                    height: 24,
                  ),

                  _infoRow(
                    Icons.bolt,
                    'Charging Type',
                    vehicle!.chargingType,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // APPLICATION STATUS
            const Text(
              'Application Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Container(
              width: double.infinity,

              padding:
              const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color:
                const Color(0xff151B18),

                borderRadius:
                BorderRadius.circular(18),
              ),

              child: Column(
                children: [

                  _statusRow(
                    Icons.auto_awesome,
                    'AI Assistant',
                    'Active',
                  ),

                  const Divider(
                    color: Colors.white12,
                    height: 24,
                  ),

                  _statusRow(
                    Icons.location_on,
                    'Location Services',
                    'Available',
                  ),

                  const Divider(
                    color: Colors.white12,
                    height: 24,
                  ),

                  _statusRow(
                    Icons.ev_station,
                    'Charging Recommendation',
                    'Enabled',
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ABOUT
            Container(
              width: double.infinity,

              padding:
              const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color:
                const Color(0xff101814),

                borderRadius:
                BorderRadius.circular(18),

                border: Border.all(
                  color: Colors.greenAccent
                      .withValues(
                    alpha: 0.20,
                  ),
                ),
              ),

              child: const Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Icon(
                    Icons.info_outline,
                    color:
                    Colors.greenAccent,
                    size: 28,
                  ),

                  SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Text(
                          'About the Application',
                          style:
                          TextStyle(
                            color:
                            Colors.greenAccent,
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        SizedBox(
                          height: 7,
                        ),

                        Text(
                          'AI EV Charging Assistant helps EV users find charging stations, predict charging requirements, estimate charging cost and discover useful places near charging stations.',
                          style:
                          TextStyle(
                            color:
                            Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Center(
              child: Text(
                'AI EV Charging Assistant • Version 1.0',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [

        Icon(
          icon,
          color: Colors.greenAccent,
          size: 27,
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

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
                height: 4,
              ),

              Text(
                value,
                style:
                const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
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

  Widget _statusRow(
      IconData icon,
      String title,
      String status,
      ) {
    return Row(
      children: [

        Icon(
          icon,
          color: Colors.greenAccent,
          size: 27,
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: Text(
            title,
            style:
            const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),

        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),

          decoration:
          BoxDecoration(
            color: Colors.greenAccent
                .withValues(
              alpha: 0.10,
            ),

            borderRadius:
            BorderRadius.circular(20),
          ),

          child: Text(
            status,
            style:
            const TextStyle(
              color:
              Colors.greenAccent,
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}