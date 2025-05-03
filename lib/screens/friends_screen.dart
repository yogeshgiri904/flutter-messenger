import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_screen.dart'; // Import message screen to send messages

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _usersFuture = Supabase.instance.client.from('profiles').select();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            );
          }
          final users = snapshot.data as List<dynamic>? ?? [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                color: const Color.fromARGB(255, 245, 184, 207),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user['email'] ?? 'No Email',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.account_circle_outlined),
                            tooltip: 'View Profile',
                            onPressed: () {
                              // Navigate to user profile
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline),
                            tooltip: 'Send Message',
                            onPressed: () {
                              // Navigate to message screen with user ID
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => MessageScreen(
                                        friendName: user['email'] ?? 'No Name',
                                      ), // Pass user email as friend name
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
