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
    
    // 直接使用内存中的密码
    if (_dataManager.rememberPassword) {
      _passwordController.text = _dataManager.password;
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    // 首先验证设置的有效性
    if (!_validateSettings()) {
      _showSnackBar('设置验证失败，请检查输入');
      return;
    }

    // 保存开关设置
    await _dataManager.setRememberAddress(_dataManager.rememberAddress);
    await _dataManager.setRememberAccount(_dataManager.rememberAccount);
    await _dataManager.setRememberPassword(_dataManager.rememberPassword);
    await _dataManager.setAutoLogin(_dataManager.autoLogin);

    // 保存服务器地址（如果启用记住地址）
    if (_dataManager.rememberAddress) {
      await _dataManager.setServerAddress(_addressController.text.trim());
    } else {
      // 如果未启用记住地址，清除已保存的地址
      await _dataManager.setServerAddress('');
    }

    // 保存用户名（如果启用记住账号）
    if (_dataManager.rememberAccount) {
      await _dataManager.setUsername(_usernameController.text.trim());
    } else {
      // 如果未启用记住账号，清除已保存的用户名
      await _dataManager.setUsername('');
    }

    // 保存密码（如果启用记住密码）
    if (_dataManager.rememberPassword) {
      await _dataManager.setPassword(_passwordController.text.trim());
    } else {
      // 如果未启用记住密码，清除已保存的密码
      await _dataManager.setPassword('');
    }

    _showSnackBar('设置已保存');
  }

  /// 验证设置的有效性
  /// 返回：设置是否有效
  bool _validateSettings() {
    // 检查自动登录设置
    if (_dataManager.autoLogin) {
      // 自动登录需要所有信息都填写完整
      final hasAddress = _addressController.text.trim().isNotEmpty;
      final hasUsername = _usernameController.text.trim().isNotEmpty;
      final hasPassword = _passwordController.text.trim().isNotEmpty;
      
      if (!hasAddress || !hasUsername || !hasPassword) {
        return false;
      }
    }

    // 检查各个记住功能的输入是否完整
    if (_dataManager.rememberAddress && _addressController.text.trim().isEmpty) {
      return false;
    }
    if (_dataManager.rememberAccount && _usernameController.text.trim().isEmpty) {
      return false;
    }
    if (_dataManager.rememberPassword && _passwordController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  /// 检查保存按钮是否可用
  /// 返回：保存按钮是否应该启用
  bool get _isSaveButtonEnabled {
    // 如果自动登录开启，需要验证所有信息完整
    if (_dataManager.autoLogin) {
      final hasAddress = _addressController.text.trim().isNotEmpty;
      final hasUsername = _usernameController.text.trim().isNotEmpty;
      final hasPassword = _passwordController.text.trim().isNotEmpty;
      
      if (!hasAddress || !hasUsername || !hasPassword) {
        return false;
      }
    }

    // 检查各个记住功能的输入是否完整
    // 如果某个记住功能开启，但对应的输入框为空，则不允许保存
    if (_dataManager.rememberAddress && _addressController.text.trim().isEmpty) {
      return false;
    }
    if (_dataManager.rememberAccount && _usernameController.text.trim().isEmpty) {
      return false;
    }
    if (_dataManager.rememberPassword && _passwordController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  /// 检查自动登录是否应该禁用
  /// 当记住地址、账号、密码都没有启用时，自动登录应该禁用
  bool get _isAutoLoginDisabled {
    return !_dataManager.rememberAddress && 
           !_dataManager.rememberAccount && 
           !_dataManager.rememberPassword;
  }

  /// 处理记住功能开关变化
  /// [type] 开关类型：'address', 'account', 'password'
  /// [newValue] 新的开关状态
  Future<void> _handleRememberSwitchChange(String type, bool newValue) async {
    switch (type) {
      case 'address':
        await _dataManager.setRememberAddress(newValue);
        break;
      case 'account':
        await _dataManager.setRememberAccount(newValue);
        break;
      case 'password':
        await _dataManager.setRememberPassword(newValue);
        break;
    }

    // 检查是否需要禁用自动登录
    // 如果所有记住功能都关闭，自动关闭自动登录
    if (_isAutoLoginDisabled && _dataManager.autoLogin) {
      await _dataManager.setAutoLogin(false);
    }

    setState(() {});
  }

  /// 处理自动登录开关变化
  /// [newValue] 新的自动登录状态
  Future<void> _handleAutoLoginSwitchChange(bool newValue) async {
    // 如果尝试开启自动登录，但设置不满足条件，显示提示
    if (newValue && !_validateAutoLoginSettings()) {
      _showSnackBar('自动登录需要填写完整的服务器信息并启用所有记住功能');
      return;
    }

    await _dataManager.setAutoLogin(newValue);
    setState(() {});
  }

  /// 验证自动登录设置是否有效
  /// 自动登录需要：所有记住功能都启用，且对应的输入框都有内容
  bool _validateAutoLoginSettings() {
    if (!_dataManager.rememberAddress || 
        !_dataManager.rememberAccount || 
        !_dataManager.rememberPassword) {
      return false;
    }

    final hasAddress = _addressController.text.trim().isNotEmpty;
    final hasUsername = _usernameController.text.trim().isNotEmpty;
    final hasPassword = _passwordController.text.trim().isNotEmpty;
    
    return hasAddress && hasUsername && hasPassword;
  }

  /// 清空所有记录
  Future<void> _clearAllRecords() async {
    // 清空输入框
    _addressController.clear();
    _usernameController.clear();
    _passwordController.clear();

    // 关闭自动登录（因为信息已被清空）
    await _dataManager.setAutoLogin(false);

    setState(() {});
    _showSnackBar('记录已清空');
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
              onPressed: _isSaveButtonEnabled ? _saveSettings : null,
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
                            onChanged: (value) => _handleRememberSwitchChange('address', value),
                          ),
                          _buildSwitchItem(
                            title: '记住Openlist账号',
                            subtitle: '自动保存上次使用的用户名',
                            value: _dataManager.rememberAccount,
                            onChanged: (value) => _handleRememberSwitchChange('account', value),
                          ),
                          _buildSwitchItem(
                            title: '记住Openlist密码',
                            subtitle: '自动保存密码用于快速登录',
                            value: _dataManager.rememberPassword,
                            onChanged: (value) => _handleRememberSwitchChange('password', value),
                          ),
                          _buildSwitchItem(
                            title: '自动登录',
                            subtitle: '应用启动时自动尝试登录',
                            value: _dataManager.autoLogin,
                            onChanged: _isAutoLoginDisabled ? null : _handleAutoLoginSwitchChange,
                            // 当所有记住功能都关闭时，禁用自动登录开关
                            enabled: !_isAutoLoginDisabled,
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
                              // 输入内容变化时更新UI状态
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
                              // 输入内容变化时更新UI状态
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
                              // 输入内容变化时更新UI状态
                              setState(() {});
                            },
                          ),
                          // 自动登录验证提示
                          if (_dataManager.autoLogin && !_validateAutoLoginSettings())
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '自动登录需要填写完整的服务器信息并启用所有记住功能',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          // 保存设置验证提示
                          if (!_isSaveButtonEnabled)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getSaveButtonDisabledReason(),
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
                          onPressed: _clearAllRecords,
                          child: const Text('清空记录'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaveButtonEnabled ? _saveSettings : null,
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

  /// 获取保存按钮禁用原因的描述
  String _getSaveButtonDisabledReason() {
    if (_dataManager.autoLogin) {
      // 自动登录开启时，需要所有信息完整
      if (_addressController.text.trim().isEmpty) return '自动登录需要填写服务器地址';
      if (_usernameController.text.trim().isEmpty) return '自动登录需要填写用户名';
      if (_passwordController.text.trim().isEmpty) return '自动登录需要填写密码';
    }

    // 检查各个记住功能的输入是否完整
    if (_dataManager.rememberAddress && _addressController.text.trim().isEmpty) {
      return '启用"记住地址"时需要填写服务器地址';
    }
    if (_dataManager.rememberAccount && _usernameController.text.trim().isEmpty) {
      return '启用"记住账号"时需要填写用户名';
    }
    if (_dataManager.rememberPassword && _passwordController.text.trim().isEmpty) {
      return '启用"记住密码"时需要填写密码';
    }

    return '请完善设置信息';
  }

  /// 构建开关选项
  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
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
            onChanged: enabled ? onChanged : null,
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
            prefixIcon: Icon(
              icon,
            ),
            border: const OutlineInputBorder(),
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