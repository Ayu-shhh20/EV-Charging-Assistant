class VehicleModel {
  final int? userId;
  final int? vehicleId;

  final String userName;
  final String vehicleName;
  final double batteryCapacity;
  final int currentBattery;
  final int range;
  final String chargingType;

  VehicleModel({
    this.userId,
    this.vehicleId,
    required this.userName,
    required this.vehicleName,
    required this.batteryCapacity,
    required this.currentBattery,
    required this.range,
    required this.chargingType,
  });
}