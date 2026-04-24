import 'package:flutter/material.dart';
import 'package:health_research/pages/academicHome.dart';
import 'package:health_research/pages/dashboard.dart';
import 'package:health_research/pages/quizList.dart';
import 'package:health_research/pages/schedule.dart';
import 'package:health_research/pages/timeSerie.dart';
import 'package:health_research/pages/usage_stats_screen.dart';
import 'package:health_research/pages/warebleHome.dart';
import 'package:health_research/pages/dailyQuizes.dart';

class BaseUi extends StatefulWidget {
  const BaseUi({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<BaseUi> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const Dashboard(),
    const Schedule(),
    const QuizList(),
    // AcademicHome(),
    // WarebleHome(),
    const DailyQuizes(),
    const UsageStatsScreen(),
    // TimeSeriesDashboard(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Academic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Quizzes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Status',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
