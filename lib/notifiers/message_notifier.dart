import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageNotifier extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  int _unreadCount = 0;
  RealtimeChannel? _channel;

  int get unreadCount => _unreadCount;

  MessageNotifier() {
    _init();
  }

  void _init() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _loadUnreadMessages();
      _subscribeToMessageChanges(user.id);
    }

    // Watch for auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        _loadUnreadMessages();
        _subscribeToMessageChanges(user.id);
      }

      if (event == AuthChangeEvent.signedOut) {
        _unreadCount = 0;
        _unsubscribe();
        notifyListeners();
      }
    });
  }

  Future<void> _loadUnreadMessages() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('messages')
          .select()
          .eq('recipient_id', userId)
          .eq('is_read', false);

      _unreadCount = response.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread messages: $e');
    }
  }

  void _subscribeToMessageChanges(String userId) {
    _unsubscribe(); // Clean up previous

    _channel = supabase.channel('messages_realtime');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            column: 'recipient_id',
            value: userId,
            type: PostgresChangeFilterType.eq,
          ),
          callback: (payload) {
            final newMsg = payload.newRecord;
            if (newMsg != null && newMsg['is_read'] == false) {
              _unreadCount++;
              notifyListeners();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            column: 'recipient_id',
            value: userId,
            type: PostgresChangeFilterType.eq,
          ),
          callback: (payload) {
            final oldMsg = payload.oldRecord;
            final updatedMsg = payload.newRecord;

            if (oldMsg != null &&
                updatedMsg != null &&
                oldMsg['is_read'] == false &&
                updatedMsg['is_read'] == true) {
              _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
              notifyListeners();
            }
          },
        );

    _channel!.subscribe();
  }

  void _unsubscribe() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
      _channel = null;
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
