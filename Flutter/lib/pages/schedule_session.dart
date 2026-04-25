import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_research/services/ScheduleSessionApiService.dart';
import 'package:health_research/pages/payment.dart';

class ScheduleSessionPage extends StatefulWidget {
  const ScheduleSessionPage({super.key});

  @override
  State<ScheduleSessionPage> createState() => _ScheduleSessionPageState();
}

class _ScheduleSessionPageState extends State<ScheduleSessionPage> {
  final ScheduleSessionApiService _apiService = ScheduleSessionApiService();

  String patientId = "";
  String patientName = "";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedDoctorId;
  String? selectedDoctorName;
  List<dynamic> availableDoctors = [];
  bool isLoadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _loadPatientInfo();
  }

  Future<void> _loadPatientInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      patientId = prefs.getString('patientId') ?? '';
      patientName = prefs.getString('firstName') ?? 'User';
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        selectedDoctorId = null;
        selectedDoctorName = null;
        availableDoctors = [];
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        selectedDoctorId = null;
        selectedDoctorName = null;
        availableDoctors = [];
      });
    }
  }

  Future<void> _loadAvailableDoctors() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoadingDoctors = true);
    try {
      final startDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      final endDateTime = startDateTime.add(const Duration(hours: 1));

      final response = await _apiService.getAvailableDoctors(
        startDateTime: startDateTime.toIso8601String(),
        endDateTime: endDateTime.toIso8601String(),
      );

      setState(() {
        availableDoctors = response['available_doctors'] ?? [];
        isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() => isLoadingDoctors = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading doctors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _proceedToPayment() {
    if (selectedDate == null || selectedTime == null || selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date, time, and doctor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final sessionDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          doctorId: selectedDoctorId!,
          doctorName: selectedDoctorName!,
          patientId: patientId,
          patientName: patientName,
          sessionDate: sessionDateTime,
          sessionTime: selectedTime!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule a Session',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(
              label: 'Date',
              value: selectedDate == null
                  ? 'Add Date'
                  : DateFormat('dd MMM yyyy').format(selectedDate!),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            _buildField(
              label: 'Time',
              value: selectedTime == null
                  ? 'Add Time'
                  : selectedTime!.format(context),
              onTap: () => _selectTime(context),
            ),
            const SizedBox(height: 20),
            _buildField(
              label: 'Doctor',
              value: selectedDoctorName ?? 'Select Doctor',
              onTap: () {
                if (availableDoctors.isEmpty && selectedDate != null && selectedTime != null) {
                  _loadAvailableDoctors();
                } else if (availableDoctors.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select date and time first'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  _showDoctorList();
                }
              },
              isLoading: isLoadingDoctors,
            ),
            const SizedBox(height: 30),
            _buildPricingSection(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pay and Schedule',
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
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value == 'Add Date' || value == 'Add Time' || value == 'Select Doctor'
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
                isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtotal (2)',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(''),
            Text(
              'LKR 2000.00',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Taxes',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              'LKR 180',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.grey),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'LKR 2180.00',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDoctorList() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Doctor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: availableDoctors.length,
              itemBuilder: (context, index) {
                final doctor = availableDoctors[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDoctorId = doctor['doctor_id'];
                      selectedDoctorName = doctor['doctor_name'];
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      doctor['doctor_name'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
