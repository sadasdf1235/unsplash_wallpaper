/// 首页 - 展示瀑布流壁纸列表
/// 功能：
/// 1. 瀑布流展示壁纸
/// 2. 分类切换
/// 3. 无限滚动加载
/// 4. 图片缓存
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/unsplash_service.dart';
import '../main.dart';
import '../widgets/shimmer_loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Unsplash API 服务
  final UnsplashService _unsplashService = UnsplashService();

  /// 滚动控制器，用于监听滚动位置实现无限加载
  final ScrollController _scrollController = ScrollController();

  /// 图片列表数据
  final List<UnsplashPhoto> _photos = [];

  /// 当前选中的分类
  String _currentCategory = 'all';

  /// 是否正在加载数据
  bool _isLoading = false;

  /// 是否还有更多数据
  bool _hasMore = true;

  /// 当前页码
  int _page = 1;

  /// 分类列表
  final List<String> _categories = [
    'all',
    'nature',
    'architecture',
    'travel',
    'animals',
    'food',
    'fashion',
    'arts',
  ];

  /// 获取分类显示文本
  String _getCategoryText(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'all':
        return l10n.categoryAll;
      case 'nature':
        return l10n.categoryNature;
      case 'architecture':
        return l10n.categoryArchitecture;
      case 'travel':
        return l10n.categoryTravel;
      case 'animals':
        return l10n.categoryAnimals;
      case 'food':
        return l10n.categoryFood;
      case 'fashion':
        return l10n.categoryFashion;
      case 'arts':
        return l10n.categoryArts;
      default:
        return category;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听处理
  /// 当滚动到距离底部500像素时，自动加载更多数据
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoading &&
        _hasMore) {
      _loadPhotos();
    }
  }

  /// 加载图片数据
  ///
  /// 处理流程：
  /// 1. 检查是否正在加载
  /// 2. 设置加载状态
  /// 3. 调用API获取数据
  /// 4. 更新状态
  /// 5. 错误处理
  Future<void> _loadPhotos() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final photos = await _unsplashService.getPhotos(
        category: _currentCategory,
        page: _page,
        perPage: 30,
      );

      setState(() {
        _photos.addAll(photos);
        _page++;
        _hasMore = photos.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading photos: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载图片失败: $e')),
      );
    }
  }

  /// 切换分类
  ///
  /// [category] 目标分类名称
  ///
  /// 处理流程：
  /// 1. 检查是否为当前分类
  /// 2. 清空现有数据
  /// 3. 重置页码和状态
  /// 4. 重新加载数据
  Future<void> _changeCategory(String category) async {
    if (category == _currentCategory) return;

    setState(() {
      _currentCategory = category;
      _photos.clear();
      _page = 1;
      _hasMore = true;
    });
    await _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        actions: [
          // 语言切换按钮
          IconButton(
            icon: Text(
              MyApp.of(context)?.locale.languageCode == 'zh' ? '中/En' : 'En/中',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
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
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              MyApp.of(context)?.toggleTheme();
            },
          ),
        ],
      ),
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Column(
        children: [
          // 分类按钮组
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getCategoryText(context, category)),
                    selected: _currentCategory == category,
                    onSelected: (_) => _changeCategory(category),
                  ),
                );
              },
            ),
          ),

          // 瀑布流图片网格
          Expanded(
            child: _photos.isEmpty && _isLoading
                ? MasonryGridView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: 10, // 显示10个骨架屏项目
                    gridDelegate:
                        SliverSimpleGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    itemBuilder: (context, index) {
                      // 随机高度，使骨架屏看起来更自然
                      final random = index % 2 == 0 ? 1.2 : 0.8;
                      return ShimmerLoading(
                        width: double.infinity,
                        height:
                            MediaQuery.of(context).size.width * 0.5 * random,
                      );
                    },
                  )
                : _photos.isEmpty
                    ? Center(child: Text(l10n.noImagesFound))
                    : MasonryGridView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(8),
                        itemCount: _photos.length + (_hasMore ? 1 : 0),
                        gridDelegate:
                            SliverSimpleGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                        ),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        itemBuilder: (context, index) {
                          if (index >= _photos.length) {
                            return Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final photo = _photos[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/photo_detail',
                                arguments: photo,
                              );
                            },
                            child: Hero(
                              tag: 'photo_thumb_${photo.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: photo.url,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => ShimmerLoading(
                                    width: double.infinity,
                                    height: MediaQuery.of(context).size.width *
                                        0.5 *
                                        (photo.height / photo.width),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      AspectRatio(
                                    aspectRatio: photo.width / photo.height,
                                    child: Container(
                                      color: isDark
                                          ? Colors.grey[900]
                                          : Colors.grey[300],
                                      child: Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
