import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';

import 'services/firebase_service.dart';
import 'services/vehicle_service.dart';

import 'screens/home_screen.dart';
import 'screens/charging_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const EVChargingAssistant(),
  );
}

class EVChargingAssistant extends StatefulWidget {
  const EVChargingAssistant({super.key});

  @override
  State<EVChargingAssistant> createState() =>
      _EVChargingAssistantState();
}

class _EVChargingAssistantState
    extends State<EVChargingAssistant> {
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    initializeApp();
  }

  Future<void> initializeApp() async {
    try {
      // =========================================================
      // 1. INITIALIZE FIREBASE
      // =========================================================

      await firebase_core.Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // =========================================================
      // 2. INITIALIZE FIREBASE APP CHECK
      // =========================================================
      //
      // DEBUG PROVIDER IS FOR LOCAL DEVELOPMENT / TESTING.
      // Do NOT use this configuration for production release.
      //

      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidDebugProvider(),
      );

      // =========================================================
      // 3. INITIALIZE YOUR FIREBASE SERVICE
      // =========================================================

      await FirebaseService.initializeUser();

      // =========================================================
      // 4. LOAD LOCAL VEHICLE DATA
      // =========================================================

      await VehicleService.initialize();

      // =========================================================
      // 5. APP READY
      // =========================================================

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      debugPrint(
        'APP INITIALIZATION ERROR: $e',
      );

      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // =========================================================
    // LOADING SCREEN
    // =========================================================

    if (loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Starting AI EV Charging Assistant...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // =========================================================
    // ERROR SCREEN
    // =========================================================

    if (error.isNotEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Firebase startup error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    error,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        loading = true;
                        error = '';
                      });

                      initializeApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // =========================================================
    // MAIN APP
    // =========================================================

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'AI EV Charging Assistant',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),

      home: const MainNavigation(),
    );
  }
}

// =============================================================
// MAIN NAVIGATION
// =============================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() =>
      _MainNavigationState();
}

class _MainNavigationState
    extends State<MainNavigation> {
  int currentIndex = 0;

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();

      case 1:
        return const ChargingScreen();

      case 2:
        return const MapScreen();

      case 3:
        return const profileScreen();

      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(currentIndex),

      bottomNavigationBar:
      BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        selectedItemColor:
        Colors.green,

        unselectedItemColor:
        Colors.grey,

        type:
        BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.electric_bolt,
            ),
            label: 'Charging',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.location_on,
            ),
            label: 'Map',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}