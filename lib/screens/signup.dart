import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaste_flutter/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'dart:math';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final List<Map<String, String>> funnyProfiles = [
    {'name': 'Crime Master Gogo', 'gender': 'male'},
    {'name': 'Baburao Apte', 'gender': 'male'},
    {'name': 'Sachiv Ji', 'gender': 'male'},
    {'name': 'Prahlad Cha', 'gender': 'male'},
    {'name': 'Pradhan Ji', 'gender': 'male'},
    {'name': 'Bhushan Bhai', 'gender': 'male'},
    {'name': 'Majnu Bhai', 'gender': 'male'},
    {'name': 'Uday Bhai', 'gender': 'male'},
    {'name': 'Munna Bhai', 'gender': 'male'},
    {'name': 'Circuit', 'gender': 'male'},
    {'name': 'Raju', 'gender': 'male'},
    {'name': 'Shyam', 'gender': 'male'},
    {'name': 'Totla Seth', 'gender': 'male'},
    {'name': 'Pappu Pager', 'gender': 'male'},
    {'name': 'Chatur Ramalingam', 'gender': 'male'},
    {'name': 'Virus', 'gender': 'male'},
    {'name': 'Prem Chopra', 'gender': 'male'},
    {'name': 'Inspector Daya', 'gender': 'male'},
    {'name': 'ACP Pradyuman', 'gender': 'male'},
    {'name': 'Inspector Abhijeet', 'gender': 'male'},
    {'name': 'Chulbul Pandey', 'gender': 'male'},
    {'name': 'Bajirao Singham', 'gender': 'male'},
    {'name': 'Rahul Mithaiwala', 'gender': 'male'},
    {'name': 'Tangaballi', 'gender': 'male'},
    {'name': 'Murli Prasad Sharma', 'gender': 'male'},
    {'name': 'DM Madam', 'gender': 'female'},
    {'name': 'Meenamma Lochini', 'gender': 'female'},
    {'name': 'Rinki', 'gender': 'female'},
  ];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedGender;

  Future<void> _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Password Mismatch', 'Passwords do not match.');
      return;
    }

    if (_selectedGender == null) {
      _showMessage('Missing Information', 'Please select a gender.');
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final user = response.user;
      if (user != null) {
        // 1. Get names for the selected gender
        final gender = _selectedGender;
        final genderSpecificNames =
            funnyProfiles
                .where((profile) => profile['gender'] == gender)
                .map((profile) => profile['name']!)
                .toList();

        // 2. Get names already used
        final existingNamesResponse = await Supabase.instance.client
            .from('profiles')
            .select('name');

        final existingNames =
            (existingNamesResponse as List)
                .map((profile) => profile['name'] as String)
                .toSet();

        // 3. Get available names that haven't been taken
        final availableNames =
            genderSpecificNames
                .where((name) => !existingNames.contains(name))
                .toList();

        // 4. Choose a random name from the available ones
        String randomName;
        if (availableNames.isNotEmpty) {
          final randomBase = (availableNames..shuffle()).first;
          final randomDigits = Random().nextInt(900) + 100;
          final camelCaseBase = toCamelCase(randomBase);
          randomName = '$camelCaseBase$randomDigits';
        } else {
          randomName = _emailController.text;
        }

        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'email': _emailController.text,
          'name': randomName,
          'gender': _selectedGender,
        });

        _showSuccessDialog(randomName);
      } else {
        _showMessage('Error', 'Signup failed. Please try again.');
      }
    } catch (e) {
      _showMessage('Error', 'An error occurred during signup: $e');
    }
  }

  String toCamelCase(String input) {
    final words = input.split(RegExp(r'\s+'));
    if (words.isEmpty) return '';

    final firstWord = words.first.toLowerCase();
    final capitalizedWords = words
        .skip(1)
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : '',
        );

    return firstWord + capitalizedWords.join();
  }

  void _showSuccessDialog(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            height: 380,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.green.shade100, Colors.green.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Account Created!',
                  style: GoogleFonts.poppins(
                    fontSize: 20, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF900C3F), // Applying the requested color
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You have been assigned the name:',
                  style: GoogleFonts.poppins(fontSize: 12), // Smaller text
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 18, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Use this name within the app.',
                  style: GoogleFonts.poppins(
                    fontSize: 12, // Smaller text
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: Text(
                      'Continue to App',
                      style: GoogleFonts.poppins(
                        fontSize: 14, // Slightly smaller font
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(
                        0xFF900C3F,
                      ), // Applying the requested color
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  LoginScreen(), // Pass user info here if needed
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: const Color(0xFF900C3F)),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF900C3F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Create a New Account',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF900C3F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please fill in the details below',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(
                    Icons.alternate_email,
                    color: Color(0xFF900C3F),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: GoogleFonts.poppins(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF900C3F),
                  ),
                ),
                items:
                    ['male', 'female'].map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(
                          gender[0].toUpperCase() + gender.substring(1),
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.poppins(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF900C3F),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: GoogleFonts.poppins(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF900C3F),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF900C3F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  'Sign Up',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Already have an account? Log in',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF900C3F),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 80.0),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Center(
                  child: Text(
                    '© 2025 Shri Ram Organisation',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
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
