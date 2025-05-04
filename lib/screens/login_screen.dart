// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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

  Future<void> _login() async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (response.user != null) {
        _showMessage('Success', 'Login successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showMessage('Error', 'Invalid email or password.');
      }
    } catch (e) {
      _showMessage('Error', 'An error occurred during login: $e');
    }
  }

  Future<void> _signup() async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final user = response.user;

      if (user != null) {
        final funnyNames = [
          'Crime Master Gogo',
          'Baburao Ganpatrao Apte',
          'Professor Parimal Tripathi',
          'Bhola Bhandari',
          'Bharat Bhushan Chobey',
          'Majnu Bhai',
          'Uday Bhai',
          'Munna Bhai',
          'Circuit',
          'Oye Lucky',
          'Raju',
          'Shyam',
          'Totla Seth',
          'Pappu Pager',
          'Chatur Ramalingam',
          'Virus',
          'Teja',
          'Robert',
          'Bhalla',
          'Prem Chopra',
          'Daya No Mercy',
          'ACP Pradyuman',
          'Abhijeet',
          'Doctor Freddy',
          'Inspector Chulbul Pandey',
          'Inspector Bajirao Singham',
          'Rahul Mithaiwala',
          'Meenamma Lochini Azhagusundaram',
          'Tangaballi',
          'Durgeshwara Azhagusundaram',
          'Murli Prasad Sharma',
          'Circuit',
        ];
        final randomName = (funnyNames..shuffle()).first;

        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'email': _emailController.text,
          'name': randomName,
        });

        _showSuccessDialog(randomName);
      } else {
        _showMessage('Error', 'Signup failed. Please try again.');
      }
    } catch (e) {
      _showMessage('Error', 'An error occurred during signup: $e');
    }
  }

  void _showSuccessDialog(String name) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            height: 340,
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
                const SizedBox(height: 20),
                Text(
                  'Welcome, $name!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account has been created successfully.',
                  style: GoogleFonts.poppins(fontSize: 14),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop(); // Close dialog

                      try {
                        final response = await Supabase.instance.client.auth
                            .signInWithPassword(
                              email: _emailController.text,
                              password: _passwordController.text,
                            );
                        if (response.user != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        } else {
                          _showMessage('Error', 'Login failed after signup.');
                        }
                      } catch (e) {
                        _showMessage('Error', 'Auto-login failed: $e');
                      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Namaste Messenger',
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
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF900C3F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please login to continue',
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
              TextField(
                controller: _passwordController,
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
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF900C3F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.login, color: Colors.white),
                label: Text(
                  'Login',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _signup,
                icon: const Icon(
                  Icons.person_add_alt_1,
                  color: Color(0xFF900C3F),
                ),
                label: Text(
                  'Don’t have an account? Sign up',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF900C3F),
                    fontSize: 14,
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
