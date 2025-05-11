import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:namaste_flutter/screens/inbox_screen.dart';
import 'package:namaste_flutter/screens/not_found.dart';

import '../notifiers/message_notifier.dart';
import 'home_drawer.dart';
import 'home_content.dart';
import 'custom_app_bar.dart';
import 'home_body.dart';
import 'navigation_bar.dart';
import 'friends_screen.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _currentSort = 'date'; // Default sort
  final GlobalKey<HomeContentState> _homeContentKey = GlobalKey<HomeContentState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContent(
        key: _homeContentKey,
        refreshCallback: _refreshPosts,
        currentSort: _currentSort,
        onSortSelected: _onSortSelected,
      ),
      const NotFoundPage(),
      const InboxScreen(),
      const FriendsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _refreshPosts() {
    _homeContentKey.currentState?.refreshPosts();
  }

  void _onSortSelected(String newSort) {
    setState(() {
      _currentSort = newSort;
    });
    _refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<MessageNotifier>().unreadCount;

    return Scaffold(
      appBar: buildCustomAppBar(context, _currentSort, _onSortSelected),
      drawer: HomeDrawer(),
      body: HomeBody(screen: _screens[_selectedIndex]),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF900C3F),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                );
                _refreshPosts();
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
