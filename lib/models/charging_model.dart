class ChargingModel {
  final String stationName;
  final String chargerType;
  final double energyUsed;
  final int chargingTime;
  final double cost;

  final DateTime dateTime;
  final bool completed;
  final int startBattery;
  final int endBattery;

  ChargingModel({
    required this.stationName,
    required this.chargerType,
    required this.energyUsed,
    required this.chargingTime,
    required this.cost,
    DateTime? dateTime,
    this.completed = true,
    this.startBattery = 0,
    this.endBattery = 100,
  }) : dateTime = dateTime ?? DateTime.now();
}