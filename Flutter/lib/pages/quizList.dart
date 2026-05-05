import 'package:flutter/material.dart';
import 'package:health_research/pages/overStimulated.dart';
import 'package:health_research/pages/warebleHome.dart';

import 'academicHome.dart';
import 'daily_journal.dart';

class QuizList extends StatefulWidget {
  const QuizList({super.key});

  @override
  State<QuizList> createState() => _QuizListState();
}

class _QuizListState extends State<QuizList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Acadamic',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Try the quest to check Status',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              _buildQuestCard(
                icon: 'assets/images/academic-quiz.png',
                title: 'Academic Stress Quest',
                description:
                    'Understand how your studies, deadlines, and academic pressure are affecting your stress level',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AcademicHome()),
                ),
              ),
              const SizedBox(height: 16),
              _buildQuestCard(
                icon: 'assets/images/physical-quiz.png',
                title: 'Behavioural Quest',
                description:
                    'Explore your daily habits, routines, and lifestyle choices to see how they influence your mental wellbeing and stress.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WarebleHome()),
                ),
              ),
              const SizedBox(height: 16),
              _buildQuestCard(
                icon: 'assets/images/academic-quiz.png',
                title: 'Daily Journal',
                description:
                    'Express your thoughts • Reflect • Release',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DailyJournal()),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestCard({
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  icon,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
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

  void _onQuestTap(String questName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$questName selected'),
        backgroundColor: Colors.black,
      ),
    );
  }
}
