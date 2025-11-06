import 'package:flutter/material.dart';
import '../../../services/data_manager.dart';

/// Openlist设置页面 - 管理Openlist服务器相关设置
class OpenlistPage extends StatefulWidget {
  const OpenlistPage({super.key});

  @override
  State<OpenlistPage> createState() => _OpenlistPageState();
}

/// Openlist设置页面状态类
class _OpenlistPageState extends State<OpenlistPage> {
  final DataManager _dataManager = DataManager();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    _addressController.text = _dataManager.serverAddress;
    _usernameController.text = _dataManager.username;
    
    // 密码需要从安全存储加载
    if (_dataManager.rememberPassword) {
      final password = await _dataManager.getPasswordFromSecureStorage();
      _passwordController.text = password;
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    // 保存开关设置
    await _dataManager.setRememberAddress(_dataManager.rememberAddress);
    await _dataManager.setRememberAccount(_dataManager.rememberAccount);
    await _dataManager.setRememberPassword(_dataManager.rememberPassword);
    await _dataManager.setAutoLogin(_dataManager.autoLogin);

    // 保存服务器地址（如果启用记住地址）
    if (_dataManager.rememberAddress) {
      await _dataManager.setServerAddress(_addressController.text.trim());
    }

    // 保存用户名（如果启用记住账号）
    if (_dataManager.rememberAccount) {
      await _dataManager.setUsername(_usernameController.text.trim());
    }

    // 保存密码（如果启用记住密码）
    if (_dataManager.rememberPassword) {
      await _dataManager.setPassword(_passwordController.text.trim());
    }

    _showSnackBar('设置已保存');
  }

  /// 验证自动登录设置
  bool _validateAutoLoginSettings() {
    if (!_dataManager.autoLogin) return true;
    
    final hasAddress = _addressController.text.trim().isNotEmpty;
    final hasUsername = _usernameController.text.trim().isNotEmpty;
    final hasPassword = _passwordController.text.trim().isNotEmpty;
    
    return hasAddress && hasUsername && hasPassword;
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
        title: const Text('Openlist设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: '保存设置',
            ),
        ],
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
                            title: '记住Openlist地址',
                            subtitle: '自动保存上次使用的服务器地址',
                            value: _dataManager.rememberAddress,
                            onChanged: (value) {
                              setState(() {
                                _dataManager.setRememberAddress(value);
                              });
                            },
                          ),
                          _buildSwitchItem(
                            title: '记住Openlist账号',
                            subtitle: '自动保存上次使用的用户名',
                            value: _dataManager.rememberAccount,
                            onChanged: (value) {
                              setState(() {
                                _dataManager.setRememberAccount(value);
                              });
                            },
                          ),
                          _buildSwitchItem(
                            title: '记住Openlist密码',
                            subtitle: '自动保存密码用于快速登录',
                            value: _dataManager.rememberPassword,
                            onChanged: (value) {
                              setState(() {
                                _dataManager.setRememberPassword(value);
                              });
                            },
                          ),
                          _buildSwitchItem(
                            title: '自动登录',
                            subtitle: '应用启动时自动尝试登录',
                            value: _dataManager.autoLogin,
                            onChanged: (value) {
                              setState(() {
                                if (value && !_validateAutoLoginSettings()) {
                                  _showSnackBar('请先填写服务器地址、用户名和密码');
                                  return;
                                }
                                _dataManager.setAutoLogin(value);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 服务器信息卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '服务器信息',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _addressController,
                            label: 'Openlist 地址',
                            hintText: '如192.168.0.1:5244',
                            icon: Icons.cloud,
                            enabled: _dataManager.rememberAddress,
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _usernameController,
                            label: '用户名',
                            hintText: '请输入用户名',
                            icon: Icons.person,
                            enabled: _dataManager.rememberAccount,
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: '密码',
                            hintText: '请输入密码',
                            icon: Icons.lock,
                            obscureText: true,
                            enabled: _dataManager.rememberPassword,
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                          if (_dataManager.autoLogin && !_validateAutoLoginSettings())
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '自动登录需要填写完整的服务器信息',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _addressController.clear();
                            _usernameController.clear();
                            _passwordController.clear();
                            _showSnackBar('记录已清空');
                          },
                          child: const Text('清空记录'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _dataManager.autoLogin && !_validateAutoLoginSettings() ? null : _saveSettings,
                          child: const Text('保存设置'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 数据管理卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '数据管理',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('清除所有数据'),
                                      content: const Text('这将清除所有保存的服务器地址、账号和密码。此操作不可撤销。'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('取消'),
                                        ),
                                        FilledButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            await _dataManager.clearAllData();
                                            await _loadSettings();
                                            _showSnackBar('所有数据已清除');
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                          child: const Text('确认清除'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('清除所有保存的数据'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  /// 构建文本输入字段
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: enabled ? null : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}