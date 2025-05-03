import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animations/animations.dart';
import 'create_post_screen.dart';
import 'message_screen.dart';
import 'view_post_screen.dart';
import 'friends_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeContent(),
    const MessageScreen(friendName: ''),
    const FriendsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<User?> _getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF900C3F),
        title: Text(
          'Namaste Messenger',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SortOptions(),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: FutureBuilder<User?>(
          future: _getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final user = snapshot.data;

            return Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF900C3F)),
                  accountName: Text(
                    user?.id ?? 'No ID',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  accountEmail: Text(
                    user?.email ?? 'No email',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFF900C3F)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFF900C3F)),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF900C3F),
                      fontSize: 14,
                    ),
                  ),
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF900C3F), Color(0xFFF5B8CF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: _screens[_selectedIndex],
        ),
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                backgroundColor: const Color(0xFF900C3F),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePostScreen(),
                      ),
                    ),
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF900C3F),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_rounded),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_rounded),
            label: 'Friends',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _postsFuture = Supabase.instance.client.from('posts').select().then((
    posts,
  ) async {
    final userIds = posts.map((post) => post['user_id']).toSet().toList();
    final profiles = await Supabase.instance.client
        .from('profiles')
        .select('id, name, email')
        .inFilter('id', userIds);

    final profilesMap = {for (var profile in profiles) profile['id']: profile};
    return posts.map((post) {
      post['user_name'] = profilesMap[post['user_id']]?['name'] ?? 'Anonymous';
      return post;
    }).toList();
  });

  String _sortBy = 'date'; // Default sorting by date

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              var posts = snapshot.data as List<dynamic>? ?? [];
              if (_sortBy == 'title') {
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

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewPostScreen(post: post),
                        ),
                      );
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
                                const CircleAvatar(
                                  radius: 16, // Reduced size
                                  backgroundColor: Color(0xFF900C3F),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 16, // Adjusted icon size
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF900C3F),
                                      ),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
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
                                fontSize: 16,
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
                                fontSize: 14,
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
                                    fontSize: 12,
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
                                      fontSize: 12,
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
        ),
      ],
    );
  }

  String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
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
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            content: TextField(
              controller: commentController,
              decoration: const InputDecoration(hintText: 'Enter your comment'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 12)),
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
                child: Text('Submit', style: GoogleFonts.poppins(fontSize: 12)),
              ),
            ],
          ),
    );
  }
}

class SortOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Sort by Date'),
            onTap: () {
              Navigator.pop(context);
              // Implement sorting logic here
            },
          ),
          ListTile(
            leading: const Icon(Icons.title),
            title: const Text('Sort by Title'),
            onTap: () {
              Navigator.pop(context);
              // Implement sorting logic here
            },
          ),
        ],
      ),
    );
  }
}
