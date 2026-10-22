import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';
import '../services/firebase_service.dart';
import '../services/vehicle_service.dart';

class VehicleInputScreen extends StatefulWidget {
  const VehicleInputScreen({super.key});

  @override
  State<VehicleInputScreen> createState() =>
      _VehicleInputScreenState();
}

class _VehicleInputScreenState
    extends State<VehicleInputScreen> {
  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController vehicleNameController =
  TextEditingController();

  final TextEditingController batteryController =
  TextEditingController();

  final TextEditingController capacityController =
  TextEditingController();

  String chargingType = 'Fast Charging';

  bool isSaving = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadVehicleData();
  }

  // ============================================================
  // LOAD PREVIOUS VEHICLE DATA
  // ============================================================

  Future<void> _loadVehicleData() async {
    try {
      // First load the locally available data.
      final localVehicle =
      VehicleService.getVehicleData();

      if (localVehicle.userName.isNotEmpty ||
          localVehicle.vehicleName.isNotEmpty) {
        _setFields(localVehicle);
      }

      // Then try to load the latest data from Firebase.
      final VehicleModel? firebaseVehicle =
      await FirebaseService.getVehicle();

      if (firebaseVehicle != null) {
        _setFields(firebaseVehicle);

        // Keep local storage synchronized with Firebase.
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
    } catch (e) {
      debugPrint(
        'Firebase vehicle load failed: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _setFields(VehicleModel vehicle) {
    nameController.text =
        vehicle.userName;

    vehicleNameController.text =
        vehicle.vehicleName;

    batteryController.text =
        vehicle.currentBattery.toString();

    capacityController.text =
        vehicle.batteryCapacity.toString();

    chargingType =
        vehicle.chargingType;
  }

  @override
  void dispose() {
    nameController.dispose();
    vehicleNameController.dispose();
    batteryController.dispose();
    capacityController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE VEHICLE
  // ============================================================

  Future<void> _saveVehicle() async {
    if (isSaving) {
      return;
    }

    final String userName =
    nameController.text.trim();

    final String vehicleName =
    vehicleNameController.text.trim();

    final int? battery =
    int.tryParse(
      batteryController.text.trim(),
    );

    final double? capacity =
    double.tryParse(
      capacityController.text.trim(),
    );

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (userName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your name.',
          ),
        ),
      );

      return;
    }

    if (vehicleName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your vehicle name.',
          ),
        ),
      );

      return;
    }

    if (battery == null ||
        battery < 0 ||
        battery > 100) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid battery percentage.',
          ),
        ),
      );

      return;
    }

    if (capacity == null ||
        capacity <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid battery capacity.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // START SAVING
    // ==========================================================

    setState(() {
      isSaving = true;
    });

    try {
      // ========================================================
      // CALCULATE RANGE
      // ========================================================

      final int estimatedRange =
      (capacity *
          battery /
          100 *
          7)
          .round();

      // ========================================================
      // CREATE VEHICLE MODEL
      // ========================================================

      final VehicleModel vehicle =
      VehicleModel(
        userId: null,
        vehicleId: null,
        userName: userName,
        vehicleName: vehicleName,
        batteryCapacity: capacity,
        currentBattery: battery,
        range: estimatedRange,
        chargingType: chargingType,
      );

      // ========================================================
      // 1. SAVE TO FIREBASE
      // ========================================================

      await FirebaseService.saveVehicle(
        vehicle: vehicle,
      );

      // ========================================================
      // 2. SAVE LOCALLY
      // ========================================================

      await VehicleService.saveVehicleData(
        userName: userName,
        vehicleName: vehicleName,
        batteryCapacity: capacity,
        currentBattery: battery,
        chargingType: chargingType,
      );

      // ========================================================
      // SUCCESS
      // ========================================================

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Profile and vehicle saved successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      // ========================================================
      // ERROR
      // ========================================================

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Profile & vehicle detail save failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xff0B0F0D),

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,

        title: const Text(
          'Profile & Vehicle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.greenAccent,
        ),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            const Text(
              'Your Profile',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Personal & Vehicle Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // ==================================================
            // NAME
            // ==================================================

            _inputField(
              controller:
              nameController,
              label:
              'Your Name',
              hint:
              'Example: Ayush Gupta',
              icon:
              Icons.person,
              keyboardType:
              TextInputType.name,
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // VEHICLE NAME
            // ==================================================

            _inputField(
              controller:
              vehicleNameController,
              label:
              'Vehicle Name',
              hint:
              'Example: Tata Nexon EV',
              icon:
              Icons.directions_car,
              keyboardType:
              TextInputType.text,
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // BATTERY
            // ==================================================

            _inputField(
              controller:
              batteryController,
              label:
              'Current Battery (%)',
              hint:
              'Example: 78',
              icon:
              Icons.battery_charging_full,
              keyboardType:
              TextInputType.number,
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // CAPACITY
            // ==================================================

            _inputField(
              controller:
              capacityController,
              label:
              'Battery Capacity (kWh)',
              hint:
              'Example: 40.5',
              icon:
              Icons.battery_full,
              keyboardType:
              const TextInputType
                  .numberWithOptions(
                decimal: true,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // CHARGING TYPE
            // ==================================================

            const Text(
              'Charging Type',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Container(
              width: double.infinity,

              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 15,
              ),

              decoration:
              BoxDecoration(
                color:
                const Color(
                    0xff151B18),

                borderRadius:
                BorderRadius
                    .circular(
                  15,
                ),

                border: Border.all(
                  color: Colors
                      .greenAccent
                      .withValues(
                    alpha: 0.2,
                  ),
                ),
              ),

              child:
              DropdownButtonHideUnderline(
                child:
                DropdownButton<
                    String>(
                  value:
                  chargingType,

                  dropdownColor:
                  const Color(
                      0xff151B18),

                  iconEnabledColor:
                  Colors
                      .greenAccent,

                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                  ),

                  items: const [
                    DropdownMenuItem(
                      value:
                      'Fast Charging',
                      child: Text(
                        'Fast Charging',
                      ),
                    ),

                    DropdownMenuItem(
                      value:
                      'Slow Charging',
                      child: Text(
                        'Slow Charging',
                      ),
                    ),
                  ],

                  onChanged:
                  isSaving
                      ? null
                      : (value) {
                    if (value ==
                        null) {
                      return;
                    }

                    setState(() {
                      chargingType =
                          value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            // ==================================================
            // SAVE BUTTON
            // ==================================================

            SizedBox(
              width:
              double.infinity,

              child:
              ElevatedButton.icon(
                onPressed:
                isSaving
                    ? null
                    : _saveVehicle,

                icon: isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.black,
                  ),
                )
                    : const Icon(
                  Icons.save,
                ),

                label: Text(
                  isSaving
                      ? 'Saving all the credentials...'
                      : 'Save Details',

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
                  Colors.greenAccent,

                  foregroundColor:
                  Colors.black,

                  disabledBackgroundColor:
                  Colors
                      .greenAccent
                      .withValues(
                    alpha: 0.5,
                  ),

                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 16,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      15,
                    ),
                  ),
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

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _inputField({
    required TextEditingController
    controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          label,
          style:
          const TextStyle(
            color:
            Colors.white70,
            fontSize: 14,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        TextField(
          controller:
          controller,

          keyboardType:
          keyboardType,

          style:
          const TextStyle(
            color:
            Colors.white,
          ),

          decoration:
          InputDecoration(
            hintText:
            hint,

            hintStyle:
            const TextStyle(
              color:
              Colors.white38,
            ),

            prefixIcon:
            Icon(
              icon,
              color:
              Colors.greenAccent,
            ),

            filled:
            true,

            fillColor:
            const Color(
                0xff151B18),

            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                15,
              ),

              borderSide:
              BorderSide(
                color: Colors
                    .greenAccent
                    .withValues(
                  alpha: 0.15,
                ),
              ),
            ),

            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                15,
              ),

              borderSide:
              const BorderSide(
                color:
                Colors.greenAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}