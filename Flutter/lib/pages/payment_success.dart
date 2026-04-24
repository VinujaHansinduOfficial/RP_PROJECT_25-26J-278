import 'package:flutter/material.dart';
import 'package:health_research/pages/baseUi.dart';
import 'package:intl/intl.dart';
import 'package:health_research/services/ScheduleSessionApiService.dart';
import 'package:health_research/pages/schedule.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String patientName;
  final DateTime sessionDate;
  final TimeOfDay sessionTime;

  const PaymentSuccessPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.patientName,
    required this.sessionDate,
    required this.sessionTime,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final ScheduleSessionApiService _apiService = ScheduleSessionApiService();
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    try {
      final sessionDateTime = DateTime(
        widget.sessionDate.year,
        widget.sessionDate.month,
        widget.sessionDate.day,
        widget.sessionTime.hour,
        widget.sessionTime.minute,
      );

      final sessionTimeString =
          '${widget.sessionTime.hour.toString().padLeft(2, '0')}.${widget.sessionTime.minute.toString().padLeft(2, '0')} ${widget.sessionTime.period == DayPeriod.am ? 'A.M' : 'P.M'}';

      await _apiService.createSession(
        doctorId: widget.doctorId,
        doctorName: widget.doctorName,
        patientId: widget.patientId,
        patientName: widget.patientName,
        sessionDate: sessionDateTime.toIso8601String(),
        sessionTime: sessionTimeString,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      print('Error creating session: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Confirmation',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isProcessing
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Successful!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your Payment was successful and\nsession scheduled successfully',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 70),
                      Image.asset(
                        'assets/images/success_coins.jpg',
                        width: 400,
                        height: 400,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BaseUi(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
