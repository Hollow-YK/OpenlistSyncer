import 'package:flutter/material.dart';

/// 颜色选项类 - 包含颜色值和对应的名称
class ColorOption {
  final Color color;
  final String name;
  
  const ColorOption({required this.color, required this.name});
}

/// 主题管理器类 - 负责管理应用主题相关的数据和配置
class ThemeManager with ChangeNotifier {
  // 私有构造函数
  ThemeManager._internal();
  
  // 单例实例
  static final ThemeManager _instance = ThemeManager._internal();
  
  /// 获取主题管理器单例
  factory ThemeManager() => _instance;
  
  /// 预定义颜色选项列表 - 改为实例成员
  /// 提供多种颜色供用户选择作为应用主题色，包含颜色名称
  final List<ColorOption> predefinedColors = [
    const ColorOption(color: Color(0xFF2196F3), name: '默认蓝'),      // Material Blue
    const ColorOption(color: Color(0xFF4CAF50), name: '默认绿'),      // Material Green
    const ColorOption(color: Color(0xFFF44336), name: '默认红'),      // Material Red
    const ColorOption(color: Color(0xFFFF9800), name: '默认橙'),      // Material Orange
    const ColorOption(color: Color(0xFF66CCFF), name: '天依蓝'),
    const ColorOption(color: Color(0xFF39C5BB), name: '葱绿色'),
    const ColorOption(color: Color(0xFFEE0000), name: '阿绫红'),
    const ColorOption(color: Color(0xFF9C27B0), name: '紫色'),        // Material Purple
    const ColorOption(color: Color(0xFF607D8B), name: '蓝灰色'),      // Blue Grey
    const ColorOption(color: Color(0xFF795548), name: '棕色'),        // Brown
    const ColorOption(color: Color(0xFFE91E63), name: '粉红色'),      // Pink
    const ColorOption(color: Color(0xFF00BCD4), name: '青色'),        // Cyan
    const ColorOption(color: Color(0xFF8BC34A), name: '浅绿色'),      // Light Green
    const ColorOption(color: Color(0xFFFFC107), name: '琥珀色'),      // Amber
    const ColorOption(color: Color(0xFF673AB7), name: '深紫色'),      // Deep Purple
  ];

  // 内部状态变量
  String _themeMode = 'system';  // 当前主题模式：system, light, dark
  int _seedColor = 0xFF2196F3;   // 当前种子颜色值（ARGB格式）

  /// 获取当前主题模式
  String get themeMode => _themeMode;
  
  /// 获取当前种子颜色
  Color get seedColor => Color(_seedColor);

  /// 设置主题模式
  /// [mode] 主题模式，可选值：'system', 'light', 'dark'
  Future<void> setThemeMode(String mode) async {
    if (mode != 'system' && mode != 'light' && mode != 'dark') {
      throw ArgumentError('主题模式必须是 system、light 或 dark');
    }
    
    _themeMode = mode; // 更新内存中的主题模式
    notifyListeners(); // 通知所有监听者主题已改变
  }

  /// 设置种子颜色
  /// [color] 新的种子颜色
  Future<void> setSeedColor(Color color) async {
    _seedColor = color.value; // 更新内存中的颜色值
    notifyListeners(); // 通知所有监听者颜色已改变
  }

  /// 根据主题模式字符串获取对应的ThemeMode枚举
  /// [themeMode] 主题模式字符串，可选值：'system', 'light', 'dark'
  /// 返回：对应的ThemeMode枚举值
  ThemeMode getThemeModeFromString(String themeMode) {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// 根据ThemeMode枚举获取对应的字符串表示
  /// [themeMode] ThemeMode枚举值
  /// 返回：对应的主题模式字符串
  String getStringFromThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }

  /// 生成亮色主题配置
  /// [seedColor] 种子颜色，用于生成完整的颜色方案
  /// 返回：配置好的亮色ThemeData
  ThemeData generateLightTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true, // 启用 Material 3 设计
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,     // 使用种子颜色
        brightness: Brightness.light, // 亮色亮度
      ),
    );
  }

  /// 生成暗色主题配置
  /// [seedColor] 种子颜色，用于生成完整的颜色方案
  /// 返回：配置好的暗色ThemeData
  ThemeData generateDarkTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true, // 启用 Material 3 设计
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,   // 使用种子颜色
        brightness: Brightness.dark, // 暗色亮度
      ),
    );
  }

  /// 获取所有可用的主题模式选项
  /// 返回：包含主题模式显示名称和对应值的列表
  List<Map<String, String>> getThemeModeOptions() {
    return [
      {'value': 'system', 'name': '跟随系统', 'icon': 'brightness_auto'},
      {'value': 'light', 'name': '浅色模式', 'icon': 'light_mode'},
      {'value': 'dark', 'name': '深色模式', 'icon': 'dark_mode'},
    ];
  }

  /// 根据颜色值查找颜色选项
  /// [colorValue] 要查找的颜色值
  /// 返回：对应的ColorOption，如果未找到则返回null
  ColorOption? findColorOptionByValue(int colorValue) {
    try {
      return predefinedColors.firstWhere(
        (colorOption) => colorOption.color.value == colorValue,
      );
    } catch (e) {
      return null; // 未找到对应的颜色选项
    }
  }

  /// 验证颜色值是否在预定义颜色列表中
  /// [colorValue] 要验证的颜色值
  /// 返回：如果颜色值有效则返回true，否则返回false
  bool isValidColorValue(int colorValue) {
    return findColorOptionByValue(colorValue) != null;
  }

  /// 获取默认的颜色选项
  /// 返回：默认的ColorOption（默认蓝）
  ColorOption getDefaultColorOption() {
    return predefinedColors.first;
  }
}