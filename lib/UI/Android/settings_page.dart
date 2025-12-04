import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings/openlist_page.dart'; // 导入Openlist设置页面
import 'settings/sync_page.dart'; // 导入同步设置页面
import 'settings/theme_page.dart'; // 导入主题设置页面
import 'settings/about_page.dart'; // 导入关于页面

/// 设置页面组件
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

/// 设置页面状态类
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
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: const Text(
              '应用设置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Card(
            margin: const EdgeInsets.all(9),
            child: Column(
              children: [
                // Openlist选项
                _buildSettingsItem(
                  icon: Icons.person,
                  title: 'Openlist设置',
                  subtitle: '记住Openlist地址、账号等',
                  onTap: () {
                    // 跳转到Openlist设置页面
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OpenlistPage(),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
                // 同步选项
                _buildSettingsItem(
                  icon: Icons.sync_outlined,
                  title: '同步',
                  subtitle: '记住路径等',
                  onTap: () {
                    // 跳转到同步设置
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SyncSettingsPage(),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
                // 主题选项
                _buildSettingsItem(
                  icon: Icons.palette_outlined,
                  title: '主题',
                  subtitle: '切换主题明暗与配色',
                  onTap: () {
                    // 跳转到主题设置
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemePage(),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: const Text(
              '关于本项目',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
            ),
          ),

          Card(
            margin: const EdgeInsets.all(9),
            child: Column(
              children: [
                // GitHub选项
                _buildSettingsItem(
                  icon: Icons.code,
                  title: 'GitHub',
                  subtitle: '前往本项目的GitHub页面',
                  onTap: () async{
                    // 跳转到关于页面
                    try {
                      const githubUrl = 'https://github.com/Hollow-YK/OpenlistSyncer';
                      await launchUrl(
                        Uri.parse(githubUrl),
                        mode: LaunchMode.externalApplication, // 在外部浏览器中打开
                      );
                    } catch (e) {
                      _showSnackBar('打开GitHub页面时出错: $e');
                    }
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
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
                      Text('退出登录 Openlist'),
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

  /// 构建设置项组件
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

  /// 显示提示消息
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