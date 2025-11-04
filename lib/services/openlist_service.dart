import 'dart:convert';
import 'package:http/http.dart' as http;

/// Openlist服务类 - 负责与Openlist服务器通信和API调用
class OpenlistService {
  // 私有构造函数
  OpenlistService._internal();
  
  // 单例实例
  static final OpenlistService _instance = OpenlistService._internal();
  
  /// 获取Openlist服务单例
  factory OpenlistService() => _instance;
  
  /// 用户登录认证
  /// [address] 服务器地址
  /// [username] 用户名
  /// [password] 密码
  /// [otpCode] 两步验证码（可选）
  /// 返回：包含认证结果的Map，包含token和用户信息
  Future<Map<String, dynamic>> login({
    required String address,
    required String username,
    required String password,
    String otpCode = '',
  }) async {
    try {
      final url = Uri.parse('http://$address/api/auth/login');
      final Map<String, dynamic> requestBody = {
        'username': username,
        'password': password,
      };
      
      if (otpCode.isNotEmpty) {
        requestBody['otp_code'] = otpCode;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {
            'success': true,
            'token': data['data']['token'],
            'message': '登录成功',
          };
        } else {
          return {
            'success': false,
            'message': '登录失败: ${data['message']}',
            'errorCode': data['code'],
          };
        }
      } else {
        return {
          'success': false,
          'message': '登录失败: HTTP ${response.statusCode}',
          'errorCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '登录出错: $e',
        'errorCode': -1,
      };
    }
  }

  /// 获取目录信息
  /// [address] 服务器地址
  /// [authToken] 认证令牌
  /// [path] 目录路径
  /// 返回：目录信息或null（如果获取失败）
  Future<FsObject?> getDirectoryInfo({
    required String address,
    required String? authToken,
    required String path,
  }) async {
    try {
      final url = Uri.parse('http://$address/api/fs/get');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': authToken,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'path': path}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return FsObject.fromJson(data['data']);
        } else {
          throw Exception('API错误: ${data['message']}');
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取目录信息失败: $e');
    }
  }

  /// 列出目录内容
  /// [address] 服务器地址
  /// [authToken] 认证令牌
  /// [path] 目录路径
  /// [page] 页码
  /// [perPage] 每页数量
  /// 返回：目录内容列表
  Future<List<FsObject>> listDirectory({
    required String address,
    required String? authToken,
    required String path,
    int page = 1,
    int perPage = 1000,
  }) async {
    try {
      final url = Uri.parse('http://$address/api/fs/list');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': authToken,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'path': path,
          'page': page,
          'per_page': perPage,
          'refresh': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final List<dynamic> itemsData = data['data']['content'] ?? [];
          return itemsData.map((item) => FsObject.fromJson(item)).toList();
        } else {
          throw Exception('API错误: ${data['message']}');
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取目录内容失败: $e');
    }
  }

  /// 获取文件详细信息
  /// [address] 服务器地址
  /// [authToken] 认证令牌
  /// [filePath] 文件路径
  /// 返回：文件信息或null（如果获取失败）
  Future<FsObject?> getFileInfo({
    required String address,
    required String? authToken,
    required String filePath,
  }) async {
    try {
      final url = Uri.parse('http://$address/api/fs/get');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': authToken,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'path': filePath}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return FsObject.fromJson(data['data']);
        } else {
          print('获取文件信息API错误: ${data['message']}');
          return null;
        }
      } else {
        print('获取文件信息HTTP错误: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取文件信息失败: $e');
      return null;
    }
  }

  /// 构建文件下载URL
  /// [address] 服务器地址
  /// [filePath] 文件路径
  /// [sign] 文件签名（可选）
  /// 返回：构建好的下载URL
  Uri buildDownloadUrl({
    required String address,
    required String filePath,
    String? sign,
  }) {
    // 移除开头的斜杠（如果存在）
    String downloadPath = filePath;
    if (downloadPath.startsWith('/')) {
      downloadPath = downloadPath.substring(1);
    }
    
    // 对路径进行URL编码（但不编码斜杠）
    final encodedPath = _encodePath(downloadPath);
    
    // 构建下载URL
    final downloadUrl = Uri.parse('http://$address/d/$encodedPath');
    
    final Map<String, String> queryParams = {};
    if (sign != null && sign.isNotEmpty) {
      queryParams['sign'] = sign;
    }

    return downloadUrl.replace(queryParameters: queryParams);
  }

  /// 递归获取目录中的所有文件
  /// [address] 服务器地址
  /// [authToken] 认证令牌
  /// [basePath] 基础路径
  /// [onProgress] 进度回调函数
  /// 返回：文件列表
  Future<List<SyncFile>> getAllFilesRecursive({
    required String address,
    required String? authToken,
    required String basePath,
    required Function(String) onProgress,
  }) async {
    final List<SyncFile> fileList = [];
    
    try {
      onProgress('正在扫描目录结构...');
      await _getAllFilesRecursiveInternal(
        address: address,
        authToken: authToken,
        currentVirtualPath: basePath,
        basePath: basePath,
        fileList: fileList,
        onProgress: onProgress,
      );
      
      onProgress('发现 ${fileList.length} 个文件');
      return fileList;
    } catch (e) {
      onProgress('扫描目录失败: $e');
      rethrow;
    }
  }

  /// 内部递归获取文件的方法
  Future<void> _getAllFilesRecursiveInternal({
    required String address,
    required String? authToken,
    required String currentVirtualPath,
    required String basePath,
    required List<SyncFile> fileList,
    required Function(String) onProgress,
  }) async {
    try {
      final contents = await listDirectory(
        address: address,
        authToken: authToken,
        path: currentVirtualPath,
      );
      
      for (final item in contents) {
        final newVirtualPath = _buildVirtualPath(currentVirtualPath, item.name);
        
        if (item.isDir) {
          // 递归处理子目录
          await _getAllFilesRecursiveInternal(
            address: address,
            authToken: authToken,
            currentVirtualPath: newVirtualPath,
            basePath: basePath,
            fileList: fileList,
            onProgress: onProgress,
          );
        } else {
          // 处理文件
          final relativePath = _getRelativePath(newVirtualPath, basePath);
          
          // 获取文件的详细信息（包含sign）
          final fileDetail = await getFileInfo(
            address: address,
            authToken: authToken,
            filePath: newVirtualPath,
          );
          
          final fsObject = fileDetail ?? item; // 如果获取详情失败，使用列表中的基础信息
          
          fileList.add(SyncFile(
            fsObject: FsObject(
              id: fsObject.id,
              path: newVirtualPath,
              name: fsObject.name,
              size: fsObject.size,
              isDir: fsObject.isDir,
              modified: fsObject.modified,
              created: fsObject.created,
              sign: fsObject.sign,
              thumb: fsObject.thumb,
              type: fsObject.type,
            ),
            relativePath: relativePath,
          ));
          
          onProgress('发现文件: ${item.name}');
        }
      }
    } catch (e) {
      onProgress('处理目录 $currentVirtualPath 时出错: $e');
      // 不抛出异常，继续处理其他目录
    }
  }

  /// 路径编码方法，正确处理空格和特殊字符但保留斜杠
  String _encodePath(String filePath) {
    final parts = filePath.split('/');
    final encodedParts = parts.map((part) => Uri.encodeComponent(part)).toList();
    return encodedParts.join('/');
  }

  /// 构建虚拟路径
  String _buildVirtualPath(String basePath, String itemName) {
    String normalizePath(String p) {
      return p.replaceAll(r'\', '/'); // 统一使用正斜杠
    }
    
    final normalizedBasePath = normalizePath(basePath);
    String base = normalizedBasePath;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1); // 移除末尾斜杠
    }
    
    return '$base/$itemName'; // 拼接路径
  }

  /// 获取相对路径
  String _getRelativePath(String fullPath, String basePath) {
    String normalizePath(String p) {
      return p.replaceAll(r'\', '/');
    }
    
    final normalizedFullPath = normalizePath(fullPath);
    final normalizedBasePath = normalizePath(basePath);
    
    String base = normalizedBasePath;
    if (!base.endsWith('/')) {
      base += '/'; // 确保basePath以斜杠结尾
    }
    
    if (normalizedFullPath.startsWith(base)) {
      String relativePath = normalizedFullPath.substring(base.length);
      return _cleanPath(relativePath);
    }
    
    String fileName = path.basename(normalizedFullPath);
    return _generateSafeFileName(fileName);
  }

  /// 清理路径
  String _cleanPath(String filePath) {
    if (filePath.contains(':')) {
      List<String> parts = filePath.split('/');
      for (int i = parts.length - 1; i >= 0; i--) {
        if (parts[i].contains(':')) {
          return parts.sublist(i + 1).join('/');
        }
      }
    }
    return filePath;
  }

  /// 生成安全文件名
  String _generateSafeFileName(String originalName) {
    return originalName
        .replaceAll(RegExp(r'[<>:"|?*]'), '_')
        .replaceAll(RegExp(r'[\\/]'), '_')
        .replaceAll(':', '_');
  }
}

/// 文件系统对象类
class FsObject {
  final String? id;
  final String path;
  final String name;
  final int size;
  final bool isDir;
  final String? modified;
  final String? created;
  final String? sign;
  final String? thumb;
  final int? type;

  FsObject({
    this.id,
    required this.path,
    required this.name,
    required this.size,
    required this.isDir,
    this.modified,
    this.created,
    this.sign,
    this.thumb,
    this.type,
  });

  /// 从JSON创建FsObject的工厂方法
  factory FsObject.fromJson(Map<String, dynamic> json) {
    return FsObject(
      id: json['id'],
      path: json['path'] ?? '',
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      isDir: json['is_dir'] ?? false,
      modified: json['modified'],
      created: json['created'],
      sign: json['sign'],
      thumb: json['thumb'],
      type: json['type'],
    );
  }
}

/// 同步文件类，包含文件对象和相对路径
class SyncFile {
  final FsObject fsObject;
  final String relativePath;

  SyncFile({
    required this.fsObject,
    required this.relativePath,
  });
}

/// 路径处理工具（从path包导入）
class path {
  static String basename(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : '';
  }
  
  static String join(String part1, String part2) {
    if (part1.endsWith('/')) {
      return '$part1$part2';
    } else {
      return '$part1/$part2';
    }
  }
  
  static String dirname(String path) {
    final parts = path.split('/');
    if (parts.length <= 1) return '';
    return parts.sublist(0, parts.length - 1).join('/');
  }
}