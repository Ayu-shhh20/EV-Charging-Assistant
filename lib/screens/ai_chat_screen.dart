import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';
import '../models/charging_model.dart';
import '../services/vehicle_service.dart';
import '../services/firebase_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  final List<Map<String, String>> _messages = [];

  VehicleModel? _vehicle;
  List<ChargingModel> _chargingHistory = [];

  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      VehicleModel? vehicle;

      try {
        vehicle = await FirebaseService.getVehicle();
      } catch (_) {
        vehicle = VehicleService.getVehicleData();
      }

      List<ChargingModel> history = [];

      try {
        history =
        await FirebaseService.getChargingSessions();
      } catch (_) {
        history = [];
      }

      if (!mounted) return;

      setState(() {
        _vehicle = vehicle;
        _chargingHistory = history;
        _loading = false;
      });

      if (_messages.isEmpty) {
        _addBotMessage(
          _welcomeMessage(),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _vehicle = VehicleService.getVehicleData();
        _chargingHistory = [];
        _loading = false;
      });

      _addBotMessage(
        'Hi! I am your EV Charging Assistant. '
            'Ask me about your battery, charging, range, '
            'charging cost, energy usage, or charging history.',
      );
    }
  }

  String _welcomeMessage() {
    final String name =
    (_vehicle?.userName ?? '').trim();

    if (name.isNotEmpty) {
      return 'Hi $name! 👋\n\n'
          'I am your AI EV Charging Assistant. '
          'I can help you with your battery, charging time, '
          'range, charging cost, energy usage and charging history.\n\n'
          'What would you like to know?';
    }

    return 'Hi! 👋\n\n'
        'I am your AI EV Charging Assistant. '
        'I can help you with your battery, charging time, '
        'range, charging cost, energy usage and charging history.\n\n'
        'What would you like to know?';
  }

  void _addBotMessage(String message) {
    _messages.add({
      'sender': 'bot',
      'message': message,
    });
  }

  void _addUserMessage(String message) {
    _messages.add({
      'sender': 'user',
      'message': message,
    });
  }

  Future<void> _sendMessage() async {
    final String message =
    _messageController.text.trim();

    if (message.isEmpty || _sending) {
      return;
    }

    _messageController.clear();

    setState(() {
      _addUserMessage(message);
      _sending = true;
    });

    _scrollToBottom();

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    final String response =
    _generateResponse(message);

    if (!mounted) return;

    setState(() {
      _addBotMessage(response);
      _sending = false;
    });

    _scrollToBottom();
  }

  void _sendSuggestion(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration:
        const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _generateResponse(String input) {
    final String message =
    input.toLowerCase().trim();

    final VehicleModel? vehicle = _vehicle;

    if (vehicle == null) {
      return 'I could not find your saved vehicle details. '
          'Please save your vehicle information first.';
    }

    /*
    ----------------------------------------------------
    GREETING
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'hello',
      'hi',
      'hey',
      'hii',
      'good morning',
      'good afternoon',
      'good evening',
    ])) {
      return 'Hello! 👋\n\n'
          'I am ready to help you with your EV charging.\n\n'
          'You can ask me about:\n'
          '• Battery status\n'
          '• Charging time\n'
          '• Charging cost\n'
          '• Range\n'
          '• Energy usage\n'
          '• Charging history';
    }

    /*
    ----------------------------------------------------
    BATTERY STATUS
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'battery status',
      'battery percentage',
      'battery percent',
      'battery level',
      'current battery',
      'how much battery',
      'battery remaining',
      'battery left',
    ])) {
      return '🔋 Battery Status\n\n'
          'Vehicle: ${vehicle.vehicleName}\n'
          'Current battery: ${vehicle.currentBattery}%\n'
          'Battery capacity: '
          '${vehicle.batteryCapacity.toStringAsFixed(1)} kWh\n'
          'Estimated range: ${vehicle.range} km\n\n'
          'Your current charging type is '
          '${vehicle.chargingType}.';
    }

    /*
    ----------------------------------------------------
    RANGE
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'range',
      'how far',
      'distance',
      'how many km',
      'kilometers',
      'kilometres',
    ])) {
      return '🚗 Estimated Range\n\n'
          'Vehicle: ${vehicle.vehicleName}\n'
          'Current battery: ${vehicle.currentBattery}%\n'
          'Estimated range: ${vehicle.range} km\n\n'
          'Actual range can vary depending on speed, '
          'traffic, road conditions, temperature, '
          'vehicle load and driving style.';
    }

    /*
    ----------------------------------------------------
    BATTERY CAPACITY
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'battery capacity',
      'capacity',
      'kwh',
      'how big is my battery',
    ])) {
      return '🔋 Battery Capacity\n\n'
          'Your ${vehicle.vehicleName} has a battery '
          'capacity of '
          '${vehicle.batteryCapacity.toStringAsFixed(1)} kWh.';
    }

    /*
    ----------------------------------------------------
    CHARGING TYPE
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'charger type',
      'charging type',
      'which charger',
      'what charger',
      'fast charging',
      'slow charging',
      'ac charger',
      'dc charger',
    ])) {
      return '⚡ Charging Information\n\n'
          'Your selected charging type is:\n'
          '${vehicle.chargingType}\n\n'
          'Fast charging generally charges the battery '
          'more quickly, while slower charging is usually '
          'better suited for longer parking periods.';
    }

    /*
    ----------------------------------------------------
    CHARGING TIME
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'charging time',
      'charge time',
      'how long',
      'how much time',
      'time to charge',
      'charging duration',
      'duration',
    ])) {
      final double missingPercentage =
      (100 - vehicle.currentBattery)
          .clamp(0, 100)
          .toDouble();

      final double energyRequired =
          vehicle.batteryCapacity *
              missingPercentage /
              100;

      double chargingPower;

      if (vehicle.chargingType
          .toLowerCase()
          .contains('fast')) {
        chargingPower = 50;
      } else {
        chargingPower = 7;
      }

      final double estimatedHours =
          energyRequired / chargingPower;

      final int minutes =
      (estimatedHours * 60).round();

      return '⚡ Estimated Charging Time\n\n'
          'Current battery: '
          '${vehicle.currentBattery}%\n'
          'Target battery: 100%\n'
          'Energy required: '
          '${energyRequired.toStringAsFixed(2)} kWh\n'
          'Charging type: '
          '${vehicle.chargingType}\n\n'
          'Estimated charging time: '
          '${_formatMinutes(minutes)}\n\n'
          'This is an estimate. Actual charging time '
          'depends on charger power, battery temperature, '
          'charging limits and the vehicle.';
    }

    /*
    ----------------------------------------------------
    ENERGY REQUIRED
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'energy required',
      'energy needed',
      'how much energy',
      'energy to charge',
      'kwh required',
      'electricity required',
      'power required',
    ])) {
      final double missingPercentage =
      (100 - vehicle.currentBattery)
          .clamp(0, 100)
          .toDouble();

      final double energy =
          vehicle.batteryCapacity *
              missingPercentage /
              100;

      return '⚡ Energy Required\n\n'
          'Current battery: ${vehicle.currentBattery}%\n'
          'Target battery: 100%\n'
          'Battery capacity: '
          '${vehicle.batteryCapacity.toStringAsFixed(1)} kWh\n\n'
          'Approximately '
          '${energy.toStringAsFixed(2)} kWh '
          'of energy would be needed to reach 100%.';
    }

    /*
    ----------------------------------------------------
    COST
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'cost',
      'price',
      'expense',
      'how much money',
      'charging bill',
      'charging cost',
      'cost to charge',
      'charge cost',
      'money',
    ])) {
      final double missingPercentage =
      (100 - vehicle.currentBattery)
          .clamp(0, 100)
          .toDouble();

      final double energy =
          vehicle.batteryCapacity *
              missingPercentage /
              100;

      // Approximate public charging electricity rate.
      // The app should not claim this is a live station price.
      const double approximateRate = 15;

      final double estimatedCost =
          energy * approximateRate;

      return '💰 Estimated Charging Cost\n\n'
          'Current battery: ${vehicle.currentBattery}%\n'
          'Energy required: '
          '${energy.toStringAsFixed(2)} kWh\n'
          'Illustrative energy rate: ₹'
          '${approximateRate.toStringAsFixed(0)}/kWh\n\n'
          'Estimated cost: ₹'
          '${estimatedCost.toStringAsFixed(2)}\n\n'
          'Actual cost depends on the charging station, '
          'tariff and any additional fees.';
    }

    /*
    ----------------------------------------------------
    CHARGING HISTORY
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'history',
      'previous charging',
      'previous session',
      'past charging',
      'charging sessions',
      'my sessions',
      'last charging',
      'recent charging',
    ])) {
      return _chargingHistoryResponse();
    }

    /*
    ----------------------------------------------------
    TOTAL SPENDING
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'total spent',
      'total spending',
      'spent on charging',
      'how much have i spent',
      'total cost',
      'total charging cost',
      'money spent',
    ])) {
      if (_chargingHistory.isEmpty) {
        return '💰 You do not have any saved charging '
            'sessions yet.';
      }

      double totalCost = 0;

      for (final ChargingModel session
      in _chargingHistory) {
        totalCost += session.cost;
      }

      return '💰 Charging Spending\n\n'
          'Total sessions: '
          '${_chargingHistory.length}\n'
          'Total amount spent: ₹'
          '${totalCost.toStringAsFixed(2)}';
    }

    /*
    ----------------------------------------------------
    TOTAL ENERGY
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'total energy',
      'energy used',
      'energy consumed',
      'electricity used',
      'total kwh',
      'kwh used',
    ])) {
      if (_chargingHistory.isEmpty) {
        return '⚡ You do not have any saved charging '
            'sessions yet.';
      }

      double totalEnergy = 0;

      for (final ChargingModel session
      in _chargingHistory) {
        totalEnergy += session.energyUsed;
      }

      return '⚡ Energy Usage\n\n'
          'Total charging sessions: '
          '${_chargingHistory.length}\n'
          'Total energy used: '
          '${totalEnergy.toStringAsFixed(2)} kWh';
    }

    /*
    ----------------------------------------------------
    AVERAGE COST
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'average cost',
      'average charging cost',
      'average expense',
      'average spending',
    ])) {
      if (_chargingHistory.isEmpty) {
        return 'There are no saved charging sessions '
            'from which I can calculate an average.';
      }

      double totalCost = 0;

      for (final ChargingModel session
      in _chargingHistory) {
        totalCost += session.cost;
      }

      final double average =
          totalCost / _chargingHistory.length;

      return '📊 Average Charging Cost\n\n'
          'Sessions: ${_chargingHistory.length}\n'
          'Average cost per session: ₹'
          '${average.toStringAsFixed(2)}';
    }

    /*
    ----------------------------------------------------
    AVERAGE ENERGY
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'average energy',
      'average kwh',
      'average electricity',
    ])) {
      if (_chargingHistory.isEmpty) {
        return 'There are no saved charging sessions '
            'from which I can calculate an average.';
      }

      double totalEnergy = 0;

      for (final ChargingModel session
      in _chargingHistory) {
        totalEnergy += session.energyUsed;
      }

      final double average =
          totalEnergy / _chargingHistory.length;

      return '📊 Average Energy Usage\n\n'
          'Average energy per session: '
          '${average.toStringAsFixed(2)} kWh';
    }

    /*
    ----------------------------------------------------
    VEHICLE INFORMATION
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'my vehicle',
      'my car',
      'vehicle details',
      'vehicle information',
      'what vehicle',
      'which vehicle',
    ])) {
      return '🚗 Vehicle Information\n\n'
          'Vehicle: ${vehicle.vehicleName}\n'
          'Battery capacity: '
          '${vehicle.batteryCapacity.toStringAsFixed(1)} kWh\n'
          'Current battery: ${vehicle.currentBattery}%\n'
          'Estimated range: ${vehicle.range} km\n'
          'Charging type: ${vehicle.chargingType}';
    }

    /*
    ----------------------------------------------------
    LOW BATTERY
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'low battery',
      'battery low',
      'should i charge',
      'need charging',
      'need to charge',
      'charge now',
    ])) {
      if (vehicle.currentBattery <= 20) {
        return '⚠️ Your battery is currently at '
            '${vehicle.currentBattery}%.\n\n'
            'It would be a good idea to plan a charging '
            'session soon, especially before travelling '
            'a significant distance.';
      }

      if (vehicle.currentBattery <= 40) {
        return '🔋 Your battery is at '
            '${vehicle.currentBattery}%.\n\n'
            'You still have some charge available, but '
            'you should consider charging if you have a '
            'long trip planned.';
      }

      return '🔋 Your battery is currently at '
          '${vehicle.currentBattery}%.\n\n'
          'Your battery level is not particularly low. '
          'Your estimated range is ${vehicle.range} km.';
    }

    /*
    ----------------------------------------------------
    FULL CHARGE
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'fully charged',
      '100 percent',
      '100%',
      'full battery',
      'charge to 100',
    ])) {
      return '🔋 A full charge means reaching 100% '
          'battery.\n\n'
          'Your battery capacity is '
          '${vehicle.batteryCapacity.toStringAsFixed(1)} kWh.\n\n'
          'For everyday use, the ideal charging level '
          'can depend on the vehicle manufacturer and '
          'your driving requirements.';
    }

    /*
    ----------------------------------------------------
    BATTERY HEALTH
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'battery health',
      'health of battery',
      'battery degradation',
      'battery damage',
      'battery life',
    ])) {
      return '🔋 Battery Health\n\n'
          'I do not have direct battery-health sensor '
          'data from your vehicle, so I cannot give you '
          'an exact battery-health percentage.\n\n'
          'In general, excessive heat, repeated extreme '
          'discharge and improper charging practices can '
          'affect long-term battery performance.';
    }

    /*
    ----------------------------------------------------
    FAST / SLOW CHARGING
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'fast or slow',
      'fast vs slow',
      'fast charging better',
      'slow charging better',
      'difference between fast and slow',
      'difference between ac and dc',
    ])) {
      return '⚡ Fast vs Slow Charging\n\n'
          'Fast charging can significantly reduce '
          'charging time and is useful when you need to '
          'continue your journey quickly.\n\n'
          'Slower charging is more suitable when the '
          'vehicle will remain parked for a longer period.\n\n'
          'The appropriate option depends on your vehicle, '
          'charger compatibility and charging requirement.';
    }

    /*
    ----------------------------------------------------
    STATION
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'station',
      'charging station',
      'charger near me',
      'charging station near me',
      'nearby charger',
      'nearby station',
      'find charger',
      'find charging station',
    ])) {
      return '📍 Charging Stations\n\n'
          'Use the Map section of the app to search for '
          'nearby charging stations.\n\n'
          'I can help you understand charging requirements '
          'and compare charging information, but I should '
          'not claim that a particular station has live '
          'availability unless the app has received live '
          'station data.';
    }

    /*
    ----------------------------------------------------
    TRIP
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'trip',
      'travel',
      'journey',
      'long drive',
      'road trip',
      'can i reach',
    ])) {
      return '🛣️ Trip Planning\n\n'
          'Your current estimated range is '
          '${vehicle.range} km with '
          '${vehicle.currentBattery}% battery.\n\n'
          'For a longer trip, consider your total distance, '
          'traffic, driving conditions and charging-station '
          'availability before starting.';
    }

    /*
    ----------------------------------------------------
    HELP
    ----------------------------------------------------
    */

    if (_containsAny(message, [
      'help',
      'what can you do',
      'what do you know',
      'features',
      'commands',
    ])) {
      return '🤖 I can help you with:\n\n'
          '🔋 Battery status\n'
          '⚡ Charging time\n'
          '💰 Charging cost\n'
          '🚗 Vehicle information\n'
          '🛣️ Estimated range\n'
          '⚡ Energy requirements\n'
          '📊 Charging history\n'
          '💵 Total charging spending\n'
          '📍 Charging stations\n'
          '🔌 Fast vs slow charging\n'
          '🛣️ Trip planning\n\n'
          'Just ask me a question normally.';
    }

    /*
    ----------------------------------------------------
    DEFAULT RESPONSE
    ----------------------------------------------------
    */

    return 'I can help with your EV charging information. '
        'Try asking something like:\n\n'
        '• What is my current battery?\n'
        '• How much will charging cost?\n'
        '• How long will charging take?\n'
        '• What is my estimated range?\n'
        '• Show my charging history\n'
        '• How much energy have I used?\n'
        '• How much have I spent?\n'
        '• Which charger should I use?';
  }

  String _chargingHistoryResponse() {
    if (_chargingHistory.isEmpty) {
      return '📊 Charging History\n\n'
          'You do not have any saved charging sessions yet.';
    }

    double totalEnergy = 0;
    double totalCost = 0;
    int totalTime = 0;

    for (final ChargingModel session
    in _chargingHistory) {
      totalEnergy += session.energyUsed;
      totalCost += session.cost;
      totalTime += session.chargingTime;
    }

    final double averageCost =
        totalCost / _chargingHistory.length;

    final double averageEnergy =
        totalEnergy / _chargingHistory.length;

    final double averageTime =
        totalTime / _chargingHistory.length;

    final StringBuffer result =
    StringBuffer();

    result.writeln('📊 Charging History');
    result.writeln();
    result.writeln(
      'Total sessions: ${_chargingHistory.length}',
    );
    result.writeln(
      'Total energy: '
          '${totalEnergy.toStringAsFixed(2)} kWh',
    );
    result.writeln(
      'Total cost: ₹'
          '${totalCost.toStringAsFixed(2)}',
    );
    result.writeln(
      'Average energy: '
          '${averageEnergy.toStringAsFixed(2)} kWh/session',
    );
    result.writeln(
      'Average cost: ₹'
          '${averageCost.toStringAsFixed(2)}/session',
    );
    result.writeln(
      'Average charging time: '
          '${averageTime.toStringAsFixed(1)} minutes',
    );

    result.writeln();
    result.writeln('Recent sessions:');
    result.writeln();

    final int count =
    _chargingHistory.length > 5
        ? 5
        : _chargingHistory.length;

    for (int i = 0; i < count; i++) {
      final ChargingModel session =
      _chargingHistory[i];

      result.writeln(
        '${i + 1}. ${session.stationName}',
      );

      result.writeln(
        '   ${session.energyUsed.toStringAsFixed(2)} kWh'
            ' • ₹${session.cost.toStringAsFixed(2)}',
      );

      result.writeln(
        '   ${session.startBattery}% → '
            '${session.endBattery}%'
            ' • ${session.chargingTime} min',
      );

      result.writeln();
    }

    return result.toString().trim();
  }

  bool _containsAny(
      String text,
      List<String> words,
      ) {
    for (final String word in words) {
      if (text.contains(word)) {
        return true;
      }
    }

    return false;
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    }

    final int hours = minutes ~/ 60;
    final int remaining = minutes % 60;

    if (remaining == 0) {
      return '$hours hour${hours == 1 ? '' : 's'}';
    }

    return '$hours hour${hours == 1 ? '' : 's'} '
        '$remaining minutes';
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _addBotMessage(
        _welcomeMessage(),
      );
    });

    _scrollToBottom();
  }

  Widget _buildMessage(
      Map<String, String> message,
      ) {
    final bool isUser =
        message['sender'] == 'user';

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 330,
        ),
        margin:
        const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        decoration:
        BoxDecoration(
          color: isUser
              ? Colors.green
              : const Color(0xFF1E1E1E),
          borderRadius:
          BorderRadius.circular(18),
          border: isUser
              ? null
              : Border.all(
            color:
            Colors.white10,
          ),
        ),
        child: Text(
          message['message'] ?? '',
          style: TextStyle(
            color: isUser
                ? Colors.white
                : Colors.white,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestion(
      String text,
      ) {
    return GestureDetector(
      onTap: () => _sendSuggestion(text),
      child: Container(
        margin:
        const EdgeInsets.only(
          right: 8,
        ),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        decoration:
        BoxDecoration(
          color:
          const Color(0xFF1E1E1E),
          borderRadius:
          BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green
                .withOpacity(0.35),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 12,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
              Colors.green,
              child: Icon(
                Icons.bolt,
                color: Colors.white,
                size: 21,
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'EV Assistant',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                Text(
                  'Smart Charging Helper',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New conversation',
            onPressed: _clearChat,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(
          color: Colors.green,
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller:
              _scrollController,
              padding:
              const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                10,
              ),
              itemCount:
              _messages.length,
              itemBuilder:
                  (context, index) {
                return _buildMessage(
                  _messages[index],
                );
              },
            ),
          ),

          if (_sending)
            Container(
              alignment:
              Alignment.centerLeft,
              padding:
              const EdgeInsets.only(
                left: 20,
                bottom: 8,
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            height: 48,
            child:
            ListView(
              scrollDirection:
              Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              children: [
                _buildSuggestion(
                  'Battery status',
                ),
                _buildSuggestion(
                  'Charging cost',
                ),
                _buildSuggestion(
                  'Charging time',
                ),
                _buildSuggestion(
                  'My range',
                ),
                _buildSuggestion(
                  'Charging history',
                ),
                _buildSuggestion(
                  'Energy used',
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      _messageController,
                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                      ),
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                      TextInputAction.send,
                      onSubmitted:
                          (_) =>
                          _sendMessage(),
                      decoration:
                      InputDecoration(
                        hintText:
                        'Ask about your EV...',
                        hintStyle:
                        const TextStyle(
                          color:
                          Colors.grey,
                        ),
                        filled: true,
                        fillColor:
                        const Color(
                          0xFF1A1A1A,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            25,
                          ),
                          borderSide:
                          BorderSide
                              .none,
                        ),
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Container(
                    decoration:
                    const BoxDecoration(
                      color: Colors.green,
                      shape:
                      BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed:
                      _sending
                          ? null
                          : _sendMessage,
                      icon:
                      const Icon(
                        Icons.send,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}