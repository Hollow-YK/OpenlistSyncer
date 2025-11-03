import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // 需要导入 Material 包来使用 Color
import 'package:shared_preferences/shared_preferences.dart';

/// 设置管理器类 - 负责管理应用的设置和主题配置
/// 使用 ChangeNotifier 实现观察者模式，当设置改变时通知监听者
class SettingsManager with ChangeNotifier {
  // 存储键名常量
  static const String _themeModeKey = 'theme_mode'; // 主题模式存储键
  static const String _seedColorKey = 'seed_color';  // 种子颜色存储键

  // 单例模式实现 - 确保全局只有一个设置管理器实例
  static final SettingsManager _instance = SettingsManager._internal();
  
  /// 工厂构造函数，返回单例实例
  factory SettingsManager() => _instance;
  
  /// 私有内部构造函数
  SettingsManager._internal();

  // 内部状态变量
  String _themeMode = 'system';  // 当前主题模式：system, light, dark
  int _seedColor = 0xFF2196F3;   // 当前种子颜色值（ARGB格式）

  /// 获取当前主题模式
  String get themeMode => _themeMode;
  
  /// 获取当前种子颜色
  Color get seedColor => Color(_seedColor);

  /// 初始化设置 - 从持久化存储中加载设置
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getString(_themeModeKey) ?? 'system'; // 默认跟随系统
    _seedColor = prefs.getInt(_seedColorKey) ?? 0xFF2196F3;  // 默认蓝色
    notifyListeners(); // 通知所有监听者设置已加载
  }

  /// 设置主题模式
  /// [mode] 主题模式，可选值：'system', 'light', 'dark'
  Future<void> setThemeMode(String mode) async {
    _themeMode = mode; // 更新内存中的主题模式
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode); // 持久化到存储
    notifyListeners(); // 通知所有监听者主题已改变
  }

  /// 设置种子颜色
  /// [color] 新的种子颜色
  Future<void> setSeedColor(Color color) async {
    _seedColor = color.value; // 更新内存中的颜色值
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.value); // 持久化到存储
    notifyListeners(); // 通知所有监听者颜色已改变
  }
}