import 'package:flutter/material.dart';
import 'settings/about.dart'; // 导入关于页面

class SettingsPage extends StatefulWidget {
  final TextEditingController addressController;
  final String? authToken;
  final String? loggedInUser;
  final bool isLoggedIn;
  final Function(String?, String?, bool) onAuthStatusChanged;

  const SettingsPage({
    super.key,
    required this.addressController,
    required this.authToken,
    required this.loggedInUser,
    required this.isLoggedIn,
    required this.onAuthStatusChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.isLoggedIn ? Icons.check_circle : Icons.person_outline,
                    color: widget.isLoggedIn ? Colors.green : Colors.grey,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isLoggedIn ? '已登录' : '未登录',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isLoggedIn 
                              ? '用户: ${widget.loggedInUser}'
                              : '请先登录Openlist服务器',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.isLoggedIn) ...[
                          const SizedBox(height: 4),
                          Text(
                            '服务器: ${widget.addressController.text}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 设置选项列表
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // 关于选项
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: '关于',
                  subtitle: '版本信息和应用介绍',
                  onTap: () {
                    // 跳转到关于页面
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
                
                // 可以在这里添加更多设置选项
                // 例如：
                // _buildSettingsItem(
                //   icon: Icons.notifications,
                //   title: '通知设置',
                //   subtitle: '管理应用通知',
                //   onTap: () {},
                //   trailing: const Icon(Icons.chevron_right),
                // ),
              ],
            ),
          ),

          // 退出登录按钮（仅在已登录时显示）
          if (widget.isLoggedIn) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    widget.onAuthStatusChanged(null, null, false);
                    _showSnackBar('已退出登录');
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
            ),
          ],
        ],
      ),
    );
  }

  // 构建设置项组件
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  // 显示提示消息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}