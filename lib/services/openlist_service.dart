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
      final dirInfo = await _getDirectoryInfo(address, authToken, sourcePath);
      if (dirInfo == null || !dirInfo.isDir) {
        throw Exception('源路径不是一个有效的目录');
      }

      // 递归获取所有文件
      onLog('正在扫描目录结构...');
      await _getAllFilesRecursive(address, authToken, sourcePath, sourcePath, fileList);

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
      for (int i = 0; i < fileList.length; i++) {
        final file = fileList[i];
        currentFileName = file.fsObject.name;
        onLog('正在下载: $currentFileName');
        
        final success = await _downloadFile(
          address: address,
          authToken: authToken,
          syncFile: file,
          localPath: localPath,
        );
        
        if (success) {
          successCount++;
          onLog('下载完成: $currentFileName');
        } else {
          onLog('下载失败: $currentFileName');
        }
        
        processedFiles = i + 1;
        onProgress(fileList, totalFiles, processedFiles, currentFileName);
      }

      return successCount == fileList.length;
    } catch (e) {
      onLog('同步失败: $e');
      throw e;
    }
  }

  Future<FsObject?> _getDirectoryInfo(String address, String? authToken, String dirPath) async {
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
          throw Exception('API错误: ${data['message']}');
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取目录信息失败: $e');
    }
  }

  Future<void> _getAllFilesRecursive(
    String address,
    String? authToken,
    String currentVirtualPath,
    String basePath,
    List<SyncFile> fileList,
  ) async {
    try {
      final contents = await _listDirectory(address, authToken, currentVirtualPath);
      
      for (final item in contents) {
        final newVirtualPath = _buildVirtualPath(currentVirtualPath, item.name);
        
        if (item.isDir) {
          await _getAllFilesRecursive(address, authToken, newVirtualPath, basePath, fileList);
        } else {
          final relativePath = _getRelativePath(newVirtualPath, basePath);
          
          fileList.add(SyncFile(
            fsObject: FsObject(
              id: item.id,
              path: newVirtualPath,
              name: item.name,
              size: item.size,
              isDir: item.isDir,
              modified: item.modified,
              created: item.created,
              sign: item.sign,
              thumb: item.thumb,
              type: item.type,
            ),
            relativePath: relativePath,
          ));
        }
      }
    } catch (e) {
      // 不抛出异常，继续处理其他目录
    }
  }

  Future<List<FsObject>> _listDirectory(String address, String? authToken, String dirPath) async {
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
          throw Exception('API错误: ${data['message']}');
        }
      } else {
        throw Exception('HTTP错误: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取目录内容失败: $e');
    }
  }

  Future<bool> _downloadFile({
    required String address,
    required String? authToken,
    required SyncFile syncFile,
    required String localPath,
  }) async {
    try {
      final file = syncFile.fsObject;
      
      final downloadUrl = Uri.parse('http://$address/api/fs/file');
      final queryParams = {
        'path': file.path,
        if (file.sign != null && file.sign!.isNotEmpty) 'sign': file.sign,
      };

      final headers = {
        if (authToken != null) 'Authorization': authToken,
      };

      final response = await http.get(
        downloadUrl.replace(queryParameters: queryParams),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final localFilePath = path.join(localPath, syncFile.relativePath);
        
        final localFileDir = Directory(path.dirname(localFilePath));
        if (!await localFileDir.exists()) {
          await localFileDir.create(recursive: true);
        }

        final localFile = File(localFilePath);
        await localFile.writeAsBytes(response.bodyBytes);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
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