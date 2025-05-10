import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MessageScreen extends StatefulWidget {
  final Map<String, dynamic> recipientProfile;
  const MessageScreen({Key? key, required this.recipientProfile})
    : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  bool _isSubmitting = false;


  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late RealtimeChannel _messageChannel;

  List<Map<String, dynamic>> _messages = [];
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  void _loadMessages() async {
    print(widget.recipientProfile);
    final response = await supabase
        .from('messages')
        .select()
        .or('sender_id.eq.$_currentUserId,recipient_id.eq.$_currentUserId')
        .order('created_at', ascending: true);

    // Explicitly cast the response to List<Map<String, dynamic>>
    final filtered =
        (response as List)
            .where(
              (msg) =>
                  (msg['sender_id'] == _currentUserId &&
                      msg['recipient_id'] == widget.recipientProfile['id']) ||
                  (msg['sender_id'] == widget.recipientProfile['id'] &&
                      msg['recipient_id'] == _currentUserId),
            )
            .toList()
            .cast<
              Map<String, dynamic>
            >(); // Ensure that it's a List<Map<String, dynamic>>

    // Update read status for any relevant messages
    _updateReadStatus(filtered);

    setState(() {
      _messages = filtered;
    });

    _scrollToBottom();
  }

  void _updateReadStatus(List<Map<String, dynamic>> messages) async {
    final messageIdsToUpdate =
        messages
            .where(
              (msg) =>
                  msg['recipient_id'] == _currentUserId &&
                  msg['is_read'] == false,
            )
            .map((msg) => msg['id'])
            .toList();

    if (messageIdsToUpdate.isNotEmpty) {
      try {
        final result =
            await supabase
                .from('messages')
                .update({'is_read': true})
                .inFilter('id', messageIdsToUpdate)
                .select();

        // print('update -> $messageIdsToUpdate, result -> $result');
      } catch (e) {
        print('Error updating read status: $e');
      }
    }
  }

  void _subscribeToMessages() {
    _messageChannel = supabase.channel('messages-channel');

    _messageChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) async {
            print('Received realtime message: ${payload.newRecord}');

            final newMessage = payload.newRecord as Map<String, dynamic>;

            final isRelevant =
                (newMessage['sender_id'] == _currentUserId &&
                    newMessage['recipient_id'] ==
                        widget.recipientProfile['id']) ||
                (newMessage['sender_id'] == widget.recipientProfile['id'] &&
                    newMessage['recipient_id'] == _currentUserId);

            if (isRelevant) {
              // Mark this message as read if it's for the current user
              if (newMessage['recipient_id'] == _currentUserId) {
                try {
                  await supabase
                      .from('messages')
                      .update({'is_read': true})
                      .eq('id', newMessage['id']);
                } catch (e) {
                  print('Error updating read status on real-time message: $e');
                }
              }

              setState(() {
                _messages.add(newMessage);
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    setState(
      () => _isSubmitting = true,
    ); // Indicate that the submission is in progress
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      // Insert message into Supabase
      await supabase.from('messages').insert({
        'sender_id': _currentUserId,
        'recipient_id': widget.recipientProfile['id'],
        'content': text,
        'created_at': now,
        'is_read': false, // New messages are not read initially
      });

      _controller.clear();

      _scrollToBottom();
    } catch (e) {
      // Handle error, if any
      print('Error sending message: $e');
    } finally {
      // Always set _isSubmitting to false, regardless of success or failure
      setState(() => _isSubmitting = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMine = msg['sender_id'] == _currentUserId;
    final time = DateFormat('h:mm a').format(DateTime.parse(msg['created_at']));

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? Colors.blue[400] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 0),
            bottomRight: Radius.circular(isMine ? 0 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg['content'],
              style: TextStyle(
                fontSize: 13,
                color: isMine ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                fontSize: 9,
                color: isMine ? Colors.white60 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                style: TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFF900C3F)),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 36,
              width: 36,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFF900C3F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.send, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    supabase.removeChannel(_messageChannel);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gender = widget.recipientProfile['gender']?.toLowerCase();
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor,
              child: Icon(genderIcon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 8),
            Text(
              widget.recipientProfile['name'] ?? 'Chat',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [Expanded(child: _buildMessageList()), _buildMessageInput()],
      ),
    );
  }
}
