import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// 文件管理器类 - 负责处理本地文件操作和下载
class FileManager {
  // 私有构造函数
  FileManager._internal();
  
  // 单例实例
  static final FileManager _instance = FileManager._internal();
  
  /// 获取文件管理器单例
  factory FileManager() => _instance;
  
  /// 下载文件到本地
  /// [downloadUrl] 文件下载URL
  /// [localFilePath] 本地文件保存路径
  /// [headers] HTTP请求头
  /// 返回：下载是否成功
  Future<bool> downloadFile({
    required Uri downloadUrl,
    required String localFilePath,
    Map<String, String>? headers,
  }) async {
    try {
      // 发送HTTP GET请求下载文件
      final response = await http.get(
        downloadUrl,
        headers: headers,
      );

      if (response.statusCode == 200) {
        // 确保目录存在
        final localFileDir = Directory(path.dirname(localFilePath));
        if (!await localFileDir.exists()) {
          await localFileDir.create(recursive: true);
        }

        // 写入文件
        final localFile = File(localFilePath);
        await localFile.writeAsBytes(response.bodyBytes);
        
        print('文件下载完成: $downloadUrl -> $localFilePath');
        return true;
      } else {
        print('文件下载失败: HTTP ${response.statusCode}');
        print('下载URL: $downloadUrl');
        return false;
      }
    } catch (e) {
      print('文件下载错误: $e');
      return false;
    }
  }

  /// 检查目录是否存在，如果不存在则创建
  /// [directoryPath] 目录路径
  /// [recursive] 是否递归创建父目录
  /// 返回：目录是否存在或创建成功
  Future<bool> ensureDirectoryExists(String directoryPath, {bool recursive = true}) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: recursive);
      }
      return true;
    } catch (e) {
      print('创建目录失败: $e');
      return false;
    }
  }

  /// 检查文件是否存在
  /// [filePath] 文件路径
  /// 返回：文件是否存在
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      print('检查文件存在性失败: $e');
      return false;
    }
  }

  /// 获取文件大小
  /// [filePath] 文件路径
  /// 返回：文件大小（字节），如果文件不存在则返回-1
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return -1;
    } catch (e) {
      print('获取文件大小失败: $e');
      return -1;
    }
  }

  /// 删除文件
  /// [filePath] 文件路径
  /// 返回：删除是否成功
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false; // 文件不存在，认为删除成功
    } catch (e) {
      print('删除文件失败: $e');
      return false;
    }
  }

  /// 安全地构建本地文件路径
  /// [basePath] 基础路径
  /// [relativePath] 相对路径
  /// 返回：安全的完整文件路径
  String buildSafeFilePath(String basePath, String relativePath) {
    // 清理相对路径中的不安全字符
    final safeRelativePath = _cleanRelativePath(relativePath);
    
    // 使用path.join安全地拼接路径
    return path.join(basePath, safeRelativePath);
  }

  /// 清理相对路径，移除不安全字符和路径遍历攻击
  /// [relativePath] 原始相对路径
  /// 返回：安全的相对路径
  String _cleanRelativePath(String relativePath) {
    if (relativePath.contains('..')) {
      // 防止路径遍历攻击
      final parts = relativePath.split('/');
      final safeParts = parts.where((part) => part != '..').toList();
      return safeParts.join('/');
    }
    
    // 替换可能的不安全字符
    return relativePath
        .replaceAll(RegExp(r'[<>:"|?*]'), '_') // 替换Windows非法字符
        .replaceAll(RegExp(r'[\\]'), '/'); // 统一使用正斜杠
  }

  /// 检查是否有足够的磁盘空间
  /// [requiredSize] 需要的空间大小（字节）
  /// [directoryPath] 要检查的目录路径
  /// 返回：是否有足够空间
  Future<bool> hasEnoughSpace(int requiredSize, String directoryPath) async {
    try {
      // 注意：在Android上准确获取可用空间需要额外权限
      // 这里使用简化实现，在实际应用中应该使用path_provider等包
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        // 简化实现：假设有足够空间
        // 在实际应用中，这里应该调用系统API检查可用空间
        return true;
      }
      return false;
    } catch (e) {
      print('检查磁盘空间失败: $e');
      return false;
    }
  }
}