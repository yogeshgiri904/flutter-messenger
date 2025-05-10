import 'package:flutter/material.dart';
import 'package:namaste_flutter/screens/message_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late String _currentUserId; // The current user ID
  Map<String, int> _unreadMessageCount =
      {}; // To store the unread message count
  Map<String, Map<String, dynamic>> _senderProfiles =
      {}; // Store sender profiles (name, gender)

  @override
  void initState() {
    super.initState();
    _initializeUser(); // Fetch current user info on init
  }

  // Initialize current user info
  void _initializeUser() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _currentUserId = user.id;
      _loadUnreadMessages(); // Load unread messages after user is initialized
    }
  }

  // Method to load unread messages and count them per sender
  void _loadUnreadMessages() async {
    final unreadMessagesResponse = await supabase
        .from('messages')
        .select()
        .eq('recipient_id', _currentUserId) // Current user is the recipient
        .eq('is_read', false); // Only unread messages

    // If the response is not empty, group the messages by sender_id
    if (unreadMessagesResponse != null && unreadMessagesResponse.isNotEmpty) {
      Map<String, List<Map<String, dynamic>>> groupedMessages = {};

      for (var msg in unreadMessagesResponse) {
        final senderId = msg['sender_id']; // Get sender_id
        if (groupedMessages.containsKey(senderId)) {
          groupedMessages[senderId]?.add(msg);
        } else {
          groupedMessages[senderId] = [msg];
        }
      }

      print('count, $groupedMessages');
      // Count the unread messages per sender and update the state
      setState(() {
        _unreadMessageCount = groupedMessages.map((senderId, messages) {
          return MapEntry(
            senderId,
            messages.length,
          ); // Map sender to unread message count
        });
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMessages() async {
    final response = await supabase
        .from('messages')
        .select('''
        sender_id, recipient_id, content, created_at
        ''')
        .eq('recipient_id', _currentUserId)
        .order('created_at', ascending: false); // newest first

    if (response == null || response.isEmpty) return [];

    // Group by sender_id: pick latest message per sender
    final Map<String, Map<String, dynamic>> latestBySender = {};

    for (var message in response) {
      final senderId = message['sender_id'];
      if (!latestBySender.containsKey(senderId)) {
        latestBySender[senderId] = message;
      }
    }

    final senderIds = latestBySender.keys.toList();

    // Fetch sender profiles
    final profileResponse = await supabase
        .from('profiles')
        .select('id, name, gender')
        .inFilter('id', senderIds);

    for (var profile in profileResponse) {
      _senderProfiles[profile['id']] = {
        'id': profile['id'],
        'email': profile['email'],
        'name': profile['name'],
        'gender': profile['gender'],
      };
    }

    // Return only the latest message per sender
    return latestBySender.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _fetchMessages(), // Call the async function here
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No messages available.'));
          }

          final messages = snapshot.data!;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final senderId = message['sender_id'];
              final lastMessage = message['content'] ?? 'No message content';

              // Fetch sender's profile info (name and gender)
              final senderProfile =
                  _senderProfiles[senderId] ??
                  {'name': 'Unknown', 'gender': 'unknown'};
              final senderName = senderProfile['name'];
              final gender = senderProfile['gender']?.toLowerCase();

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

              // If the sender has unread messages, display a count
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 10.0,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(0),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarColor,
                    child: Icon(genderIcon, color: Colors.white, size: 30),
                  ),
                  title: Text(
                    senderName,
                    style: TextStyle(
                      fontSize: 14, // Reduce font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 12, // Reduce font size
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing:
                      _unreadMessageCount[senderId] != null &&
                              _unreadMessageCount[senderId]! > 0
                          ? CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.blue,
                            child: Text(
                              _unreadMessageCount[senderId]!.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10, // Smaller unread count text size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : null,
                  onTap: () {
                    // Navigate to the MessageScreen for that sender
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MessageScreen(
                              recipientProfile: senderProfile,
                            ),
                      ),
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
}
