import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/unsplash_service.dart';
import '../main.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final UnsplashService _unsplashService = UnsplashService();
  UnsplashPhoto? _currentPhoto;
  bool _isLoading = true;
  bool _isLoadingFull = false;
  bool _hasLoadedFull = false;

  @override
  void initState() {
    super.initState();
    _loadRandomPhoto();
  }

  Future<void> _loadRandomPhoto() async {
    setState(() {
      _isLoading = true;
      _isLoadingFull = false;
      _hasLoadedFull = false;
    });

    try {
      final photo = await _unsplashService.getRandomPhoto();
      setState(() {
        _currentPhoto = photo;
        _isLoading = false;
      });
      // 加载完预览图后，开始加载高清图
      _loadFullResolution();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.loadingError(e.toString()))),
        );
      }
    }
  }

  Future<void> _loadFullResolution() async {
    if (_currentPhoto == null || _hasLoadedFull) return;

    setState(() => _isLoadingFull = true);

    try {
      // 预加载高清图
      await precacheImage(
        CachedNetworkImageProvider(_currentPhoto!.welcomeFullUrl),
        context,
      );
      if (mounted) {
        setState(() {
          _isLoadingFull = false;
          _hasLoadedFull = true;
        });
      }
    } catch (e) {
      print('Failed to load full resolution image: $e');
      if (mounted) {
        setState(() => _isLoadingFull = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片
          if (_currentPhoto != null)
            Stack(
              children: [
                // 低分辨率图片
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: CachedNetworkImage(
                    imageUrl: _currentPhoto!.welcomePreviewUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (context, url) => Container(
                      color: isDark ? Colors.grey[900] : Colors.grey[300],
                    ),
                  ),
                ),

                // 高清图片（带渐变过渡）
                if (_hasLoadedFull)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 300),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: CachedNetworkImage(
                        imageUrl: _currentPhoto!.welcomeFullUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (context, url) => Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // 渐变遮罩
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // 内容
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 顶部按钮组
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 语言切换按钮
                    IconButton(
                      icon: Text(
                        MyApp.of(context)?.locale.languageCode == 'zh'
                            ? '中/En'
                            : 'En/中',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        MyApp.of(context)?.toggleLanguage();
                      },
                    ),
                    // 主题切换按钮
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        MyApp.of(context)?.toggleTheme();
                      },
                    ),
                  ],
                ),

                // 底部内容
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      if (_currentPhoto != null) ...[
                        Text(
                          l10n.photographer(_currentPhoto!.photographerName),
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 20),
                      ],
                      // 刷新按钮
                      Material(
                        color: Colors.transparent,
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3), // 更精确的透明度控制
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _isLoading ? null : _loadRandomPhoto,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // 开始探索按钮
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.0,
                            vertical: 16.0,
                          ),
                        ),
                        child: Text(l10n.startExplore),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 加载指示器
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

          // 高清图加载指示器
          if (_isLoadingFull)
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
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
                    Text(
                      'HD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
