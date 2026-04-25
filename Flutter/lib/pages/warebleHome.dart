import 'package:flutter/material.dart';
import 'package:health_research/pages/physStress.dart';
import 'package:health_research/pages/stressQuestionnaireScreen.dart';

class WarebleHome extends StatelessWidget {
  const WarebleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Physical Activities',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🖼️ Illustration Image
              Image.asset(
                'assets/images/physical_activities.png',
                height: 270,
              ),

              const SizedBox(height: 20),

              // 📄 Description Text
              Text(
                "Physical activity has a strong positive impact on stress and mood because it helps regulate key factors that influence overall well-being. Regular exercise improves sleep quality, stabilizes heart rate, and reduces the physical tension caused by stress. It can also help offset the negative effects of long screen time, high caffeine intake, and an unhealthy BMI by boosting energy levels and improving hormonal balance. Even simple activities like walking, stretching, or playing a sport can release endorphins, lower anxiety, and make you feel more relaxed and mentally refreshed.",
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 25),

              // 🔥 Section Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Try the quest to check you’s",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PhysStress(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xfff2f2f2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/file_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Stress Quest ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Explore your daily habits, routines, and lifestyle choices to see how they influence your mental wellbeing.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
