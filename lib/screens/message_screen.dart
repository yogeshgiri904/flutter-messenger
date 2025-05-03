import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rxdart/rxdart.dart';

class MessageScreen extends StatefulWidget {
  final String friendName;
  const MessageScreen({super.key, required this.friendName});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _messageController = TextEditingController();

  String get _currentUserId => Supabase.instance.client.auth.currentUser!.id;

  Stream<List<Map<String, dynamic>>> _getMessagesStream(String recipientId) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    final fromMe = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', recipientId);

    final toMe = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', currentUserId);

    return Rx.combineLatest2(fromMe, toMe, (
      List<Map<String, dynamic>> a,
      List<Map<String, dynamic>> b,
    ) {
      final allMessages = [...a, ...b];
      allMessages.sort(
        (x, y) => DateTime.parse(
          x['created_at'],
        ).compareTo(DateTime.parse(y['created_at'])),
      );
      return allMessages;
    });
  }

  Future<void> _sendMessage(String recipientId) async {
    final content = _messageController.text.trim();

    if (content.isEmpty) return;

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': _currentUserId,
        'recipient_id': recipientId,
        'content': content,
      });
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF900C3F);
    final recipientId = widget.friendName;

    return Scaffold(
      appBar:
          widget.friendName.isNotEmpty
              ? AppBar(
                title: Text(
                  'Chat with ${widget.friendName}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
                backgroundColor: primaryColor,
              )
              : null,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getMessagesStream(recipientId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender_id'] == _currentUserId;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? primaryColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message['content'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: InputDecoration(
                      labelText: 'Message',
                      labelStyle: GoogleFonts.poppins(
                        color: primaryColor,
                        fontSize: 12,
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: primaryColor),
                  onPressed: () => _sendMessage(recipientId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
