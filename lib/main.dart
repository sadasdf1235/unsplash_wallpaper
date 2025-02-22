/// 壁纸应用程序入口
/// 
/// 功能：
/// 1. 应用程序初始化
/// 2. 主题管理（明暗主题切换）
/// 3. 语言管理（中英文切换）
/// 4. 路由管理
/// 5. 国际化配置
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'pages/welcome_page.dart';
import 'pages/home_page.dart';
import 'pages/photo_detail_page.dart';
import 'services/unsplash_service.dart';

/// 应用程序入口函数
void main() {
  runApp(const MyApp());
}

/// 应用程序根组件
/// 
/// 提供全局状态管理：
/// - 主题模式
/// - 语言设置
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  /// 获取应用程序状态
  /// 
  /// 用于在子组件中访问和修改全局状态
  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  State<MyApp> createState() => MyAppState();
}

/// 应用程序状态管理
class MyAppState extends State<MyApp> {
  /// 当前主题模式
  ThemeMode _themeMode = ThemeMode.system;

  /// 当前语言设置
  Locale locale = const Locale('zh', '');

  /// 切换主题模式
  /// 
  /// 在明暗主题之间切换
  void toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
    });
  }

  /// 切换语言
  /// 
  /// 在中英文之间切换
  void toggleLanguage() {
    setState(() {
      if (locale.languageCode == 'zh') {
        locale = const Locale('en', '');
      } else {
        locale = const Locale('zh', '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '壁纸工具',
      debugShowCheckedModeBanner: false,  // 移除调试标签
      theme: AppTheme.lightTheme,         // 亮色主题
      darkTheme: AppTheme.darkTheme,      // 暗色主题
      themeMode: _themeMode,              // 当前主题模式
      
      // 国际化配置
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', ''),  // 中文
        Locale('en', ''),  // 英文
      ],
      locale: locale,      // 当前语言设置

      // 路由配置
      initialRoute: '/welcome',  // 初始路由
      routes: {
        '/welcome': (context) => const WelcomePage(),  // 欢迎页
        '/home': (context) => const HomePage(),        // 首页
      },
      
      // 动态路由生成
      onGenerateRoute: (settings) {
        // 图片详情页路由
        if (settings.name == '/photo_detail') {
          final photo = settings.arguments as UnsplashPhoto;
          return MaterialPageRoute(
            builder: (context) => PhotoDetailPage(photo: photo),
          );
        }
        return null;
      },
      
      // 未知路由处理
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const WelcomePage(),
        );
      },
    );
  }
} 