import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Unsplash API 服务
/// 
/// 提供与 Unsplash API 交互的方法，包括：
/// 1. 获取图片列表
/// 2. 获取随机图片
class UnsplashPhoto {
  final String id;
  final String url;
  final String fullUrl;
  final String photographerName;
  final int width;
  final int height;

  UnsplashPhoto({
    required this.id,
    required this.url,
    required this.fullUrl,
    required this.photographerName,
    required this.width,
    required this.height,
  });

  /// 从JSON数据创建UnsplashPhoto实例
  factory UnsplashPhoto.fromJson(Map<String, dynamic> json) {
    return UnsplashPhoto(
      id: json['id'],
      url: json['urls']['regular'] + '&w=800&h=800&q=80',
      fullUrl: json['urls']['raw'] + '&w=2560&h=1440&q=100',
      photographerName: json['user']['name'],
      width: json['width'],
      height: json['height'],
    );
  }

  /// 获取欢迎页的预览图URL（低分辨率）
  String get welcomePreviewUrl => 
      fullUrl.replaceAll('&w=2560&h=1440&q=100', '&w=640&h=360&q=60');

  /// 获取欢迎页的高清图URL
  String get welcomeFullUrl => 
      fullUrl.replaceAll('&w=2560&h=1440&q=100', '&w=1920&h=1080&q=100');

  /// 获取指定分辨率的图片URL
  String getCustomResolutionUrl(int width, int height) {
    if (width == this.width && height == this.height) {
      // 原始分辨率
      return fullUrl.replaceAll(RegExp(r'&w=\d+&h=\d+&q=\d+'), '');
    }
    return fullUrl.replaceAll(
      RegExp(r'&w=\d+&h=\d+&q=\d+'),
      '&w=$width&h=$height&q=100',
    );
  }
}

/// Unsplash API 服务类
class UnsplashService {
  /// API基础URL
  final String _baseUrl = 'https://api.unsplash.com';
  
  /// API访问密钥
  /// 从 Unsplash 开发者平台获取：https://unsplash.com/developers
  final String _accessKey = ApiConfig.unsplashAccessKey;

  /// 获取图片列表
  /// 
  /// 参数:
  /// - [category] 图片分类，默认为'all'
  /// - [page] 页码，默认为1
  /// - [perPage] 每页数量，默认为30
  /// - [width] 图片宽度，默认为200
  /// - [height] 图片高度，默认为200
  /// 
  /// 返回:
  /// - Future<List<UnsplashPhoto>> 图片列表
  Future<List<UnsplashPhoto>> getPhotos({
    String category = 'all',
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final queryParams = {
        'client_id': _accessKey,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      // 根据分类使用不同的API端点
      final endpoint = category == 'all' 
          ? '$_baseUrl/photos'
          : '$_baseUrl/search/photos';

      if (category != 'all') {
        queryParams['query'] = category;
      }

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        List<dynamic> photoData;
        
        // 搜索API和普通列表API返回的数据结构不同
        if (category == 'all') {
          photoData = jsonData as List<dynamic>;
        } else {
          photoData = (jsonData as Map<String, dynamic>)['results'] as List<dynamic>;
        }

        return photoData.map((photo) => UnsplashPhoto.fromJson(photo)).toList();
      } else {
        throw Exception('Failed to load photos: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 获取随机图片
  /// 
  /// 返回:
  /// - Future<UnsplashPhoto> 随机图片信息
  /// 
  /// 说明:
  /// - 获取横向布局的随机图片
  /// - 用于欢迎页面背景
  Future<UnsplashPhoto> getRandomPhoto() async {
    try {
      final queryParams = {
        'client_id': _accessKey,
        'orientation': 'landscape',
        'content_filter': 'high',  // 获取高质量图片
      };

      final uri = Uri.parse('$_baseUrl/photos/random')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UnsplashPhoto.fromJson(data);
      } else {
        throw Exception('Failed to load random photo: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
} 