import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:namaste_flutter/screens/view_post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class HomeContent extends StatefulWidget {
  final void Function() refreshCallback; // Adding the callback
  const HomeContent({super.key, required this.refreshCallback, required String currentSort, required void Function(String newSort) onSortSelected}); // Required constructor for callback

  @override
  HomeContentState createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String sortBy = 'date'; // default sort
  late Future<List<dynamic>> _postsFuture; // Declare as late, so it can be initialized later

  @override
  void initState() {
    super.initState();
    // Initialize _postsFuture here
    _postsFuture = _fetchPosts();
  }

  Future<List<dynamic>> _fetchPosts() async {
    final posts = await Supabase.instance.client.from('posts').select();
    final userIds = posts.map((post) => post['user_id']).toSet().toList();
    final profiles = await Supabase.instance.client
        .from('profiles')
        .select('id, name, gender, email')
        .inFilter('id', userIds);

    final profilesMap = {for (var profile in profiles) profile['id']: profile};
    return posts.map((post) {
      post['user_name'] = profilesMap[post['user_id']]?['name'] ?? 'Anonymous';
      post['gender'] = profilesMap[post['user_id']]?['gender'] ?? '';
      return post;
    }).toList();
  }

  Future<void> refreshPosts() async {
    final newPosts = await _fetchPosts();
    setState(() {
      _postsFuture = Future.value(newPosts); // Refresh the future with new data
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshPosts,
      child: FutureBuilder<List<dynamic>>(
        future: _postsFuture, // Use _postsFuture
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          var posts = snapshot.data ?? [];
          if (sortBy == 'title') {
            posts.sort(
              (a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''),
            );
          } else {
            posts.sort(
              (a, b) =>
                  (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final createdAt = DateTime.tryParse(post['created_at'] ?? '');
              final formattedDate =
                  createdAt != null ? timeAgo(createdAt) : 'NA';
              final userName = post['user_name'] ?? 'Anonymous';
              final gender = post['gender']?.toLowerCase();

              IconData genderIcon;
              Color getRandomColor() {
                final Random random = Random();

                return Color.fromARGB(
                  255, // full opacity
                  random.nextInt(180), // red
                  random.nextInt(200), // green
                  random.nextInt(200), // blue
                );
              }

              Color avatarColor = getRandomColor();

              if (gender == 'female') {
                genderIcon = Icons.girl_outlined;
                // avatarColor = Colors.pinkAccent;
              } else if (gender == 'male') {
                genderIcon = Icons.boy_outlined;
                // avatarColor = Colors.blueAccent;
              } else {
                genderIcon = Icons.person;
                // avatarColor = Colors.grey;
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewPostScreen(post: post),
                    ),
                  ).then((_) {
                    widget.refreshCallback(); // Call the callback on refresh
                  });
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  color: const Color(0xFFFDECEF),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                            radius: 16,
                            backgroundColor: avatarColor,
                            child: Icon(
                              genderIcon,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                            // const CircleAvatar(
                            //   radius: 16,
                            //   backgroundColor: Color(0xFF900C3F),
                            //   child: Icon(
                            //     Icons.person,
                            //     color: Colors.white,
                            //     size: 16,
                            //   ),
                            // ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF900C3F),
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          post['title'] ?? 'Untitled',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF900C3F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (post['content'] ?? '').toString().length > 100
                              ? '${(post['content'] ?? '').toString().substring(0, 100)}...'
                              : post['content'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Posted: $formattedDate',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF900C3F),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                _showCommentDialog(context, post['id']);
                              },
                              icon: const Icon(
                                Icons.comment_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(
                                'Comment',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper function to format time ago (you need to define this)
  String timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 365) {
      return '${(duration.inDays / 365).floor()} years ago';
    } else if (duration.inDays > 30) {
      return '${(duration.inDays / 30).floor()} months ago';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} days ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showCommentDialog(BuildContext context, dynamic postId) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Add Comment',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            content: TextField(
              controller: commentController,
              decoration: const InputDecoration(hintText: 'Enter your comment'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 10)),
              ),
              TextButton(
                onPressed: () async {
                  final comment = commentController.text.trim();
                  if (comment.isNotEmpty) {
                    try {
                      final user = Supabase.instance.client.auth.currentUser;
                      await Supabase.instance.client.from('comments').insert({
                        'post_id': postId,
                        'content': comment,
                        'user_id': user?.id,
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment added!')),
                        );
                        widget.refreshCallback();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error adding comment: $e')),
                        );
                      }
                    }
                  }
                },
                child: Text('Submit', style: GoogleFonts.poppins(fontSize: 10)),
              ),
            ],
          ),
    );
  }

}
