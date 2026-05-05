import 'package:flutter/material.dart';
import 'package:health_research/models/User.dart';
import 'package:health_research/pages/baseUi.dart';
// import 'package:thera_up/pages/base_ui.dart';
import 'package:health_research/pages/register.dart';
import 'package:health_research/pages/dashboard.dart';
import 'package:health_research/services/UserApiService.dart';
import 'package:shared_preferences/shared_preferences.dart';

//shortcut for creating a stateless widget "stl"
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserApiService _apiService = UserApiService();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter email and password.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      User? user = await _apiService.loginUser(email, password);
      if (user != null) {
        await _saveUserSession(user);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BaseUi()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }

    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red),
    );
  }

  Future<void> _saveUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patientId', user.patientId);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('email', user.email);
    await prefs.setBool('hasAssignedDoctors', user.hasAssignedDoctors);
    if (user.fullName != null) {
      await prefs.setString('fullName', user.fullName!);
    }
    if (user.role != null) {
      await prefs.setString('role', user.role!);
    }
    if (user.dob != null) {
      await prefs.setString('dob', user.dob!);
    }
    await prefs.setInt('age', user.age);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // FIXED BOTTOM OVERFLOW
          child: Column(
            children: [
              _topSection(),
              _fieldSection(),
              _bottomSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Column _topSection() {
    return Column(
      children: const [
        SizedBox(height: 100),
        Text('Login',
            style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Color(0xff000000))),
        SizedBox(height: 70),
        Text('Welcome back!',
            style: TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Column _fieldSection() {
    return Column(
      children: [
        const Text('Please enter your email and password',
            style: TextStyle(fontSize: 16, color: Colors.black)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _inputField("email@domain.com", _emailController),
              const SizedBox(height: 30),
              _inputField("*****************", _passwordController,
                  isPassword: true),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputField(String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xffffffff).withOpacity(0.2),
        contentPadding: const EdgeInsets.all(15),
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffffffff)),
        ),
      ),
    );
  }

  Column _bottomSection(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff000000),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Color(0xffffffff))
                : const Text("Sign in",
                    style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20), //
          child: Row(
            children: const [
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.grey,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Or",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const Text("If you haven't already sign up")],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton(
            onPressed: _isLoading ? null : () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Register()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffe2dbe3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Color(0xffbdbaba))
                : const Text("Sign Up",
                    style: TextStyle(color: Color(0xff000000), fontSize: 20)),
          ),
        ),
      ],
    );
  }
}
