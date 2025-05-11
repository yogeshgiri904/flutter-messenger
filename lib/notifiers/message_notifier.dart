import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageNotifier extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  MessageNotifier() {
    _loadUnreadMessages();
    _subscribeToMessageChanges();
  }

  Future<void> _loadUnreadMessages() async {
    final response = await supabase
        .from('messages')
        .select()
        .eq('recipient_id', supabase.auth.currentUser!.id)
        .eq('is_read', false);

    _unreadCount = response.length;
    notifyListeners();
  }

  void _subscribeToMessageChanges() {
    final channel = supabase.channel('realtime:messages');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        column: 'recipient_id',
        value: supabase.auth.currentUser!.id,
        type: PostgresChangeFilterType.eq,
      ),
      callback: (payload) {
        final newMsg = payload.newRecord;
        if (newMsg != null && newMsg['is_read'] == false) {
          _unreadCount++;
          notifyListeners();
        }
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        column: 'recipient_id',
        value: supabase.auth.currentUser!.id,
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

    channel.subscribe();
  }
}
