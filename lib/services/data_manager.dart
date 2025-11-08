import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 数据管理器类 - 负责管理用户数据和设置
class DataManager with ChangeNotifier {
  // 存储键名常量
  static const String _rememberAddressKey = 'remember_address';
  static const String _rememberAccountKey = 'remember_account'; 
  static const String _rememberPasswordKey = 'remember_password';
  static const String _autoLoginKey = 'auto_login';
  static const String _serverAddressKey = 'server_address';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password'; // 使用 base64 编码存储
  static const String _lastSyncPathKey = 'last_sync_path';
  
  // 默认值
  static const bool _defaultRememberAddress = true;
  static const bool _defaultRememberAccount = false;
  static const bool _defaultRememberPassword = false;
  static const bool _defaultAutoLogin = false;

  // 单例模式
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  // 内部状态
  bool _rememberAddress = _defaultRememberAddress;
  bool _rememberAccount = _defaultRememberAccount;
  bool _rememberPassword = _defaultRememberPassword;
  bool _autoLogin = _defaultAutoLogin;
  String _serverAddress = '';
  String _username = '';
  String _password = ''; // 明文密码（仅在内存中）
  String _lastSyncPath = '';

  /// 初始化数据管理器
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载设置开关
    _rememberAddress = prefs.getBool(_rememberAddressKey) ?? _defaultRememberAddress;
    _rememberAccount = prefs.getBool(_rememberAccountKey) ?? _defaultRememberAccount;
    _rememberPassword = prefs.getBool(_rememberPasswordKey) ?? _defaultRememberPassword;
    _autoLogin = prefs.getBool(_autoLoginKey) ?? _defaultAutoLogin;
    
    // 加载服务器地址
    _serverAddress = prefs.getString(_serverAddressKey) ?? '';
    
    // 加载用户名
    _username = prefs.getString(_usernameKey) ?? '';
    
    // 加载密码（base64 解码）
    final encodedPassword = prefs.getString(_passwordKey) ?? '';
    if (encodedPassword.isNotEmpty) {
      try {
        _password = _decodePassword(encodedPassword);
      } catch (e) {
        print('密码解码失败: $e');
        // 解码失败时清除密码
        await prefs.remove(_passwordKey);
        _password = '';
      }
    }
    
    // 加载上次同步路径
    _lastSyncPath = prefs.getString(_lastSyncPathKey) ?? '';
    
    notifyListeners();
  }

  /// 使用 base64 编码密码
  String _encodePassword(String password) {
    try {
      final bytes = utf8.encode(password);
      return base64.encode(bytes);
    } catch (e) {
      print('密码编码失败: $e');
      return '';
    }
  }

  /// 使用 base64 解码密码
  String _decodePassword(String encodedPassword) {
    try {
      final bytes = base64.decode(encodedPassword);
      return utf8.decode(bytes);
    } catch (e) {
      print('密码解码失败: $e');
      throw Exception('密码解码失败: $e');
    }
  }

  // Getters
  bool get rememberAddress => _rememberAddress;
  bool get rememberAccount => _rememberAccount;
  bool get rememberPassword => _rememberPassword;
  bool get autoLogin => _autoLogin;
  String get serverAddress => _serverAddress;
  String get username => _username;
  String get password => _password; // 返回内存中的密码
  String get lastSyncPath => _lastSyncPath;

  /// 检查是否可以使用一键登录（有足够的信息）
  bool get canUseQuickLogin {
    bool hasAddress = _rememberAddress && _serverAddress.isNotEmpty;
    bool hasAccount = _rememberAccount && _username.isNotEmpty;
    bool hasPassword = _rememberPassword && _password.isNotEmpty;
    
    // 至少需要地址和账号密码中的一项
    return hasAddress && (hasAccount || hasPassword);
  }

  /// 检查自动登录是否可用（需要所有信息）
  bool get canAutoLogin {
    return _autoLogin && 
           _serverAddress.isNotEmpty && 
           _username.isNotEmpty && 
           _rememberPassword &&
           _password.isNotEmpty;
  }

  /// 设置记住地址开关
  Future<void> setRememberAddress(bool value) async {
    _rememberAddress = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberAddressKey, value);
    
    // 如果关闭记住地址，清除地址
    if (!value) {
      await setServerAddress('');
    }
    
    notifyListeners();
  }

  /// 设置记住账号开关
  Future<void> setRememberAccount(bool value) async {
    _rememberAccount = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberAccountKey, value);
    
    // 如果关闭记住账号，清除用户名
    if (!value) {
      await setUsername('');
    }
    
    notifyListeners();
  }

  /// 设置记住密码开关
  Future<void> setRememberPassword(bool value) async {
    _rememberPassword = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberPasswordKey, value);
    
    // 如果关闭记住密码，清除密码
    if (!value) {
      await setPassword('');
    }
    
    notifyListeners();
  }

  /// 设置自动登录开关
  Future<void> setAutoLogin(bool value) async {
    _autoLogin = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLoginKey, value);
    notifyListeners();
  }

  /// 设置服务器地址
  Future<void> setServerAddress(String address) async {
    _serverAddress = address;
    final prefs = await SharedPreferences.getInstance();
    if (_rememberAddress && address.isNotEmpty) {
      await prefs.setString(_serverAddressKey, address);
    } else {
      await prefs.remove(_serverAddressKey);
    }
    notifyListeners();
  }

  /// 设置用户名
  Future<void> setUsername(String username) async {
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    if (_rememberAccount && username.isNotEmpty) {
      await prefs.setString(_usernameKey, username);
    } else {
      await prefs.remove(_usernameKey);
    }
    notifyListeners();
  }

  /// 设置密码
  Future<void> setPassword(String password) async {
    _password = password;
    final prefs = await SharedPreferences.getInstance();
    if (_rememberPassword && password.isNotEmpty) {
      final encodedPassword = _encodePassword(password);
      await prefs.setString(_passwordKey, encodedPassword);
    } else {
      await prefs.remove(_passwordKey);
      _password = '';
    }
    notifyListeners();
  }

  /// 设置上次同步路径
  Future<void> setLastSyncPath(String path) async {
    _lastSyncPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path.isNotEmpty) {
      await prefs.setString(_lastSyncPathKey, path);
    } else {
      await prefs.remove(_lastSyncPathKey);
    }
    notifyListeners();
  }

  /// 检查密码是否可解码
  Future<bool> checkPasswordDecodable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedPassword = prefs.getString(_passwordKey) ?? '';
      if (encodedPassword.isEmpty) {
        return true; // 没有存储密码，视为可解码
      }
      
      _decodePassword(encodedPassword);
      return true;
    } catch (e) {
      print('密码解码检查失败: $e');
      return false;
    }
  }

  /// 清除所有用户数据
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 清除设置
    await prefs.remove(_rememberAddressKey);
    await prefs.remove(_rememberAccountKey);
    await prefs.remove(_rememberPasswordKey);
    await prefs.remove(_autoLoginKey);
    
    // 清除用户数据
    await prefs.remove(_serverAddressKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_lastSyncPathKey);
    
    // 重置内存状态
    _rememberAddress = _defaultRememberAddress;
    _rememberAccount = _defaultRememberAccount;
    _rememberPassword = _defaultRememberPassword;
    _autoLogin = _defaultAutoLogin;
    _serverAddress = '';
    _username = '';
    _password = '';
    _lastSyncPath = '';
    
    notifyListeners();
  }

  /// 重置为默认设置
  Future<void> resetToDefaults() async {
    await clearAllData();
    await init();
  }
}