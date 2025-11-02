import 'package:flutter/material.dart';
import 'ui/android/login_page.dart';
import 'ui/android/sync_page.dart';

// 应用入口点
void main() {
  runApp(const MyApp()); // 启动Flutter应用
}

// 主应用组件，继承StatelessWidget（无状态组件）
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // 构造函数，接收可选的key参数

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Openlist Sync', // 应用名称
      theme: ThemeData( // 明亮主题配置
        useMaterial3: true, // 使用Material 3设计
        colorScheme: ColorScheme.fromSeed( // 从种子颜色生成配色方案
          seedColor: Colors.blue, // 种子颜色为蓝色
          brightness: Brightness.light, // 明亮模式
        ),
      ),
      darkTheme: ThemeData( // 暗黑主题配置
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark, // 暗黑模式
        ),
      ),
      home: const MainApp(), // 设置主页组件
    );
  }
}

// 主应用状态管理组件，继承StatefulWidget（有状态组件）
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState(); // 创建对应的状态类
}

// 主应用状态类
class _MainAppState extends State<MainApp> {
  int _currentIndex = 0; // 当前底部导航栏选中的索引
  String? _authToken; // 认证令牌，可能为空
  String? _loggedInUser; // 登录用户名，可能为空
  bool _isLoggedIn = false; // 登录状态标识
  final TextEditingController _addressController = TextEditingController(); // 服务器地址输入控制器

  // 更新认证状态的方法
  void _updateAuthStatus(String? token, String? user, bool isLoggedIn) {
    if (!mounted) return; // 如果组件未挂载，直接返回（避免在组件销毁后调用setState）
    setState(() { // 更新状态并触发UI重建
      _authToken = token;
      _loggedInUser = user;
      _isLoggedIn = isLoggedIn;
    });
  }

  // 底部导航栏标签点击事件处理
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index; // 更新当前选中的标签索引
    });
  }

  @override
  Widget build(BuildContext context) {
    // 定义页面列表，包含登录页和同步页
    final List<Widget> pages = [
      LoginPage( // 登录页面
        addressController: _addressController,
        authToken: _authToken,
        loggedInUser: _loggedInUser,
        isLoggedIn: _isLoggedIn,
        onAuthStatusChanged: _updateAuthStatus,
      ),
      SyncPage( // 同步页面
        addressController: _addressController,
        authToken: _authToken,
        loggedInUser: _loggedInUser,
        isLoggedIn: _isLoggedIn,
        onAuthStatusChanged: _updateAuthStatus,
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex], // 根据当前索引显示对应页面
      bottomNavigationBar: BottomNavigationBar( // 底部导航栏
        currentIndex: _currentIndex, // 当前选中索引
        onTap: _onTabTapped, // 点击事件处理
        items: [ // 导航项配置
          BottomNavigationBarItem(
            icon: Badge( // 徽章组件，用于显示登录状态指示
              isLabelVisible: !_isLoggedIn, // 未登录时显示红色徽章
              backgroundColor: Colors.red,
              smallSize: 8,
              child: const Icon(Icons.login), // 登录图标
            ),
            label: '登录', // 标签文本
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _isLoggedIn, // 登录时显示绿色徽章
              backgroundColor: Colors.green,
              smallSize: 8,
              child: const Icon(Icons.sync), // 同步图标
            ),
            label: '同步', // 标签文本
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose(); // 销毁控制器，释放资源
    super.dispose();
  }
}