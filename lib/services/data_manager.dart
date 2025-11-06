import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 数据管理器类 - 负责管理用户数据和设置
class DataManager with ChangeNotifier {
  // 存储键名常量
  static const String _rememberAddressKey = 'remember_address';
  static const String _rememberAccountKey = 'remember_account'; 
  static const String _rememberPasswordKey = 'remember_password';
  static const String _autoLoginKey = 'auto_login';
  static const String _serverAddressKey = 'server_address';
  static const String _usernameKey = 'username';
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

  // 安全存储用于加密密钥
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _encryptionKeyKey = 'encryption_key';
  
  // 内部状态
  bool _rememberAddress = _defaultRememberAddress;
  bool _rememberAccount = _defaultRememberAccount;
  bool _rememberPassword = _defaultRememberPassword;
  bool _autoLogin = _defaultAutoLogin;
  String _serverAddress = '';
  String _username = '';
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
    
    // 加载上次同步路径
    _lastSyncPath = prefs.getString(_lastSyncPathKey) ?? '';
    
    // 如果启用了记住密码，从安全存储加载加密的密码
    if (_rememberPassword) {
      await _loadEncryptedPassword();
    }
    
    notifyListeners();
  }

  /// 获取加密密钥，如果不存在则生成新的
  Future<encrypt.Key> _getEncryptionKey() async { // 使用前缀
    String? keyString = await _secureStorage.read(key: _encryptionKeyKey);
    
    if (keyString == null) {
      // 生成新的256位密钥
      final key = encrypt.Key.fromSecureRandom(32); // 使用前缀
      keyString = base64.encode(key.bytes);
      await _secureStorage.write(key: _encryptionKeyKey, value: keyString);
      return key;
    }
    
    return encrypt.Key.fromBase64(keyString); // 使用前缀
  }

  /// 加密密码
  Future<String> _encryptPassword(String password) async {
    try {
      final key = await _getEncryptionKey();
      final iv = encrypt.IV.fromLength(16); // 使用前缀
      final encrypter = encrypt.Encrypter(encrypt.AES(key)); // 使用前缀
      final encrypted = encrypter.encrypt(password, iv: iv);
      return encrypted.base64;
    } catch (e) {
      print('密码加密失败: $e');
      return '';
    }
  }

  /// 解密密码
  Future<String> _decryptPassword(String encryptedPassword) async {
    try {
      final key = await _getEncryptionKey();
      final iv = encrypt.IV.fromLength(16); // 使用前缀
      final encrypter = encrypt.Encrypter(encrypt.AES(key)); // 使用前缀
      final decrypted = encrypter.decrypt64(encryptedPassword, iv: iv);
      return decrypted;
    } catch (e) {
      print('密码解密失败: $e');
      return '';
    }
  }

  /// 从安全存储加载加密的密码
  Future<void> _loadEncryptedPassword() async {
    // 密码存储在安全存储中
    // 这里我们只需要验证是否存储了密码，实际解密在需要时进行
  }

  /// 保存密码到安全存储
  Future<void> _savePasswordToSecureStorage(String password) async {
    if (password.isEmpty) {
      await _secureStorage.delete(key: 'encrypted_password');
      return;
    }
    
    try {
      final encryptedPassword = await _encryptPassword(password);
      await _secureStorage.write(key: 'encrypted_password', value: encryptedPassword);
    } catch (e) {
      print('保存密码失败: $e');
    }
  }

  /// 从安全存储获取密码
  Future<String> getPasswordFromSecureStorage() async {
    try {
      final encryptedPassword = await _secureStorage.read(key: 'encrypted_password');
      if (encryptedPassword == null || encryptedPassword.isEmpty) {
        return '';
      }
      return await _decryptPassword(encryptedPassword);
    } catch (e) {
      print('获取密码失败: $e');
      return '';
    }
  }

  // Getters
  bool get rememberAddress => _rememberAddress;
  bool get rememberAccount => _rememberAccount;
  bool get rememberPassword => _rememberPassword;
  bool get autoLogin => _autoLogin;
  String get serverAddress => _serverAddress;
  String get username => _username;
  String get lastSyncPath => _lastSyncPath;

  /// 检查是否可以使用一键登录（有足够的信息）
  bool get canUseQuickLogin {
    bool hasAddress = _rememberAddress && _serverAddress.isNotEmpty;
    bool hasAccount = _rememberAccount && _username.isNotEmpty;
    bool hasPassword = _rememberPassword;
    
    // 至少需要地址和账号密码中的一项
    return hasAddress && (hasAccount || hasPassword);
  }

  /// 检查自动登录是否可用（需要所有信息）
  bool get canAutoLogin {
    return _autoLogin && 
           _serverAddress.isNotEmpty && 
           _username.isNotEmpty && 
           _rememberPassword;
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
      await _savePasswordToSecureStorage('');
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
    if (_rememberPassword && password.isNotEmpty) {
      await _savePasswordToSecureStorage(password);
    } else {
      await _savePasswordToSecureStorage('');
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
    await prefs.remove(_lastSyncPathKey);
    
    // 清除安全存储中的密码
    await _secureStorage.delete(key: 'encrypted_password');
    
    // 重置内存状态
    _rememberAddress = _defaultRememberAddress;
    _rememberAccount = _defaultRememberAccount;
    _rememberPassword = _defaultRememberPassword;
    _autoLogin = _defaultAutoLogin;
    _serverAddress = '';
    _username = '';
    _lastSyncPath = '';
    
    notifyListeners();
  }

  /// 重置为默认设置
  Future<void> resetToDefaults() async {
    await clearAllData();
    await init();
  }
}