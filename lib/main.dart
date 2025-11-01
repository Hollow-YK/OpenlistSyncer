import 'package:flutter/material.dart';
import 'ui/android/login_page.dart';
import 'ui/android/sync_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Openlist Sync',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  String? _authToken;
  String? _loggedInUser;
  bool _isLoggedIn = false;
  final TextEditingController _addressController = TextEditingController();

  void _updateAuthStatus(String? token, String? user, bool isLoggedIn) {
    if (!mounted) return;
    setState(() {
      _authToken = token;
      _loggedInUser = user;
      _isLoggedIn = isLoggedIn;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      LoginPage(
        addressController: _addressController,
        authToken: _authToken,
        loggedInUser: _loggedInUser,
        isLoggedIn: _isLoggedIn,
        onAuthStatusChanged: _updateAuthStatus,
      ),
      SyncPage(
        addressController: _addressController,
        authToken: _authToken,
        loggedInUser: _loggedInUser,
        isLoggedIn: _isLoggedIn,
        onAuthStatusChanged: _updateAuthStatus,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: !_isLoggedIn,
              backgroundColor: Colors.red,
              smallSize: 8,
              child: const Icon(Icons.login),
            ),
            label: '登录',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _isLoggedIn,
              backgroundColor: Colors.green,
              smallSize: 8,
              child: const Icon(Icons.sync),
            ),
            label: '同步',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}