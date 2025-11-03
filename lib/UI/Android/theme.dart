import 'package:flutter/material.dart';
import '../../services/settings_manager.dart';

/// 颜色选项类 - 包含颜色值和对应的名称
class ColorOption {
  final Color color;
  final String name;
  
  const ColorOption({required this.color, required this.name});
}

/// 应用主题配置类 - 负责提供主题相关的配置和数据
/// 作为设置管理器和UI组件之间的桥梁
class AppTheme {
  // 静态设置管理器实例
  static final SettingsManager _settingsManager = SettingsManager();
  
  /// 预定义颜色选项列表
  /// 提供多种颜色供用户选择作为应用主题色，包含颜色名称
  static List<ColorOption> get predefinedColors => [
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

  /// 获取当前主题模式
  /// 将字符串模式转换为Flutter的ThemeMode枚举
  static ThemeMode get currentThemeMode {
    switch (_settingsManager.themeMode) {
      case 'light':
        return ThemeMode.light; // 亮色模式
      case 'dark':
        return ThemeMode.dark;  // 暗色模式
      case 'system':
      default:
        return ThemeMode.system; // 跟随系统
    }
  }

  /// 获取当前种子颜色
  /// 从设置管理器中获取用户选择的主题色
  static Color get seedColor => _settingsManager.seedColor;

  /// 亮色主题配置
  /// 基于当前种子颜色生成完整的亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // 启用 Material 3 设计
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,     // 使用当前种子颜色
        brightness: Brightness.light, // 亮色亮度
      ),
    );
  }

  /// 暗色主题配置
  /// 基于当前种子颜色生成完整的暗色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true, // 启用 Material 3 设计
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,   // 使用当前种子颜色
        brightness: Brightness.dark, // 暗色亮度
      ),
    );
  }

  /// 添加主题变化监听器
  /// [listener] 当主题改变时要调用的回调函数
  static void addListener(VoidCallback listener) {
    _settingsManager.addListener(listener);
  }

  /// 移除主题变化监听器
  /// [listener] 要移除的回调函数
  static void removeListener(VoidCallback listener) {
    _settingsManager.removeListener(listener);
  }

  /// 获取设置管理器实例（供主题页面使用）
  /// 注意：这打破了封装性，但在简单应用中可以接受
  static SettingsManager get settingsManager => _settingsManager;
}