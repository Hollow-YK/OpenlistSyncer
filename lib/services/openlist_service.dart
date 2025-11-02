import 'dart:convert'; // JSON编解码
import 'dart:io'; // 文件IO操作
import 'package:http/http.dart' as http; // HTTP客户端
import 'package:path/path.dart' as path; // 路径处理

// Openlist服务类，负责与Openlist服务器通信和文件同步
class OpenlistService {
  // 同步文件夹的主要方法
  Future<bool> syncFolder({
    required String address, // 服务器地址
    required String? authToken, // 认证令牌
    required String sourcePath, // 源路径（服务器端）
    required String localPath, // 本地路径
    required Function(List<SyncFile>, int, int, String) onProgress, // 进度回调
    required Function(String) onLog, // 日志回调
    required Function() onTokenExpired, // 令牌过期回调
  }) async {
    final List<SyncFile> fileList = []; // 文件列表
    int totalFiles = 0; // 总文件数
    int processedFiles = 0; // 已处理文件数
    String currentFileName = ''; // 当前正在处理的文件名

    try {
      // 验证源路径安全性
      if (sourcePath.contains('..') || sourcePath.isEmpty) {
        throw Exception('源路径无效'); // 防止路径遍历攻击
      }

      // 验证本地路径
      if (localPath.isEmpty) {
        throw Exception('本地路径不能为空');
      }

      // 获取目录信息
      onLog('正在获取目录信息...');
      final dirInfo = await _getDirectoryInfo(address, authToken, sourcePath, onTokenExpired);
      if (dirInfo == null || !dirInfo.isDir) {
        throw Exception('源路径不是一个有效的目录');
      }

      // 递归获取所有文件
      onLog('正在扫描目录结构...');
      await _getAllFilesRecursive(address, authToken, sourcePath, sourcePath, fileList, onTokenExpired);

      totalFiles = fileList.length; // 设置总文件数
      onProgress(fileList, totalFiles, processedFiles, currentFileName); // 更新进度

      if (fileList.isEmpty) {
        onLog('目录中没有文件可同步');
        return true; // 空目录也算同步成功
      }

      onLog('发现 $totalFiles 个文件，开始下载...');

      // 创建本地目录
      final localDir = Directory(localPath);
      if (!await localDir.exists()) {
        await localDir.create(recursive: true); // 递归创建目录
      }

      // 下载文件
      int successCount = 0; // 成功计数
      int failCount = 0; // 失败计数
      
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
        
        // 下载单个文件
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
        
        processedFiles = i + 1; // 更新已处理文件数
        onProgress(fileList, totalFiles, processedFiles, currentFileName); // 更新进度
      }

      onLog('同步完成: $successCount 成功, $failCount 失败');
      return failCount == 0; // 返回是否全部成功
    } catch (e) {
      onLog('同步失败: $e');
      throw e; // 重新抛出异常
    }
  }

  // 获取目录信息
  Future<FsObject?> _getDirectoryInfo(
    String address, 
    String? authToken, 
    String dirPath,
    Function() onTokenExpired,
  ) async {
    try {
      final url = Uri.parse('http://$address/api/fs/get'); // 构建API URL
      final headers = {
        'Content-Type': 'application/json', // JSON内容类型
        if (authToken != null) 'Authorization': authToken, // 条件添加认证头
      };
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'path': dirPath}), // 编码请求体
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // 解码响应体
        if (data['code'] == 200) {
          return FsObject.fromJson(data['data']); // 成功返回目录对象
        } else {
          // 检查是否是密码更改错误
          if (data['code'] == 401 && data['message'] == 'Password has been changed, login please') {
            onTokenExpired(); // 触发令牌过期回调
            throw TokenExpiredException('密码已更改，请重新登录');
          }
          throw Exception('API错误: ${data['message']}');
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TokenExpiredException) {
        rethrow; // 重新抛出令牌过期异常
      }
      throw Exception('获取目录信息失败: $e');
    }
  }

  // 递归获取所有文件
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
          // 如果是目录，递归处理
          await _getAllFilesRecursive(address, authToken, newVirtualPath, basePath, fileList, onTokenExpired);
        } else {
          // 如果是文件，添加到文件列表
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
            relativePath: relativePath, // 相对路径
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

  // 列出目录内容
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
          'page': 1, // 页码
          'per_page': 1000, // 每页数量
          'refresh': false, // 不强制刷新
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final List<dynamic> itemsData = data['data']['content'] ?? [];
          return itemsData.map((item) => FsObject.fromJson(item)).toList(); // 转换为FsObject列表
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

  // 获取单个文件信息的方法
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
          return null; // 返回null而不是抛出异常
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

  // 下载单个文件
  Future<bool> _downloadFile({
    required String address,
    required String? authToken,
    required SyncFile syncFile,
    required String localPath,
    required Function() onTokenExpired,
  }) async {
    try {
      final file = syncFile.fsObject;
      
      // 首先通过API获取文件的最新信息（包含sign）
      final fileInfo = await _getFileInfo(address, authToken, file.path, onTokenExpired);
      if (fileInfo == null) {
        print('无法获取文件信息: ${file.name}');
        return false;
      }
      
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
        queryParams['sign'] = fileInfo.sign!; // 添加签名参数
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
        await localFile.writeAsBytes(response.bodyBytes); // 写入二进制数据
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

  // 路径编码方法，正确处理空格和特殊字符但保留斜杠
  String _encodePath(String filePath) {
    // 将路径分割成各部分
    final parts = filePath.split('/');
    
    // 对每个部分进行URL编码，然后重新组合
    final encodedParts = parts.map((part) => Uri.encodeComponent(part)).toList();
    
    // 重新组合路径
    return encodedParts.join('/');
  }

  // 构建虚拟路径
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

  // 获取相对路径
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
      return _cleanPath(relativePath); // 清理路径
    }
    
    String fileName = path.basename(normalizedFullPath); // 获取文件名
    return _generateSafeFileName(fileName); // 生成安全文件名
  }

  // 清理路径
  String _cleanPath(String filePath) {
    if (filePath.contains(':')) {
      List<String> parts = filePath.split('/');
      for (int i = parts.length - 1; i >= 0; i--) {
        if (parts[i].contains(':')) {
          return parts.sublist(i + 1).join('/'); // 移除包含冒号的部分
        }
      }
    }
    return filePath;
  }

  // 生成安全文件名
  String _generateSafeFileName(String originalName) {
    return originalName
        .replaceAll(RegExp(r'[<>:"|?*]'), '_') // 替换非法字符
        .replaceAll(RegExp(r'[\\/]'), '_')
        .replaceAll(':', '_');
  }
}

// 文件系统对象类
class FsObject {
  final String? id; // 文件ID
  final String path; // 文件路径
  final String name; // 文件名
  final int size; // 文件大小
  final bool isDir; // 是否为目录
  final String? modified; // 修改时间
  final String? created; // 创建时间
  final String? sign; // 文件签名（用于下载验证）
  final String? thumb; // 缩略图
  final int? type; // 文件类型

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

  // 从JSON创建FsObject的工厂方法
  factory FsObject.fromJson(Map<String, dynamic> json) {
    return FsObject(
      id: json['id'],
      path: json['path'] ?? '', // 提供默认值
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

// 同步文件类，包含文件对象和相对路径
class SyncFile {
  final FsObject fsObject; // 文件系统对象
  final String relativePath; // 相对路径

  SyncFile({
    required this.fsObject,
    required this.relativePath,
  });
}

// 令牌过期异常类
class TokenExpiredException implements Exception {
  final String message;
  
  TokenExpiredException(this.message);
  
  @override
  String toString() => message;
}