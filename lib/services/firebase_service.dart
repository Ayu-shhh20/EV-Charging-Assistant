import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/vehicle_model.dart';
import '../models/charging_model.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // AUTHENTICATION
  // ------------------------------------------------------------

  static Future<User> initializeUser() async {
    User? user = _auth.currentUser;

    if (user == null) {
      final UserCredential credential =
      await _auth.signInAnonymously();

      user = credential.user;
    }

    if (user == null) {
      throw Exception(
        'Unable to create Firebase anonymous user.',
      );
    }

    // Create/update the user's main document
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'uid': user.uid,
        'lastActive': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return user;
  }

  static String getUserUid() {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Firebase user is not initialized.',
      );
    }

    return user.uid;
  }

  // ------------------------------------------------------------
  // VEHICLE
  // ------------------------------------------------------------

  static Future<void> saveVehicle({
    required VehicleModel vehicle,
  }) async {
    final String uid = getUserUid();

    final int estimatedRange =
    (vehicle.batteryCapacity *
        vehicle.currentBattery /
        100 *
        7)
        .round();

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .doc('primary')
        .set(
      {
        'userName': vehicle.userName,
        'vehicleName': vehicle.vehicleName,
        'batteryCapacity': vehicle.batteryCapacity,
        'currentBattery': vehicle.currentBattery,
        'range': estimatedRange,
        'chargingType': vehicle.chargingType,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Also keep the user's name in the main user document.
    await _firestore
        .collection('users')
        .doc(uid)
        .set(
      {
        'uid': uid,
        'userName': vehicle.userName,
        'lastActive': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<VehicleModel?> getVehicle() async {
    final String uid = getUserUid();

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .doc('primary')
        .get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data =
    snapshot.data();

    if (data == null) {
      return null;
    }

    return VehicleModel(
      userId: null,
      vehicleId: null,
      userName:
      data['userName']?.toString() ?? '',
      vehicleName:
      data['vehicleName']?.toString() ?? '',
      batteryCapacity:
      (data['batteryCapacity'] as num?)
          ?.toDouble() ??
          40.5,
      currentBattery:
      (data['currentBattery'] as num?)
          ?.toInt() ??
          80,
      range:
      (data['range'] as num?)
          ?.toInt() ??
          280,
      chargingType:
      data['chargingType']?.toString() ??
          'Fast Charging',
    );
  }

  // ------------------------------------------------------------
  // CHARGING SESSION
  // ------------------------------------------------------------

  static Future<String> saveChargingSession({
    required String stationName,
    required String chargerType,
    required double energyUsed,
    required int chargingTime,
    required double cost,
    required int startBattery,
    required int endBattery,
    bool completed = true,
  }) async {
    final String uid = getUserUid();

    final DocumentReference<Map<String, dynamic>>
    document =
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('chargingSessions')
        .add(
      {
        'stationName': stationName,
        'chargerType': chargerType,
        'energyUsed': energyUsed,
        'chargingTime': chargingTime,
        'cost': cost,
        'startBattery': startBattery,
        'endBattery': endBattery,
        'completed': completed,
        'dateTime': FieldValue.serverTimestamp(),
      },
    );

    return document.id;
  }

  // ------------------------------------------------------------
  // GET CHARGING HISTORY
  // ------------------------------------------------------------

  static Future<List<ChargingModel>>
  getChargingSessions() async {
    final String uid = getUserUid();

    final QuerySnapshot<Map<String, dynamic>>
    snapshot =
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('chargingSessions')
        .orderBy(
      'dateTime',
      descending: true,
    )
        .get();

    return snapshot.docs.map((doc) {
      final Map<String, dynamic> data =
      doc.data();

      DateTime dateTime =
      DateTime.now();

      final dynamic timestamp =
      data['dateTime'];

      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      }

      return ChargingModel(
        stationName:
        data['stationName']?.toString() ??
            'Unknown Station',
        chargerType:
        data['chargerType']?.toString() ??
            'Unknown Charger',
        energyUsed:
        (data['energyUsed'] as num?)
            ?.toDouble() ??
            0,
        chargingTime:
        (data['chargingTime'] as num?)
            ?.toInt() ??
            0,
        cost:
        (data['cost'] as num?)
            ?.toDouble() ??
            0,
        dateTime: dateTime,
        completed:
        data['completed'] as bool? ?? true,
        startBattery:
        (data['startBattery'] as num?)
            ?.toInt() ??
            0,
        endBattery:
        (data['endBattery'] as num?)
            ?.toInt() ??
            100,
      );
    }).toList();
  }

  // ------------------------------------------------------------
  // DELETE ALL USER DATA
  // ------------------------------------------------------------

  static Future<void> deleteAllUserData() async {
    final String uid = getUserUid();

    final CollectionReference<Map<String, dynamic>>
    sessions =
    _firestore
        .collection('users')
        .doc(uid)
        .collection('chargingSessions');

    final QuerySnapshot<Map<String, dynamic>>
    sessionSnapshot =
    await sessions.get();

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
    doc in sessionSnapshot.docs) {
      await doc.reference.delete();
    }

    final CollectionReference<Map<String, dynamic>>
    vehicles =
    _firestore
        .collection('users')
        .doc(uid)
        .collection('vehicles');

    final QuerySnapshot<Map<String, dynamic>>
    vehicleSnapshot =
    await vehicles.get();

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
    doc in vehicleSnapshot.docs) {
      await doc.reference.delete();
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .delete();
  }
}