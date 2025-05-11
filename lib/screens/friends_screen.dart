import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_screen.dart'; // Ensure this file exists and accepts `recipientProfile`

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, int> _unreadMessageCount = {};
  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser!.id;
    if (currentUserId.isNotEmpty) {
      _loadUnreadMessages();
      _subscribeToMessageChanges();
    }
  }

  @override
  void dispose() {
    supabase.removeAllChannels();
    super.dispose();
  }

  // Load unread messages count from the database
  void _loadUnreadMessages() async {
    final response = await supabase
        .from('messages')
        .select()
        .eq('recipient_id', currentUserId)
        .eq('is_read', false);

    if (response != null && response.isNotEmpty) {
      Map<String, int> counts = {};
      for (var msg in response) {
        final senderId = msg['sender_id'];
        counts[senderId] = (counts[senderId] ?? 0) + 1;
      }

      setState(() {
        _unreadMessageCount = counts;
      });
    }
  }

  void _resetUnreadMessages(user) async {
    setState(() {
      _unreadMessageCount[user['id']] = 0;
    });
  }

  void _subscribeToMessageChanges() {
    final channel = supabase.channel('realtime:messages');

    // New messages
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        column: 'recipient_id',
        value: currentUserId,
        type: PostgresChangeFilterType.eq,
      ),
      callback: (payload) {
        final newMsg = payload.newRecord;
        if (newMsg != null && newMsg['is_read'] == false) {
          final senderId = newMsg['sender_id'];
          setState(() {
            _unreadMessageCount[senderId] =
                (_unreadMessageCount[senderId] ?? 0) + 1;
          });
        }
      },
    );

    // Read messages
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        column: 'recipient_id',
        value: currentUserId,
        type: PostgresChangeFilterType.eq,
      ),
      callback: (payload) {
        final oldMsg = payload.oldRecord;
        final updatedMsg = payload.newRecord;
        if (oldMsg != null &&
            updatedMsg != null &&
            oldMsg['is_read'] == false &&
            updatedMsg['is_read'] == true) {
          final senderId = updatedMsg['sender_id'];
          setState(() {
            if (_unreadMessageCount.containsKey(senderId)) {
              _unreadMessageCount[senderId] =
                  (_unreadMessageCount[senderId]! - 1)
                      .clamp(0, double.infinity)
                      .toInt();
            }
          });
        }
      },
    );

    channel.subscribe();
  }

  // This method will be called when the user taps on a friend to open message screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getOtherProfiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No friends found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(4.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userId = user['id'];
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.pink.shade50,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: avatarColor,
                    child: Icon(genderIcon, color: Colors.white, size: 26),
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 28),
                      if (_unreadMessageCount[userId] != null &&
                          _unreadMessageCount[userId]! > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.blue,
                            child: Text(
                              _unreadMessageCount[userId]!.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                   
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MessageScreen(recipientProfile: user),
                      ),
                    );
                    _resetUnreadMessages(
                      user,
                    ); 
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Method to get the list of profiles excluding the current user
  Future<List<Map<String, dynamic>>> _getOtherProfiles() async {
    final response = await supabase
        .from('profiles')
        .select()
        .neq('id', currentUserId);

    return List<Map<String, dynamic>>.from(response);
  }
}
