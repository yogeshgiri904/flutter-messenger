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
  late Future<List<dynamic>> _commentsFuture;
  late Future<Map<String, dynamic>?> _postAuthorFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _fetchComments();
    _postAuthorFuture = _fetchPostAuthor();
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

  Future<List<dynamic>> _fetchComments() async {
    final comments = await Supabase.instance.client
        .from('comments')
        .select('id, content, created_at, user_id')
        .eq('post_id', widget.post['id'])
        .order('created_at', ascending: false);

    final userIds = comments.map((c) => c['user_id']).toSet().toList();

    final profiles = await Supabase.instance.client
        .from('profiles')
        .select('id, name, email')
        .inFilter('id', userIds);

    final userMap = {for (var profile in profiles) profile['id']: profile};

    for (var comment in comments) {
      comment['user'] = userMap[comment['user_id']];
    }
    return comments;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'View Post',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF900C3F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Post Title
              Row(
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 20,
                    color: Color(0xFF900C3F),
                  ),
                  const SizedBox(width: 8),
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

              const SizedBox(height: 8),

              /// Post Meta (author & date)
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
                        'By ${author?['name'] ?? 'Unknown'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post['created_at']?.toString().split('T').first ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              /// Post Content
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post['content'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
                ),
              ),

              const SizedBox(height: 24),

              /// Comments Section
              Row(
                children: [
                  const Icon(
                    Icons.comment_outlined,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Comments',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              FutureBuilder<List<dynamic>>(
                future: _commentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Error loading comments: ${snapshot.error}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    );
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return Text(
                      'No comments yet.',
                      style: GoogleFonts.poppins(fontSize: 12),
                    );
                  }

                  return Column(
                    children:
                        comments.map((comment) {
                          final user = comment['user'];
                          final createdAt =
                              comment['created_at']
                                  ?.toString()
                                  .split('T')
                                  .first ??
                              '';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              leading: const Icon(
                                Icons.person_outline,
                                size: 24,
                                color: Colors.grey,
                              ),
                              title: Text(
                                comment['content'] ?? '',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              subtitle: Text(
                                'By ${user?['name'] ?? 'Unknown'} • $createdAt',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
