import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  final TextEditingController addressController;
  final String? authToken;
  final String? loggedInUser;
  final bool isLoggedIn;
  final Function(String?, String?, bool) onAuthStatusChanged;

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

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Openlist 登录'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 状态指示卡片
            Card(
              color: widget.isLoggedIn ? Colors.green[50] : Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      widget.isLoggedIn ? Icons.check_circle : Icons.info,
                      color: widget.isLoggedIn ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isLoggedIn ? '已登录' : '未登录',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isLoggedIn ? Colors.green[800] : Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isLoggedIn 
                                ? '当前用户: ${widget.loggedInUser}'
                                : '请先登录Openlist服务器',
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
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView(
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
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
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
                          _buildAddressField(),
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
                                  color: Colors.blue[100], // 使用相同的蓝色
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '账户设置',
                                  style: TextStyle(
                                    color: Colors.blue[800], // 使用相同的蓝色
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildAccountSettings(),
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

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Openlist 地址 *',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.addressController,
          decoration: InputDecoration(
            hintText: '192.168.0.1:5244',
            prefixIcon: const Icon(Icons.cloud),
            border: const OutlineInputBorder(),
            filled: true,
            suffixIcon: widget.isLoggedIn
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '请输入Openlist服务器的IP地址和端口',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return Column(
      children: [
        if (widget.isLoggedIn) ...[
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text('当前用户'),
            subtitle: Text(widget.loggedInUser ?? ''),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                widget.onAuthStatusChanged(null, null, false);
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
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _showLoginDialog,
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

  Future<void> _showLoginDialog() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController otpController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('登录 Openlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  decoration: const InputDecoration(
                    labelText: '两步验证码 (2FA，可选)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await _performLogin(
                  usernameController.text.trim(),
                  passwordController.text.trim(),
                  otpController.text.trim(),
                );
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('登录'),
            ),
          ],
        );
      },
    );
  }

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
      final url = Uri.parse('http://$address/api/auth/login');
      final Map<String, dynamic> requestBody = {
        'username': username,
        'password': password,
      };
      
      if (otpCode.isNotEmpty) {
        requestBody['otp_code'] = otpCode;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}