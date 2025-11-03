import 'package:flutter/material.dart';
import '../theme.dart' as app_theme; // 导入主题配置，使用别名避免命名冲突

/// 主题设置页面 - 允许用户自定义应用的主题和颜色
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

/// 主题设置页面的状态类
class _ThemePageState extends State<ThemePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 明暗设置项标题
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                '明暗设置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            
            // 明暗设置卡片
            Card(
              child: Column(
                children: [
                  _buildThemeModeItem(
                    icon: Icons.brightness_auto,
                    title: '跟随系统',
                    value: 'system',
                  ),
                  const Divider(height: 1), // 分隔线
                  _buildThemeModeItem(
                    icon: Icons.light_mode,
                    title: '浅色模式',
                    value: 'light',
                  ),
                  const Divider(height: 1), // 分隔线
                  _buildThemeModeItem(
                    icon: Icons.dark_mode,
                    title: '深色模式',
                    value: 'dark',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24), // 间距
            
            // 颜色设置项标题
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                '主题颜色',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            
            // 颜色选择卡片 - 宽度与明暗设置卡片一致
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildColorGrid(),
              ),
            ),
          ],
        )
      ),
    );
  }

  /// 构建颜色选项网格布局
  /// 使用GridView实现等距排布和两端对齐
  Widget _buildColorGrid() {
    // 计算每行显示的颜色数量
    const double colorItemWidth = 70.0; // 每个颜色选项的宽度
    const double horizontalSpacing = 16.0; // 水平间距
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算每行可以容纳的颜色数量
        final availableWidth = constraints.maxWidth;
        final itemsPerRow = ((availableWidth + horizontalSpacing) / 
                            (colorItemWidth + horizontalSpacing)).floor();
        
        return GridView.builder(
          shrinkWrap: true, // 重要：确保GridView在Column中正确显示
          physics: const NeverScrollableScrollPhysics(), // 禁用GridView自身的滚动
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: itemsPerRow, // 动态计算每行数量
            crossAxisSpacing: horizontalSpacing, // 水平间距
            mainAxisSpacing: 16, // 垂直间距
            childAspectRatio: 0.7, // 宽高比，确保布局美观
          ),
          itemCount: app_theme.AppTheme.predefinedColors.length,
          itemBuilder: (context, index) {
            final colorOption = app_theme.AppTheme.predefinedColors[index];
            return _buildColorOption(colorOption);
          },
        );
      },
    );
  }

  /// 构建主题模式选项项
  /// [icon] 选项图标
  /// [title] 选项标题
  /// [value] 选项对应的主题模式值
  Widget _buildThemeModeItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    // 检查当前选项是否被选中
    final isSelected = app_theme.AppTheme.settingsManager.themeMode == value;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? Theme.of(context).colorScheme.primary  // 选中时使用主题色
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // 未选中时半透明
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary  // 选中时使用主题色
              : Theme.of(context).colorScheme.onSurface, // 未选中时使用表面文本色
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // 选中时加粗
        ),
      ),
      trailing: isSelected 
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary, // 选中标记使用主题色
            )
          : null,
      onTap: () {
        // 点击时更新主题模式
        app_theme.AppTheme.settingsManager.setThemeMode(value);
      },
    );
  }

  /// 构建颜色选项
  /// [colorOption] 颜色选项对象，包含颜色和名称
  Widget _buildColorOption(app_theme.ColorOption colorOption) {
    // 检查当前颜色是否被选中
    final isSelected = colorOption.color.value == app_theme.AppTheme.seedColor.value;
    
    return GestureDetector(
      onTap: () {
        // 点击时更新种子颜色
        app_theme.AppTheme.settingsManager.setSeedColor(colorOption.color);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 颜色圆圈
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorOption.color, // 显示颜色
              shape: BoxShape.circle, // 圆形
              border: isSelected
                  ? Border.all(
                      color: _getContrastColor(colorOption.color), // 使用对比色作为边框
                      width: 3, // 边框宽度
                    )
                  : Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      width: 1,
                    ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: colorOption.color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    // 根据颜色亮度选择对勾图标的颜色，确保可见性
                    color: _getContrastColor(colorOption.color),
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(height: 8), // 颜色和名称之间的间距
          // 颜色名称
          Text(
            colorOption.name,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 获取与给定颜色形成对比的颜色（黑色或白色）
  /// [backgroundColor] 背景颜色
  /// 返回：如果背景色较亮则返回黑色，否则返回白色
  Color _getContrastColor(Color backgroundColor) {
    // 计算颜色的相对亮度（0-1之间）
    final luminance = backgroundColor.computeLuminance();
    
    // 如果亮度大于0.5，使用黑色；否则使用白色
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}