import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const ViewPostScreen({super.key, required this.post});

  @override
  State<ViewPostScreen> createState() => _ViewPostScreenState();
}

class _ViewPostScreenState extends State<ViewPostScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 10;
  List<dynamic> _comments = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isSubmitting = false;
  late Future<Map<String, dynamic>?> _postAuthorFuture;

  @override
  void initState() {
    super.initState();
    _postAuthorFuture = _fetchPostAuthor();
    _fetchComments();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _fetchComments();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchPostAuthor() async {
    final userId = widget.post['user_id'];
    if (userId == null) return null;

    final response =
        await Supabase.instance.client
            .from('profiles')
            .select('name, email')
            .eq('id', userId)
            .maybeSingle();

    return response;
  }

  Future<void> _fetchComments() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final response = await Supabase.instance.client
        .from('comments')
        .select('id, content, created_at, user_id')
        .eq('post_id', widget.post['id'])
        .order('created_at', ascending: false)
        .range(_comments.length, _comments.length + _pageSize - 1);

    final userIds = response.map((c) => c['user_id']).toSet().toList();
    final profiles = await Supabase.instance.client
        .from('profiles')
        .select('id, name, email')
        .inFilter('id', userIds);
    final userMap = {for (var p in profiles) p['id']: p};

    for (var comment in response) {
      comment['user'] = userMap[comment['user_id']];
    }

    setState(() {
      _comments.addAll(response);
      _hasMore = response.length == _pageSize;
      _isLoading = false;
    });
  }

  Future<void> _refreshComments() async {
    setState(() {
      _comments.clear();
      _hasMore = true;
    });
    await _fetchComments();
  }

  Future<void> _addComment(String content) async {
    if (content.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await Supabase.instance.client.from('comments').insert({
        'content': content.trim(),
        'post_id': widget.post['id'],
        'user_id': user.id,
      });

      _commentController.clear();
      // Refresh comments to reload from the top (ordered by created_at DESC)
      await _refreshComments();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Post',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF900C3F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshComments,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 20,
                        color: Color(0xFF900C3F),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post['title'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF900C3F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _postAuthorFuture,
                    builder: (context, snapshot) {
                      final author = snapshot.data;
                      return Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'By ${author?['name'] ?? 'Anonymous'}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo(
                              DateTime.tryParse(post['created_at']) ??
                                  DateTime.now(),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      post['content'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.comment_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Comments',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._comments.map((comment) {
                    final user = comment['user'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[300],
                            child: const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?['name'] ?? 'Anonymous',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  comment['content'] ?? '',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                                Text(
                                  timeAgo(
                                    DateTime.tryParse(comment['created_at']) ??
                                        DateTime.now(),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          /// Add Comment
          Container(
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
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  width: 36,
                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => _addComment(_commentController.text),
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
                            : const Icon(
                              Icons.send,
                              size: 18,
                              color: Colors.white,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 1) return 'just now';
    if (difference.inSeconds < 60) return '${difference.inSeconds} seconds ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${(difference.inDays / 7).floor()} weeks ago';
  }
}
