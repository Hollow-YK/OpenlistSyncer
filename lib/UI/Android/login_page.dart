import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 登录页面组件
class LoginPage extends StatefulWidget {
  final TextEditingController addressController; // 服务器地址控制器
  final String? authToken; // 认证令牌
  final String? loggedInUser; // 登录用户
  final bool isLoggedIn; // 登录状态
  final Function(String?, String?, bool) onAuthStatusChanged; // 认证状态改变回调

  const LoginPage({
    super.key,
    required this.addressController,
    required this.authToken,
    required this.loggedInUser,
    required this.isLoggedIn,
    required this.onAuthStatusChanged,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// 登录页面状态类
class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Openlist 登录'), // 页面标题
        backgroundColor: Theme.of(context).colorScheme.inversePrimary, // 使用主题色
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 内边距
        child: Column(
          children: [
            // 状态指示卡片
            Card(
              color: widget.isLoggedIn ? Colors.green[50] : Colors.blue[50], // 根据登录状态改变颜色
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      widget.isLoggedIn ? Icons.check_circle : Icons.info, // 状态图标
                      color: widget.isLoggedIn ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 12), // 间距
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                        children: [
                          Text(
                            widget.isLoggedIn ? '已登录' : '未登录', // 状态文本
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isLoggedIn ? Colors.green[800] : Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isLoggedIn 
                                ? '当前用户: ${widget.loggedInUser}' // 显示用户名
                                : '请先登录Openlist服务器', // 提示信息
                            style: TextStyle(
                              color: widget.isLoggedIn ? Colors.green[700] : Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24), // 间距
            
            Expanded(
              child: ListView( // 可滚动列表
                children: [
                  // 服务器设置卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100], // 标签背景色
                                  borderRadius: BorderRadius.circular(12), // 圆角
                                ),
                                child: Text(
                                  '服务器设置',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildAddressField(), // 构建地址输入字段
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 账户设置卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '账户设置',
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildAccountSettings(), // 构建账户设置区域
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建地址输入字段
  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Openlist 地址 *', // 必填字段标记
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant, // 使用主题色
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.addressController, // 绑定控制器
          decoration: InputDecoration(
            hintText: '192.168.0.1:5244', // 占位符文本
            prefixIcon: const Icon(Icons.cloud), // 前缀图标
            border: const OutlineInputBorder(), // 边框样式
            filled: true, // 填充背景
            suffixIcon: widget.isLoggedIn
                ? const Icon(Icons.check_circle, color: Colors.green) // 登录成功显示勾选图标
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '请输入Openlist服务器的IP地址和端口', // 帮助文本
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // 构建账户设置区域
  Widget _buildAccountSettings() {
    return Column(
      children: [
        if (widget.isLoggedIn) ...[ // 如果已登录，显示用户信息和退出按钮
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text('当前用户'),
            subtitle: Text(widget.loggedInUser ?? ''), // 显示用户名
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, // 宽度填满
            child: OutlinedButton(
              onPressed: () {
                widget.onAuthStatusChanged(null, null, false); // 退出登录
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('退出登录'),
                ],
              ),
            ),
          ),
        ] else ...[ // 如果未登录，显示登录按钮
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _showLoginDialog, // 显示登录对话框
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login),
                  SizedBox(width: 8),
                  Text('登录 Openlist'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 显示登录对话框
  Future<void> _showLoginDialog() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController otpController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('登录 Openlist'),
          content: SingleChildScrollView( // 可滚动内容
            child: Column(
              mainAxisSize: MainAxisSize.min, // 最小高度
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true, // 密码模式
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  decoration: const InputDecoration(
                    labelText: '两步验证码 (2FA，可选)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number, // 数字键盘
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 取消按钮
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await _performLogin( // 执行登录
                  usernameController.text.trim(),
                  passwordController.text.trim(),
                  otpController.text.trim(),
                );
                if (!mounted) return;
                Navigator.of(context).pop(); // 关闭对话框
              },
              child: const Text('登录'),
            ),
          ],
        );
      },
    );
  }

  // 执行登录操作
  Future<void> _performLogin(String username, String password, String otpCode) async {
    final address = widget.addressController.text.trim();

    if (address.isEmpty) {
      _showSnackBar('请先输入Openlist地址');
      return;
    }

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('请输入用户名和密码');
      return;
    }

    try {
      final url = Uri.parse('http://$address/api/auth/login'); // 构建登录URL
      final Map<String, dynamic> requestBody = {
        'username': username,
        'password': password,
      };
      
      if (otpCode.isNotEmpty) {
        requestBody['otp_code'] = otpCode; // 添加两步验证码
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody), // 编码请求体
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          // 登录成功，更新认证状态
          widget.onAuthStatusChanged(data['data']['token'], username, true);
        } else {
          _showSnackBar('登录失败: ${data['message']}');
        }
      } else {
        _showSnackBar('登录失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('登录出错: $e');
    }
  }

  // 显示提示消息
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating, // 浮动样式
      ),
    );
  }
}