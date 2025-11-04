import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_manager.dart';

/// 设置管理器类 - 负责管理应用的设置和持久化存储
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

  // 主题管理器实例
  final ThemeManager _themeManager = ThemeManager();

  /// 初始化设置 - 从持久化存储中加载设置
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString(_themeModeKey) ?? 'system'; // 默认跟随系统
    final seedColor = prefs.getInt(_seedColorKey) ?? 0xFF2196F3;  // 默认蓝色
    
    // 验证颜色值是否有效，如果无效则使用默认值
    if (!_themeManager.isValidColorValue(seedColor)) {
      final defaultColor = _themeManager.getDefaultColorOption().color.value;
      await prefs.setInt(_seedColorKey, defaultColor); // 保存修正后的颜色值
    }

    // 设置主题管理器状态
    await _themeManager.setThemeMode(themeMode);
    await _themeManager.setSeedColor(Color(seedColor));
    
    // 监听主题管理器变化
    _themeManager.addListener(() {
      notifyListeners(); // 当主题改变时通知设置管理器的监听者
      _saveSettings(); // 保存设置到持久化存储
    });
    
    notifyListeners(); // 通知所有监听者设置已加载
  }

  /// 获取当前主题模式
  String get themeMode => _themeManager.themeMode;
  
  /// 获取当前种子颜色
  Color get seedColor => _themeManager.seedColor;

  /// 获取主题管理器实例
  ThemeManager get themeManager => _themeManager;

  /// 设置主题模式
  /// [mode] 主题模式，可选值：'system', 'light', 'dark'
  Future<void> setThemeMode(String mode) async {
    await _themeManager.setThemeMode(mode);
  }

  /// 设置种子颜色
  /// [color] 新的种子颜色
  Future<void> setSeedColor(Color color) async {
    await _themeManager.setSeedColor(color);
  }

  /// 获取当前主题配置
  /// 返回：包含当前主题模式和种子颜色的配置对象
  Map<String, dynamic> getCurrentThemeConfig() {
    return {
      'themeMode': themeMode,
      'seedColor': seedColor.value,
      'themeModeEnum': _themeManager.getThemeModeFromString(themeMode),
    };
  }

  /// 生成当前的主题数据
  /// [isLight] 是否为亮色主题，如果为null则根据当前主题模式决定
  /// 返回：配置好的ThemeData
  ThemeData generateThemeData({bool? isLight}) {
    final bool useLightTheme;
    
    if (isLight != null) {
      useLightTheme = isLight;
    } else {
      final currentThemeMode = _themeManager.getThemeModeFromString(themeMode);
      if (currentThemeMode == ThemeMode.system) {
        // 在实际使用中，这里应该根据系统主题决定
        // 为简单起见，我们默认使用亮色
        useLightTheme = true;
      } else {
        useLightTheme = currentThemeMode == ThemeMode.light;
      }
    }
    
    if (useLightTheme) {
      return _themeManager.generateLightTheme(seedColor);
    } else {
      return _themeManager.generateDarkTheme(seedColor);
    }
  }

  /// 保存设置到持久化存储
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode);
    await prefs.setInt(_seedColorKey, seedColor.value);
  }

  /// 重置所有设置为默认值
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeModeKey); // 移除主题模式设置
    await prefs.remove(_seedColorKey); // 移除颜色设置
    await init(); // 重新初始化（会加载默认值）
  }
}