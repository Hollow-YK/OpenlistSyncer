import 'package:flutter/material.dart';
import '../../../services/data_manager.dart';

/// 同步设置页面 - 管理文件同步相关设置
class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

/// 同步设置页面状态类
class _SyncSettingsPageState extends State<SyncSettingsPage> {
  final DataManager _dataManager = DataManager();
  final TextEditingController _sourcePathController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 加载设置
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    // 等待数据管理器初始化
    await _dataManager.init();

    // 填充表单
    _sourcePathController.text = _dataManager.sourcePath;

    setState(() {
      _isLoading = false;
    });
  }

  /// 处理记住功能开关变化
  /// [newValue] 新的开关状态
  Future<void> _handleRememberSourcePathChange(bool newValue) async {
    await _dataManager.setRememberSourcePath(newValue);
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 功能开关卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '功能设置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSwitchItem(
                            title: '记住源路径',
                            subtitle: '自动保存上次使用的Openlist源路径',
                            value: _dataManager.rememberSourcePath,
                            onChanged: _handleRememberSourcePathChange,
                          ),
                          const SizedBox(height: 16),
                          _buildSwitchItem(
                            title: '记住本地路径',
                            subtitle: '自动保存上次使用的本地路径',
                            value: false,
                            onChanged: (bool value) {
                              _showSnackBar('还没写完，下次一定');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  /// 构建开关选项
  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sourcePathController.dispose();
    super.dispose();
  }
}