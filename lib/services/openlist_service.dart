import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class OpenlistService {
  Future<bool> syncFolder({
    required String address,
    required String? authToken,
    required String sourcePath,
    required String localPath,
    required Function(List<SyncFile>, int, int, String) onProgress,
    required Function(String) onLog,
    required Function() onTokenExpired, // 新增：令牌过期回调
  }) async {
    final List<SyncFile> fileList = [];
    int totalFiles = 0;
    int processedFiles = 0;
    String currentFileName = '';

    try {
      // 验证源路径
      if (sourcePath.contains('..') || sourcePath.isEmpty) {
        throw Exception('源路径无效');
      }

      // 验证本地路径
      if (localPath.isEmpty) {
        throw Exception('本地路径不能为空');
      }

      // 获取目录信息 - 使用用户输入的路径
      onLog('正在获取目录信息...');
      final dirInfo = await _getDirectoryInfo(address, authToken, sourcePath, onTokenExpired);
      if (dirInfo == null || !dirInfo.isDir) {
        throw Exception('源路径不是一个有效的目录');
      }

      // 递归获取所有文件
      onLog('正在扫描目录结构...');
      await _getAllFilesRecursive(address, authToken, sourcePath, sourcePath, fileList, onTokenExpired);

      totalFiles = fileList.length;
      onProgress(fileList, totalFiles, processedFiles, currentFileName);

      if (fileList.isEmpty) {
        onLog('目录中没有文件可同步');
        return true;
      }

      onLog('发现 $totalFiles 个文件，开始下载...');

      // 创建本地目录
      final localDir = Directory(localPath);
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }

      // 下载文件
      int successCount = 0;
      int failCount = 0;
      
      for (int i = 0; i < fileList.length; i++) {
        final file = fileList[i];
        currentFileName = file.fsObject.name;
        onLog('正在下载 ($processedFiles/$totalFiles): $currentFileName');
        
        // 记录sign信息用于调试
        if (file.fsObject.sign != null) {
          onLog('文件签名: ${file.fsObject.sign}');
        } else {
          onLog('警告: 文件没有签名信息');
        }
        
        final success = await _downloadFile(
          address: address,
          authToken: authToken,
          syncFile: file,
          localPath: localPath,
          onTokenExpired: onTokenExpired,
        );
        
        if (success) {
          successCount++;
          onLog('✓ 下载完成: $currentFileName');
        } else {
          failCount++;
          onLog('✗ 下载失败: $currentFileName');
        }
        
        processedFiles = i + 1;
        onProgress(fileList, totalFiles, processedFiles, currentFileName);
      }

      onLog('同步完成: $successCount 成功, $failCount 失败');
      return failCount == 0;
    } catch (e) {
      onLog('同步失败: $e');
      throw e;
    }
  }

  Future<FsObject?> _getDirectoryInfo(
    String address, 
    String? authToken, 
    String dirPath,
    Function() onTokenExpired,
  ) async {
    try {
      final url = Uri.parse('http://$address/api/fs/get');
      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': authToken,
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'path': dirPath}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return FsObject.fromJson(data['data']);
        } else {
          // 检查是否是密码更改错误
          if (data['code'] == 401 && data['message'] == 'Password has been changed, login please') {
            onTokenExpired();
            throw TokenExpiredException('密码已更改，请重新登录');
          }
          throw Exception('API错误: ${data['message']}');
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        rethrow;
      }
      throw Exception('获取目录信息失败: $e');
    }
  }

  Future<void> _getAllFilesRecursive(
    String address,
    String? authToken,
    String currentVirtualPath,
    String basePath,
    List<SyncFile> fileList,
    Function() onTokenExpired,
  ) async {
    try {
      final contents = await _listDirectory(address, authToken, currentVirtualPath, onTokenExpired);
      
      for (final item in contents) {
        final newVirtualPath = _buildVirtualPath(currentVirtualPath, item.name);
        
        if (item.isDir) {
          await _getAllFilesRecursive(address, authToken, newVirtualPath, basePath, fileList, onTokenExpired);
        } else {
          final relativePath = _getRelativePath(newVirtualPath, basePath);
          
          // 为每个文件预先获取详细信息（包含sign）
          final fileDetail = await _getFileInfo(address, authToken, newVirtualPath, onTokenExpired);
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
              sign: fsObject.sign, // 这里包含了从API获取的sign
              thumb: fsObject.thumb,
              type: fsObject.type,
            ),
            relativePath: relativePath,
          ));
        }
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        rethrow;
      }
      print('递归获取文件失败: $e');
      // 不抛出异常，继续处理其他目录
    }
  }

  Future<List<FsObject>> _listDirectory(
    String address, 
    String? authToken, 
    String dirPath,
    Function() onTokenExpired,
  ) async {
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
          'path': dirPath,
          'page': 1,
          'per_page': 1000,
          'refresh': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final List<dynamic> itemsData = data['data']['content'] ?? [];
          return itemsData.map((item) => FsObject.fromJson(item)).toList();
        } else {
          // 检查是否是密码更改错误
          if (data['code'] == 401 && data['message'] == 'Password has been changed, login please') {
            onTokenExpired();
            throw TokenExpiredException('密码已更改，请重新登录');
          }
          throw Exception('API错误: ${data['message']}');
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        rethrow;
      }
      throw Exception('获取目录内容失败: $e');
    }
  }

  // 新增：获取单个文件信息的方法
  Future<FsObject?> _getFileInfo(
    String address, 
    String? authToken, 
    String filePath,
    Function() onTokenExpired,
  ) async {
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
          // 检查是否是密码更改错误
          if (data['code'] == 401 && data['message'] == 'Password has been changed, login please') {
            onTokenExpired();
            throw TokenExpiredException('密码已更改，请重新登录');
          }
          print('获取文件信息API错误: ${data['message']}');
          return null;
        }
      } else {
        print('获取文件信息HTTP错误: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        rethrow;
      }
      print('获取文件信息失败: $e');
      return null;
    }
  }

  Future<bool> _downloadFile({
    required String address,
    required String? authToken,
    required SyncFile syncFile,
    required String localPath,
    required Function() onTokenExpired, // 新增：令牌过期回调
  }) async {
    try {
      final file = syncFile.fsObject;
      
      // 首先通过API获取文件的最新信息（包含sign）
      final fileInfo = await _getFileInfo(address, authToken, file.path, onTokenExpired);
      if (fileInfo == null) {
        print('无法获取文件信息: ${file.name}');
        return false;
      }

      // 关键修改：正确构建下载URL
      // 根据您提供的分析链接，正确的格式应该是：
      // http://地址/d/路径?sign=xxx
      // 其中路径应该是相对于存储的路径，而不是完整的文件系统路径
      
      // 移除开头的斜杠（如果存在）
      String downloadPath = file.path;
      if (downloadPath.startsWith('/')) {
        downloadPath = downloadPath.substring(1);
      }
      
      // 对路径进行URL编码（但不编码斜杠）
      final encodedPath = _encodePath(downloadPath);
      
      // 构建下载URL
      final downloadUrl = Uri.parse('http://$address/d/$encodedPath');
      
      final Map<String, String> queryParams = {};
      if (fileInfo.sign != null && fileInfo.sign!.isNotEmpty) {
        queryParams['sign'] = fileInfo.sign!;
      }

      final headers = {
        if (authToken != null) 'Authorization': authToken,
      };

      final fullUrl = downloadUrl.replace(queryParameters: queryParams);
      print('下载URL: $fullUrl');

      final response = await http.get(
        fullUrl,
        headers: headers,
      );

      if (response.statusCode == 200) {
        // 使用安全的相对路径构建本地文件路径
        final localFilePath = path.join(localPath, syncFile.relativePath);
        
        // 确保目录存在
        final localFileDir = Directory(path.dirname(localFilePath));
        if (!await localFileDir.exists()) {
          await localFileDir.create(recursive: true);
        }

        // 写入文件
        final localFile = File(localFilePath);
        await localFile.writeAsBytes(response.bodyBytes);
        print('下载完成: ${file.name} -> $localFilePath');
        return true;
      } else {
        // 检查响应体是否包含密码更改错误
        if (response.statusCode == 401) {
          try {
            final data = jsonDecode(response.body);
            if (data['code'] == 401 && data['message'] == 'Password has been changed, login please') {
              onTokenExpired();
              throw TokenExpiredException('密码已更改，请重新登录');
            }
          } catch (e) {
            // 如果不是JSON响应，忽略
          }
        }
        
        print('下载失败 ${file.name}: ${response.statusCode}');
        print('下载URL: $fullUrl');
        print('响应头: ${response.headers}');
        print('响应体: ${response.body}');
        return false;
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        rethrow;
      }
      print('下载错误 ${syncFile.fsObject.name}: $e');
      return false;
    }
  }

  // 新增：路径编码方法，正确处理空格和特殊字符但保留斜杠
  String _encodePath(String filePath) {
    // 将路径分割成各部分
    final parts = filePath.split('/');
    
    // 对每个部分进行URL编码，然后重新组合
    final encodedParts = parts.map((part) => Uri.encodeComponent(part)).toList();
    
    // 重新组合路径
    return encodedParts.join('/');
  }

  String _buildVirtualPath(String basePath, String itemName) {
    String normalizePath(String p) {
      return p.replaceAll(r'\', '/');
    }
    
    final normalizedBasePath = normalizePath(basePath);
    
    String base = normalizedBasePath;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    
    return '$base/$itemName';
  }

  String _getRelativePath(String fullPath, String basePath) {
    String normalizePath(String p) {
      return p.replaceAll(r'\', '/');
    }
    
    final normalizedFullPath = normalizePath(fullPath);
    final normalizedBasePath = normalizePath(basePath);
    
    String base = normalizedBasePath;
    if (!base.endsWith('/')) {
      base += '/';
    }
    
    if (normalizedFullPath.startsWith(base)) {
      String relativePath = normalizedFullPath.substring(base.length);
      return _cleanPath(relativePath);
    }
    
    String fileName = path.basename(normalizedFullPath);
    return _generateSafeFileName(fileName);
  }

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

  String _generateSafeFileName(String originalName) {
    return originalName
        .replaceAll(RegExp(r'[<>:"|?*]'), '_')
        .replaceAll(RegExp(r'[\\/]'), '_')
        .replaceAll(':', '_');
  }
}

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

class SyncFile {
  final FsObject fsObject;
  final String relativePath;

  SyncFile({
    required this.fsObject,
    required this.relativePath,
  });
}

// 新增：令牌过期异常类
class TokenExpiredException implements Exception {
  final String message;
  
  TokenExpiredException(this.message);
  
  @override
  String toString() => message;
}