import 'package:cafetrack_flutter/login_screen.dart';
import 'services/mongo_service.dart';
import 'services/cart_service.dart';
import 'screens/cart_screen.dart';
import 'screens/my_orders_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/wishlist_screen.dart';
import 'services/mongo_service.dart';
import 'package:cafetrack_flutter/add_board_game_screen.dart';
import 'package:cafetrack_flutter/add_food_item_screen.dart';
import 'package:cafetrack_flutter/board_games_screen.dart';
import 'package:cafetrack_flutter/inventory_list_page.dart';
import 'package:cafetrack_flutter/profile_screen.dart';
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
    final user = MongoService.currentUser;
    if (user == null) return;
    if (mounted) {
      setState(() {
        _userRole = user['role'] ?? 'user';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CartService().addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartService().removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const CartScreen()),
                  );
                },
              ),
              if (CartService().itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${CartService().itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () async {
              await MongoService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                );
              }
            },
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'CafeTrack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('My Orders'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const MyOrdersScreen()),
                );
              },
            ),
            if (_userRole == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Manage Orders'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const AdminOrdersScreen()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Wishlist'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const WishlistScreen()),
                );
              },
            ),
          ],
        ),
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