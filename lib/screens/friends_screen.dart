import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_screen.dart'; // Chat screen accepting `recipientProfile`

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
    if (currentUserId != null) {
       _loadUnreadMessages(currentUserId); 
    }
  }

  Future<List<Map<String, dynamic>>> _getOtherProfiles() async {
    final response = await supabase
        .from('profiles')
        .select()
        .neq('id', currentUserId);

    return List<Map<String, dynamic>>.from(response);
  }

  void _loadUnreadMessages(currentUserId) async {
    final unreadMessagesResponse = await supabase
        .from('messages')
        .select()
        .eq('recipient_id', currentUserId) // Current user is the recipient
        .eq('is_read', false); // Only unread messages

    print(unreadMessagesResponse);
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
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor,
                  child: Icon(
                    genderIcon,
                    color: Colors.white,
                    size: 26,
                  ),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageScreen(
                        recipientProfile: user,
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