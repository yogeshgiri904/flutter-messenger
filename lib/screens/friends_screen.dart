import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_screen.dart'; // Your chat screen
import 'dart:math';

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
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            );
          }

          final users = snapshot.data as List<dynamic>? ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No friends found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(4.0), // Reduced padding
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userName = user['name'] ?? 'Anonymous';
              final gender = user['gender']?.toLowerCase();

              IconData genderIcon;
              Color avatarColor;

              if (gender == 'female') {
                genderIcon = Icons.girl_outlined;
                avatarColor = Colors.pinkAccent;
              } else if (gender == 'male') {
                genderIcon = Icons.boy_outlined;
                avatarColor = Colors.blueAccent;
              } else {
                genderIcon = Icons.person;
                avatarColor = Colors.grey;
              }

              return Card(
                elevation: 2, // Reduced elevation
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.pink.shade50,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ), // Reduced padding
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: avatarColor,
                    child: Icon(
                      genderIcon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14, // Reduced font size
                    ),
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          size: 20,
                        ),
                        tooltip: 'View Profile',
                        onPressed: () {
                          // Handle profile navigation
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                        ),
                        tooltip: 'Send Message',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MessageScreen(),
                            ),
                          );
                        },
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
