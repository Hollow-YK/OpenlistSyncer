import 'package:flutter/material.dart';
import 'services/settings_manager.dart';
import 'services/data_manager.dart';
import 'UI/Android/login_page.dart';
import 'UI/Android/sync_page.dart';
import 'UI/Android/settings_page.dart';

/// 应用入口点
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化
  
  // 初始化设置管理器 - 在运行应用前加载保存的设置
  await SettingsManager().init();
  
  // 初始化数据管理器 - 加载用户数据
  await DataManager().init();
  
  runApp(const MyApp());
}

/// 主应用组件
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// 主应用状态类 - 负责监听主题变化并重建应用
class _MyAppState extends State<MyApp> {
  final SettingsManager _settingsManager = SettingsManager();

  @override
  void initState() {
    super.initState();
    // 添加主题变化监听器 - 当主题改变时重建应用
    _settingsManager.addListener(_onThemeChanged);
  }

  /// 主题变化回调函数
  void _onThemeChanged() {
    setState(() {
      // 空setState，目的是强制重建整个应用以应用新主题
    });
  }

  @override
  void dispose() {
    // 移除主题变化监听器 - 避免内存泄漏
    _settingsManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = _settingsManager.getCurrentThemeConfig();
    
    return MaterialApp(
      title: 'Openlist Sync',
      theme: _settingsManager.generateThemeData(isLight: true),      // 亮色主题
      darkTheme: _settingsManager.generateThemeData(isLight: false), // 暗色主题
      themeMode: themeConfig['themeModeEnum'] as ThemeMode, // 当前主题模式
      home: const MainApp(),
    );
  }
}

/// 主应用页面组件 - 包含底部导航和页面切换
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

/// 主应用页面状态类
class _MainAppState extends State<MainApp> {
  int _currentIndex = 0; // 当前选中的底部导航项索引
  String? _authToken;    // 认证令牌
  String? _loggedInUser; // 登录用户名
  bool _isLoggedIn = false; // 登录状态
  final TextEditingController _addressController = TextEditingController(); // 服务器地址控制器
  final SettingsManager _settingsManager = SettingsManager();

  /// 更新认证状态
  /// [token] 新的认证令牌
  /// [user] 登录用户名
  /// [isLoggedIn] 是否已登录
  void _updateAuthStatus(String? token, String? user, bool isLoggedIn) {
    if (!mounted) return; // 如果组件未挂载，直接返回
    setState(() {
      _authToken = token;
      _loggedInUser = user;
      _isLoggedIn = isLoggedIn;
    });
  }

  /// 底部导航项点击处理
  /// [index] 点击的导航项索引
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index; // 更新当前选中索引
    });
  }

  @override
  Widget build(BuildContext context) {
    // 页面列表
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
      SettingsPage(
        addressController: _addressController,
        authToken: _authToken,
        loggedInUser: _loggedInUser,
        isLoggedIn: _isLoggedIn,
        onAuthStatusChanged: _updateAuthStatus,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex], // 显示当前选中的页面
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: _settingsManager.seedColor, // 选中项使用主题色
        unselectedItemColor: Colors.grey, // 未选中项使用灰色
        backgroundColor: Theme.of(context).colorScheme.surface, // 背景色使用表面色
        type: BottomNavigationBarType.fixed, // 固定类型，确保所有项都显示标签
        items: [
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: !_isLoggedIn, // 未登录时显示红色徽章
              backgroundColor: Colors.red,
              smallSize: 8,
              child: const Icon(Icons.login),
            ),
            label: '登录',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _isLoggedIn, // 登录时显示绿色徽章
              backgroundColor: Colors.green,
              smallSize: 8,
              child: const Icon(Icons.sync),
            ),
            label: '同步',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose(); // 销毁控制器
    super.dispose();
  }
}