import 'package:flutter/material.dart';
import 'overStimulated.dart';
import 'stress_quiz.dart';
import 'anxiety_quiz.dart';
import 'depression_quiz.dart';
import 'daily_journal.dart';

class DailyQuizes extends StatelessWidget {
  const DailyQuizes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Very light cool gray-blue
      appBar: AppBar(
        title: const Text(
          "Check your daily status",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const SizedBox(height: 8),
            _buildCard(
              context,
              title: " Daily Stress Quest",
              subtitle: "Quick check on today's work-life stress level",
              image: "assets/images/stressed-quiz.png",
              page: const StressQuiz(),
              color: const Color(0xFFFFAB91), // soft coral
            ),
            _buildCard(
              context,
              title: " Daily Anxiety Quest ",
              subtitle: "Track how calm or restless you're feeling today",
              image: "assets/images/anxiety_quiz.png",
              page: const AnxietyQuiz(),
              color: const Color(0xFF9575CD), // soft purple
            ),
            _buildCard(
              context,
              title: " Daily Depression Quest",
              subtitle: "Assess your emotional wellbeing right now",
              image: "assets/images/depression-quiz.png",
              page: const DepressionQuiz(),
              color: const Color(0xFF81C784), // soft green
            ),
            _buildCard(
              context,
              title: "Over-stimulated Quest",
              subtitle: "Check for signs of emotional and physical exhaustion to find out if you may be experiencing burnout.",
              image: "assets/images/burnout-quiz.png",
              page: const Overstimulated(),
              highlight: true,
              color: const Color(0xFFFFCA28), // warm amber
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String image,
    required Widget page,
    required Color color,
    bool highlight = false,
  }) {
    final borderRadius = BorderRadius.circular(24);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          borderRadius: borderRadius,
          splashColor: color.withOpacity(0.12),
          highlightColor: color.withOpacity(0.08),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                if (highlight)
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
              ],
              border: highlight
                  ? Border.all(color: color.withOpacity(0.6), width: 1.5)
                  : null,
            ),
            child: Container(
              height: highlight ? 140 : 120, // ← taller cards (main request)
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.9),
                          color.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        image,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.38,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: highlight ? color : Colors.grey.shade500,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
