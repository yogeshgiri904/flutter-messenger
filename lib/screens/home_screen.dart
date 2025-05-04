import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animations/animations.dart';
import 'create_post_screen.dart';
import 'message_screen.dart';
import 'view_post_screen.dart';
import 'friends_screen.dart';
import 'login_screen.dart';

class ProfileUser {
  final String id;
  final String name;
  final String email;

  ProfileUser({required this.id, required this.name, required this.email});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<_HomeContentState> _homeContentKey =
      GlobalKey<_HomeContentState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContent(key: _homeContentKey, refreshCallback: _refreshPosts),
      const MessageScreen(friendName: ''),
      const FriendsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<ProfileUser?> _getCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final response =
        await Supabase.instance.client
            .from('profiles')
            .select('name, email')
            .eq('id', user.id)
            .maybeSingle();

    if (response == null) return null;

    return ProfileUser(
      id: user.id,
      name: response['name'] ?? 'No name',
      email: response['email'] ?? 'No email',
    );
  }

  void _refreshPosts() {
    _homeContentKey.currentState?.refreshPosts();
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
            fontSize: 18,
            fontWeight: FontWeight.w500,
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
        child: FutureBuilder<ProfileUser?>(
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
                    user?.name ?? 'Anonymous',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  accountEmail: Text(
                    user?.email ?? 'No email',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
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
                      fontSize: 12,
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
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                  );
                  _refreshPosts(); // Now actually refreshes HomeContent
                },
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
  final Function refreshCallback;

  const HomeContent({super.key, required this.refreshCallback});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<dynamic>> _postsFuture;
  final String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  Future<List<dynamic>> _fetchPosts() async {
    final posts = await Supabase.instance.client.from('posts').select();
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
  }

  Future<void> refreshPosts() async {
    final newPosts = await _fetchPosts();
    setState(() {
      _postsFuture = Future.value(newPosts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshPosts,
      child: FutureBuilder(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          var posts = snapshot.data ?? [];
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
                  ).then((_) {
                    widget.refreshCallback();
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
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFF900C3F),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
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

class SortOptions extends StatelessWidget {
  const SortOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(
              'Sort by Date',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.title),
            title: Text(
              'Sort by Title',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
