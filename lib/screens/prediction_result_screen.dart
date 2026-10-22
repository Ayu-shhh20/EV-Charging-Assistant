import 'package:flutter/material.dart';

import '../models/ai_prediction_model.dart';
import 'map_screen.dart';

class PredictionResultScreen extends StatelessWidget {
  final AIPredictionModel prediction;
  final int battery;

  const PredictionResultScreen({
    super.key,
    required this.prediction,
    required this.battery,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101010),

      appBar: AppBar(
        title: const Text(
          "AI Prediction Result",
        ),
        backgroundColor: Colors.black,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              "🤖 AI Charging Analysis",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Your charging plan has been generated "
                  "using the information you provided.",
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            resultCard(
              "Battery Level",
              "$battery%",
              Icons.battery_charging_full,
            ),

            resultCard(
              "Charging Time",
              "${prediction.estimatedTime} minutes",
              Icons.timer,
            ),

            resultCard(
              "Estimated Cost",
              "₹${prediction.estimatedCost}",
              Icons.currency_rupee,
            ),

            resultCard(
              "Recommended Station",
              prediction.recommendedStation,
              Icons.ev_station,
            ),

            resultCard(
              "AI Confidence",
              "${prediction.confidenceScore}%",
              Icons.auto_awesome,
            ),

            const SizedBox(height: 15),

            // FIND CHARGING STATION
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const MapScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.location_on,
                ),

                label: const Text(
                  "Find Charging Station",
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.greenAccent,

                  foregroundColor:
                  Colors.black,

                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 15,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // DONE / HOME BUTTON
            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {

                  Navigator.popUntil(
                    context,
                        (route) => route.isFirst,
                  );

                },

                icon: const Icon(
                  Icons.home_outlined,
                ),

                label: const Text(
                  "Back to Home",
                ),

                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  Colors.greenAccent,

                  side: const BorderSide(
                    color: Colors.greenAccent,
                  ),

                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 15,
                  ),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // AI NOTE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: const Color(0xff18251E),
                borderRadius:
                BorderRadius.circular(16),
              ),

              child: const Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Icon(
                    Icons.info_outline,
                    color: Colors.greenAccent,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "This prediction is currently "
                          "generated using prototype data. "
                          "Later, the AI model will use "
                          "real-time station and vehicle "
                          "data from PostgreSQL.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget resultCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      width: double.infinity,

      margin:
      const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xff1c1c1c),

        borderRadius:
        BorderRadius.circular(15),

        border: Border.all(
          color: Colors.white10,
        ),
      ),

      child: Row(
        children: [

          Icon(
            icon,
            color: Colors.greenAccent,
            size: 28,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 20,
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
}