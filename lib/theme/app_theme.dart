/// 应用程序主题配置
///
/// 提供：
/// 1. 亮色主题配置
/// 2. 暗色主题配置
/// 3. 主题色定义
/// 4. 组件样式定义
import 'package:flutter/material.dart';

/// 主题配置类
class AppTheme {
  /// 主题色 - iPhone 12 马卡龙绿
  static const Color primaryColor = Color(0xFF90EE90);

  /// 亮色主题配置
  static ThemeData lightTheme = ThemeData(
    // 主色调配置
    primarySwatch: MaterialColor(primaryColor.value, {
      50: primaryColor.withOpacity(0.1),
      100: primaryColor.withOpacity(0.2),
      200: primaryColor.withOpacity(0.3),
      300: primaryColor.withOpacity(0.4),
      400: primaryColor.withOpacity(0.5),
      500: primaryColor.withOpacity(0.6),
      600: primaryColor.withOpacity(0.7),
      700: primaryColor.withOpacity(0.8),
      800: primaryColor.withOpacity(0.9),
      900: primaryColor,
    }),

    // 颜色方案
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: primaryColor,
      surface: Colors.white,
      onPrimary: Colors.black87,
    ),

    // 过滤器芯片主题
    chipTheme: ChipThemeData(
      selectedColor: primaryColor,
      labelStyle: TextStyle(color: Colors.black87),
      secondaryLabelStyle: TextStyle(color: Colors.black87),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      checkmarkColor: Colors.black87,
    ),

    // 进度指示器主题
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
    ),

    // 按钮主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
    ),
  );

  /// 暗色主题配置
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primaryColor,

    // 暗色主题颜色方案
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      surface: Colors.grey.shade900,
      onPrimary: Colors.black87,
    ),

    // 暗色主题过滤器芯片
    chipTheme: ChipThemeData(
      selectedColor: primaryColor,
      labelStyle: TextStyle(color: Colors.white70),
      secondaryLabelStyle: TextStyle(color: Colors.black87),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      checkmarkColor: Colors.white,
      selectedShadowColor: Colors.transparent,
      backgroundColor: Colors.grey.shade800,
      disabledColor: Colors.grey.shade700,
    ),

    // 暗色主题进度指示器
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryColor,
    ),

    // 暗色主题按钮
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
    ),
  );
}
