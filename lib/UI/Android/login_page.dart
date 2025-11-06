
import 'package:flutter/material.dart';
import '../../services/openlist_service.dart';
import '../../services/data_manager.dart'; // 导入 DataManager

/// 登录页面组件
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

/// 登录页面状态类
class _LoginPageState extends State<LoginPage> {
  final OpenlistService _openlistService = OpenlistService(); // Openlist服务实例
  final DataManager _dataManager = DataManager(); // 数据管理器实例
  bool _isLoggingIn = false; // 登录状态标识，防止重复点击
  bool _showQuickLoginButton = false; // 是否显示一键登录按钮
  bool _isAutoLoginAttempted = false; // 是否已尝试自动登录

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  /// 初始化页面
  Future<void> _initializePage() async {
    await _dataManager.init();
    
    // 如果启用了记住地址，自动填充地址
    if (_dataManager.rememberAddress && _dataManager.serverAddress.isNotEmpty) {
      widget.addressController.text = _dataManager.serverAddress;
    }

    // 检查是否显示一键登录按钮
    _updateQuickLoginButtonVisibility();

    // 尝试自动登录
    if (!_isAutoLoginAttempted && _dataManager.canAutoLogin) {
      _isAutoLoginAttempted = true;
      await _performAutoLogin();
    }
  }

  /// 更新一键登录按钮的可见性
  void _updateQuickLoginButtonVisibility() {
    final hasAddress = widget.addressController.text.isNotEmpty;
    final canUseQuickLogin = _dataManager.canUseQuickLogin;
    
    setState(() {
      // 如果启用了记住地址，直接检查是否有足够信息
      // 如果没有启用记住地址，需要用户先输入地址
      _showQuickLoginButton = _dataManager.rememberAddress 
          ? canUseQuickLogin
          : (hasAddress && canUseQuickLogin);
    });
  }

  /// 执行自动登录
  Future<void> _performAutoLogin() async {
    if (!_dataManager.canAutoLogin) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final password = await _dataManager.getPasswordFromSecureStorage();
      
      final result = await _openlistService.login(
        address: _dataManager.serverAddress,
        username: _dataManager.username,
        password: password,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // 登录成功，更新认证状态
        widget.onAuthStatusChanged(result['token'], _dataManager.username, true);
        _showSnackBar('自动登录成功');
      } else {
        // 自动登录失败，显示提示并填充信息
        _showAutoLoginFailedDialog();
      }
    } catch (e) {
      if (!mounted) return;
      _showAutoLoginFailedDialog();
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  /// 显示自动登录失败对话框
  void _showAutoLoginFailedDialog() {
    _showSnackBar('自动登录失败，请检查网络连接或手动登录');
    
    // 填充自动登录信息到输入框
    if (_dataManager.rememberAddress) {
      widget.addressController.text = _dataManager.serverAddress;
    }
    
    // 注意：这里我们不自动填充密码，因为密码是加密存储的
    // 用户需要手动输入密码
    
    _updateQuickLoginButtonVisibility();
  }

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

  /// 构建地址输入字段
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
          onChanged: (value) {
            // 地址改变时更新一键登录按钮的可见性
            _updateQuickLoginButtonVisibility();
          },
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

  /// 构建账户设置区域
  Widget _buildAccountSettings() {
    return Column(
      children: [
        // 一键登录按钮（条件显示）
        if (_showQuickLoginButton && !widget.isLoggedIn) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoggingIn ? null : _handleQuickLogin,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoggingIn
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('登录中...'),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quickreply),
                        SizedBox(width: 8),
                        Text('使用保存的信息登录'),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
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
              onPressed: _isLoggingIn ? null : _showLoginDialog,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoggingIn
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('登录中...'),
                      ],
                    )
                  : const Row(
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

  /// 处理一键登录
  Future<void> _handleQuickLogin() async {
    final hasAddress = _dataManager.rememberAddress && _dataManager.serverAddress.isNotEmpty;
    final hasAccount = _dataManager.rememberAccount && _dataManager.username.isNotEmpty;
    final hasPassword = _dataManager.rememberPassword;

    // 检查是否有足够的信息进行一键登录
    if (!hasAddress || (!hasAccount && !hasPassword)) {
      _showSnackBar('没有足够的信息进行一键登录');
      return;
    }

    // 如果三项都启用，直接尝试登录
    if (hasAddress && hasAccount && hasPassword) {
      await _performQuickLogin();
    } else {
      // 否则显示登录对话框并自动填充信息
      await _showLoginDialogWithPrefilledInfo();
    }
  }

  /// 执行一键登录
  Future<void> _performQuickLogin() async {
    setState(() {
      _isLoggingIn = true;
    });

    try {
      final password = await _dataManager.getPasswordFromSecureStorage();
      
      final result = await _openlistService.login(
        address: _dataManager.serverAddress,
        username: _dataManager.username,
        password: password,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // 登录成功，更新认证状态
        widget.onAuthStatusChanged(result['token'], _dataManager.username, true);
        _showSnackBar('一键登录成功');
      } else {
        _showSnackBar(result['message']);
      }
    } catch (e) {
      _showSnackBar('一键登录失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  /// 显示带预填充信息的登录对话框
  Future<void> _showLoginDialogWithPrefilledInfo() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController otpController = TextEditingController();

    // 预填充信息
    if (_dataManager.rememberAddress) {
      widget.addressController.text = _dataManager.serverAddress;
    }
    if (_dataManager.rememberAccount) {
      usernameController.text = _dataManager.username;
    }
    if (_dataManager.rememberPassword) {
      final password = await _dataManager.getPasswordFromSecureStorage();
      passwordController.text = password;
    }

    await _showLoginDialogInternal(
      usernameController: usernameController,
      passwordController: passwordController,
      otpController: otpController,
    );
  }

  /// 显示登录对话框
  Future<void> _showLoginDialog() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController otpController = TextEditingController();

    // 如果启用了记住账号，预填充用户名
    if (_dataManager.rememberAccount && _dataManager.username.isNotEmpty) {
      usernameController.text = _dataManager.username;
    }

    await _showLoginDialogInternal(
      usernameController: usernameController,
      passwordController: passwordController,
      otpController: otpController,
    );
  }

  /// 内部登录对话框实现
  Future<void> _showLoginDialogInternal({
    required TextEditingController usernameController,
    required TextEditingController passwordController,
    required TextEditingController otpController,
  }) async {
    bool isDialogOpen = true;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void safeSetDialogState(void Function() fn) {
              if (isDialogOpen && mounted) {
                setDialogState(fn);
              }
            }

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
                    const SizedBox(height: 16),
                    if (_isLoggingIn) // 登录中显示进度指示器
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isDialogOpen = false;
                    Navigator.of(context).pop();
                  },
                  child: const Text('关闭'),
                ),
                FilledButton(
                  onPressed: _isLoggingIn
                      ? null // 登录中禁用登录按钮
                      : () async {
                          safeSetDialogState(() {
                            _isLoggingIn = true; // 开始登录
                          });

                          await _performLogin(
                            usernameController.text.trim(),
                            passwordController.text.trim(),
                            otpController.text.trim(),
                            safeSetDialogState,
                          );
                          
                          // 只有在对话框仍然显示时才关闭
                          if (isDialogOpen && mounted && Navigator.of(context).canPop()) {
                            isDialogOpen = false; // 标记对话框已关闭
                            Navigator.of(context).pop();
                          }
                        },
                  child: const Text('登录'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // 对话框关闭后的回调
      isDialogOpen = false;
      _isLoggingIn = false; // 确保重置登录状态
    });
  }

  /// 执行登录操作
  Future<void> _performLogin(
    String username,
    String password,
    String otpCode,
    void Function(void Function()) safeSetDialogState,
  ) async {
    final address = widget.addressController.text.trim();

    if (address.isEmpty) {
      _showSnackBar('请先输入Openlist地址');
      safeSetDialogState(() {
        _isLoggingIn = false; // 重置登录状态
      });
      return;
    }

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('请输入用户名和密码');
      safeSetDialogState(() {
        _isLoggingIn = false; // 重置登录状态
      });
      return;
    }

    try {
      // 使用OpenlistService进行登录
      final result = await _openlistService.login(
        address: address,
        username: username,
        password: password,
        otpCode: otpCode,
      );

      if (!mounted) {
        safeSetDialogState(() {
          _isLoggingIn = false; // 重置登录状态
        });
        return;
      }

      if (result['success'] == true) {
        // 登录成功，更新认证状态
        widget.onAuthStatusChanged(result['token'], username, true);
        
        // 保存用户数据（根据设置）
        if (_dataManager.rememberAddress) {
          await _dataManager.setServerAddress(address);
        }
        if (_dataManager.rememberAccount) {
          await _dataManager.setUsername(username);
        }
        if (_dataManager.rememberPassword) {
          await _dataManager.setPassword(password);
        }
        
        _showSnackBar('登录成功');
        
        // 更新一键登录按钮状态
        _updateQuickLoginButtonVisibility();
      } else {
        _showSnackBar(result['message']);
      }
    } catch (e) {
      // 处理网络错误和其他异常
      if (!mounted) {
        safeSetDialogState(() {
          _isLoggingIn = false; // 重置登录状态
        });
        return;
      }

      String errorMessage = '登录出错: $e';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage = '无法连接到服务器，请检查地址和网络连接';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = '连接超时，请检查网络连接或服务器状态';
      }

      _showSnackBar(errorMessage);
    } finally {
      // 确保重置登录状态
      if (mounted) {
        safeSetDialogState(() {
          _isLoggingIn = false; // 重置登录状态
        });
      }
    }
  }

  /// 显示提示消息
  void _showSnackBar(String message) {
    if (!mounted) return;
    
    // 使用 ScaffoldMessenger 显示 SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4), // 延长显示时间以便用户阅读
        behavior: SnackBarBehavior.floating, // 浮动样式
        action: SnackBarAction(
          label: '关闭',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 清理资源
    _isLoggingIn = false;
    super.dispose();
  }
}