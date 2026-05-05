import 'package:flutter/material.dart';
import 'package:health_research/pages/schedule_session.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_research/services/SessionApiService.dart';
import 'package:health_research/pages/doctor_video_call.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  final SessionApiService _sessionApiService = SessionApiService();
  String patientId = "";
  List<dynamic> upcomingSessions = [];
  List<dynamic> pastSessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientIdAndSessions();
  }

  Future<void> _loadPatientIdAndSessions() async {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getString('patientId') ?? '';

    if (patientId.isNotEmpty) {
      await _fetchSessions();
    }
  }

  Future<void> _fetchSessions() async {
    setState(() => isLoading = true);
    try {
      final response = await _sessionApiService.getSessions(
        patientId: patientId,
        activeOnly: true,
      );

      if (mounted) {
        setState(() {
          final allSessions = response['sessions'] ?? [];
          final now = DateTime.now();

          upcomingSessions = allSessions.where((session) {
            final sessionDate = DateTime.parse(session['session_date']);
            return sessionDate.isAfter(now);
          }).toList();

          pastSessions = allSessions.where((session) {
            final sessionDate = DateTime.parse(session['session_date']);
            return sessionDate.isBefore(now);
          }).toList();

          upcomingSessions.sort((a, b) {
            final dateA = DateTime.parse(a['session_date']);
            final dateB = DateTime.parse(b['session_date']);
            return dateA.compareTo(dateB);
          });

          pastSessions.sort((a, b) {
            final dateA = DateTime.parse(a['session_date']);
            final dateB = DateTime.parse(b['session_date']);
            return dateB.compareTo(dateA);
          });

          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching sessions: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _formatSessionDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('d\'th\' MMMM yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String _formatSessionTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('h:mma').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sessions',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildScheduleSessionCard(),
                    const SizedBox(height: 30),
                    _buildSectionHeader('Up Coming', 'See all'),
                    const SizedBox(height: 16),
                    upcomingSessions.isEmpty
                        ? _buildEmptyState('No upcoming sessions')
                        : _buildSessionsList(upcomingSessions,
                            isUpcoming: true),
                    const SizedBox(height: 30),
                    _buildSectionHeader('Past Sessions', 'See all'),
                    const SizedBox(height: 16),
                    pastSessions.isEmpty
                        ? _buildEmptyState('No past sessions')
                        : _buildSessionsList(pastSessions, isUpcoming: false),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildScheduleSessionCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ScheduleSessionPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/schedule.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Schedule a Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Schedule a session with a professional to lift your mood',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.orange,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Row(
            children: const [
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsList(List<dynamic> sessions,
      {required bool isUpcoming}) {
    return Column(
      children: sessions.map((session) {
        return _buildSessionCard(session, isUpcoming: isUpcoming);
      }).toList(),
    );
  }

  Widget _buildSessionCard(dynamic session, {required bool isUpcoming}) {
    final doctorName = session['doctor_name'] ?? 'Unknown Doctor';
    final durationMinutes = session['duration_minutes'] ?? 60;
    final sessionDate = session['session_date'];
    final formattedDate = _formatSessionDate(sessionDate);
    final formattedTime = _formatSessionTime(sessionDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Time : $formattedTime',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            doctorName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Counseling psychologists',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 4),
            const Text(
              'Kindly join 5 minutes in advance',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorVideoCall(
                        sessionId: 'S202523',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Join Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
