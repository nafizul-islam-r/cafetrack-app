import 'package:cafetrack/add_board_game_screen.dart';
import 'package:cafetrack/add_food_item_screen.dart';
import 'package:cafetrack/board_games_screen.dart';
import 'package:cafetrack/inventory_list_page.dart';
import 'package:cafetrack/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted && userDoc.exists) {
      setState(() {
        _userRole = userDoc.data()?['role'] ?? 'user';
      });
    }
  }

  static const List<Widget> _pages = <Widget>[
    InventoryListPage(),
    BoardGamesScreen(),
    ProfileScreen(),
  ];

  static const List<String> _pageTitles = [
    'Food Inventory',
    'Board Games',
    'My Profile',
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget? _buildFab() {
    if (_userRole != 'admin') {
      return null;
    }

    if (_selectedIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const AddFoodItemScreen()),
          );
        },
        tooltip: 'Add Food Item',
        child: const Icon(Icons.add),
      );
    }
    else if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const AddBoardGameScreen()),
          );
        },
        tooltip: 'Add Board Game',
        child: const Icon(Icons.add),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: 'Board Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _buildFab(),
    );
  }
}