/// 图片详情页
/// 
/// 功能：
/// 1. 显示高清大图，支持缩放和旋转
/// 2. 渐进式加载（先显示低分辨率图片，再加载高清图）
/// 3. 支持下载不同分辨率的图片
/// 4. 支持分享图片
/// 5. 支持主题切换
/// 6. 支持语言切换
/// 7. 显示下载和加载进度
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../services/unsplash_service.dart';
import '../main.dart';

class PhotoDetailPage extends StatefulWidget {
  /// 要显示的图片数据
  final UnsplashPhoto photo;

  const PhotoDetailPage({
    Key? key,
    required this.photo,
  }) : super(key: key);

  @override
  State<PhotoDetailPage> createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage> {
  /// 是否正在保存图片
  bool _isSaving = false;
  
  /// 是否正在加载高清图
  bool _isLoadingFull = false;
  
  /// 是否已加载完高清图
  bool _hasLoadedFull = false;
  
  /// 高清图下载进度 (0.0 - 1.0)
  double _downloadProgress = 0;
  
  /// 图片保存进度 (0.0 - 1.0)
  double _saveProgress = 0;

  PhotoViewController? _controller;
  
  double _currentScale = 1.0;
  double _currentRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = PhotoViewController()..outputStateStream.listen(_onPhotoViewChanged);
    _loadFullResolution();
  }

  void _onPhotoViewChanged(PhotoViewControllerValue value) {
    setState(() {
      _currentScale = value.scale ?? 1.0;
      _currentRotation = value.rotation;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// 加载高清图
  /// 
  /// 流程：
  /// 1. 下载高清图片数据
  /// 2. 转换为图片提供者
  /// 3. 预缓存图片
  /// 4. 更新状态
  Future<void> _loadFullResolution() async {
    if (_hasLoadedFull) return;

    setState(() => _isLoadingFull = true);

    try {
      // 使用 Dio 下载图片以获取进度
      final dio = Dio();
      final response = await dio.get(
        widget.photo.fullUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // 将下载的图片数据转换为 ImageProvider
      final imageBytes = Uint8List.fromList(response.data);
      final imageProvider = MemoryImage(imageBytes);

      // 预加载图片
      await precacheImage(imageProvider, context);

      if (mounted) {
        setState(() {
          _isLoadingFull = false;
          _hasLoadedFull = true;
          _downloadProgress = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFull = false;
          _downloadProgress = 0;
        });
      }
    }
  }

  /// 分享图片
  /// 
  /// 分享图片信息，包括：
  /// - 标题
  /// - 摄影师信息
  /// - 图片链接
  void _sharePhoto() {
    final l10n = AppLocalizations.of(context)!;
    Share.share(
      '${l10n.sharePhotoTitle}\n'
      '${l10n.photographer(widget.photo.photographerName)}\n'
      '${l10n.photoLink(widget.photo.url)}',
    );
  }

  /// 显示分辨率选择对话框
  /// 
  /// 提供多种分辨率选项：
  /// - HD (1280×720)
  /// - Full HD (1920×1080)
  /// - 2K (2560×1440)
  /// - 4K (3840×2160)
  /// - Original (原始分辨率)
  Future<void> _showResolutionDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolutions = [
      {'name': 'HD (1280×720)', 'width': 1280, 'height': 720},
      {'name': 'Full HD (1920×1080)', 'width': 1920, 'height': 1080},
      {'name': '2K (2560×1440)', 'width': 2560, 'height': 1440},
      {'name': '4K (3840×2160)', 'width': 3840, 'height': 2160},
      {'name': 'Original', 'width': widget.photo.width, 'height': widget.photo.height},
    ];

    final resolution = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          '选择下载分辨率',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: resolutions.map((res) {
              return ListTile(
                title: Text(
                  res['name'] as String,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  (res['name'] as String) == 'Original' 
                      ? '原始分辨率'
                      : '推荐用于${(res['name'] as String).split(' ')[0]}显示器',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(res),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (resolution != null) {
      _savePhoto(
        width: resolution['width'] as int,
        height: resolution['height'] as int,
      );
    }
  }

  /// 保存图片到相册
  /// 
  /// 参数：
  /// - [width] 图片宽度
  /// - [height] 图片高度
  /// 
  /// 流程：
  /// 1. 检查存储权限
  /// 2. 下载指定分辨率的图片
  /// 3. 保存到相册
  /// 4. 显示结果提示
  Future<void> _savePhoto({
    required int width,
    required int height,
  }) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _saveProgress = 0;
    });

    try {
      // 检查存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception(AppLocalizations.of(context)!.permissionRequired);
      }

      // 构建指定分辨率的URL
      final downloadUrl = widget.photo.getCustomResolutionUrl(width, height);

      // 下载图片
      final dio = Dio();
      final response = await dio.get(
        downloadUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _saveProgress = received / total;
            });
          }
        },
      );

      // 保存到相册
      final result = await SaverGallery.saveImage(
        Uint8List.fromList(response.data),
        quality: 100,
        name: 'unsplash_${widget.photo.id}_${width}x$height',
        androidRelativePath: "Pictures/Unsplash",
        androidExistNotSave: true,
      );

      if (result.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveSuccess)),
        );
      } else {
        throw Exception(result.errorMessage ?? AppLocalizations.of(context)!.saveFailed);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saveFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black54 : Colors.white.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 语言切换按钮
          IconButton(
            icon: Text(
              MyApp.of(context)?.locale.languageCode == 'zh' ? '中/En' : 'En/中',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
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
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              MyApp.of(context)?.toggleTheme();
            },
          ),
          // 保存按钮
          IconButton(
            icon: _isSaving 
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: _saveProgress > 0 ? _saveProgress : null,
                        color: isDark ? Colors.white : Colors.black87,
                        strokeWidth: 2,
                      ),
                    ),
                    if (_saveProgress > 0)
                      Text(
                        '${(_saveProgress * 100).toInt()}%',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                )
              : Icon(
                  Icons.download,
                  color: isDark ? Colors.white : Colors.black87,
                ),
            onPressed: _isSaving ? null : _showResolutionDialog,
          ),
          // 分享按钮
          IconButton(
            icon: Icon(
              Icons.share,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _sharePhoto,
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // 背景层
          Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark ? Colors.black : Colors.grey[100],
          ),

          // 图片层
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 计算图片显示尺寸，保持原始比例
                final screenAspectRatio = constraints.maxWidth / constraints.maxHeight;
                final imageAspectRatio = widget.photo.width / widget.photo.height;
                
                double width, height;
                if (screenAspectRatio > imageAspectRatio) {
                  height = constraints.maxHeight;
                  width = height * imageAspectRatio;
                } else {
                  width = constraints.maxWidth;
                  height = width / imageAspectRatio;
                }

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 低分辨率图片
                    Hero(
                      tag: 'photo_thumb_${widget.photo.id}',
                      child: Container(
                        width: width,
                        height: height,
                        child: CachedNetworkImage(
                          imageUrl: widget.photo.url,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: isDark ? Colors.grey[900] : Colors.grey[200],
                          ),
                        ),
                      ),
                    ),

                    // 高清图片（带渐变过渡）
                    if (_hasLoadedFull)
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: Duration(milliseconds: 300),
                        child: Container(
                          width: width,
                          height: height,
                          child: PhotoView(
                            imageProvider: CachedNetworkImageProvider(
                              widget.photo.fullUrl,
                              cacheKey: 'full_${widget.photo.id}',
                            ),
                            controller: _controller,
                            enableRotation: true,
                            minScale: PhotoViewComputedScale.contained * 0.8,
                            maxScale: PhotoViewComputedScale.covered * 3,
                            initialScale: PhotoViewComputedScale.contained,
                            backgroundDecoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
                            heroAttributes: PhotoViewHeroAttributes(
                              tag: 'photo_full_${widget.photo.id}',
                            ),
                            scaleStateChangedCallback: (state) {
                              // 可以在这里处理缩放状态改变的回调
                            },
                            basePosition: Alignment.center,
                            gestureDetectorBehavior: HitTestBehavior.translucent,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // 加载进度指示器
          if (_isLoadingFull)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 6.0,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_downloadProgress > 0) ...[
                          Text(
                            '${(_downloadProgress * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        Text(
                          'Loading HD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (_hasLoadedFull)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${(_currentScale * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    if (_currentRotation != 0) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.rotate_right,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${(_currentRotation * 180 / 3.14159).toInt()}°',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 