import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/openlist_service.dart'; // 修正导入路径

class SyncPage extends StatefulWidget {
  final TextEditingController addressController;
  final String? authToken;
  final String? loggedInUser;
  final bool isLoggedIn;
  final Function(String?, String?, bool) onAuthStatusChanged;

  const SyncPage({
    super.key,
    required this.addressController,
    required this.authToken,
    required this.loggedInUser,
    required this.isLoggedIn,
    required this.onAuthStatusChanged,
  });

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final TextEditingController _sourcePathController = TextEditingController();
  final TextEditingController _localPathController = TextEditingController();
  final OpenlistService _openlistService = OpenlistService();

  bool _isSyncing = false;
  bool _hasStoragePermission = false;
  final List<SyncFile> _fileList = [];
  int _totalFiles = 0;
  int _processedFiles = 0;
  String _currentFileName = '';
  
  // 同步日志相关状态
  final List<String> _syncLogs = [];
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkPermissions();
    await _initializeLocalPath();
  }

  Future<void> _checkPermissions() async {
    try {
      final storageStatus = await Permission.storage.status;
      final manageExternalStatus = await Permission.manageExternalStorage.status;
      
      if (!mounted) return;
      setState(() {
        _hasStoragePermission = storageStatus.isGranted || manageExternalStatus.isGranted;
      });
    } catch (e) {
      debugPrint('Permission check error: $e');
      if (!mounted) return;
      setState(() {
        _hasStoragePermission = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final storageStatus = await Permission.storage.request();
      final manageStatus = await Permission.manageExternalStorage.request();
      
      if (!mounted) return;
      setState(() {
        _hasStoragePermission = storageStatus.isGranted || manageStatus.isGranted;
      });
      
      if (!_hasStoragePermission) {
        _showSnackBar('需要存储权限才能同步文件');
        if (storageStatus.isPermanentlyDenied || manageStatus.isPermanentlyDenied) {
          _showPermissionDialog();
        }
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
      _showSnackBar('权限请求失败: $e');
    }
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('需要存储权限'),
          content: const Text('同步文件需要访问设备存储的权限。请授予"所有文件管理"权限。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeLocalPath() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        if (!mounted) return;
        setState(() {
          _localPathController.text = directory.path;
        });
        return;
      }
    } catch (e) {
      debugPrint('External storage not available: $e');
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      if (!mounted) return;
      setState(() {
        _localPathController.text = directory.path;
      });
    } catch (e) {
      debugPrint('Application documents directory not available: $e');
      if (!mounted) return;
      setState(() {
        _localPathController.text = '/storage/emulated/0/Download';
      });
    }
  }

  Future<void> _selectLocalPath() async {
    if (!_hasStoragePermission) {
      await _requestPermissions();
      if (!_hasStoragePermission) {
        return;
      }
    }

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择同步目录',
        initialDirectory: _localPathController.text.isNotEmpty 
            ? _localPathController.text 
            : null,
      );

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _localPathController.text = selectedDirectory;
        });
      }
    } catch (e) {
      debugPrint('Error selecting directory: $e');
      _showSnackBar('选择路径时出错: $e');
      _showFallbackPathSelector();
    }
  }

  Future<void> _showFallbackPathSelector() async {
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择存储路径'),
          content: const Text('系统文件选择器不可用，请选择预设路径或手动输入'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final directory = await getExternalStorageDirectory();
                Navigator.pop(context, directory?.path);
              },
              child: const Text('外部存储'),
            ),
            FilledButton(
              onPressed: () async {
                final directory = await getApplicationDocumentsDirectory();
                Navigator.pop(context, directory.path);
              },
              child: const Text('应用文档'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, '/storage/emulated/0/Download'),
              child: const Text('下载文件夹'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _localPathController.text = result;
      });
    }
  }

Future<void> _startSync() async {
  if (widget.addressController.text.isEmpty ||
      _sourcePathController.text.isEmpty ||
      _localPathController.text.isEmpty) {
    _showSnackBar('请填写所有必填字段');
    return;
  }

  if (!widget.isLoggedIn) {
    _showSnackBar('请先登录Openlist');
    return;
  }

  if (!_hasStoragePermission) {
    await _requestPermissions();
    if (!_hasStoragePermission) {
      _showSnackBar('需要存储权限才能同步文件');
      return;
    }
  }

  if (!mounted) return;
  setState(() {
    _isSyncing = true;
    _fileList.clear();
    _totalFiles = 0;
    _processedFiles = 0;
    _currentFileName = '';
    _syncLogs.clear();
    _addLog('开始同步文件...');
    _addLog('服务器地址: ${widget.addressController.text.trim()}');
    _addLog('源路径: ${_sourcePathController.text.trim()}');
    _addLog('本地路径: ${_localPathController.text.trim()}');
    _addLog('认证令牌: ${widget.authToken != null ? "已设置" : "未设置"}');
  });

  try {
    final result = await _openlistService.syncFolder(
      address: widget.addressController.text.trim(),
      authToken: widget.authToken,
      sourcePath: _sourcePathController.text.trim(),
      localPath: _localPathController.text.trim(),
      onProgress: (fileList, totalFiles, processedFiles, currentFileName) {
        if (!mounted) return;
        setState(() {
          _fileList.clear();
          _fileList.addAll(fileList);
          _totalFiles = totalFiles;
          _processedFiles = processedFiles;
          _currentFileName = currentFileName;
        });
      },
      onLog: _addLog,
      onTokenExpired: () { // 新增：令牌过期回调
        if (!mounted) return;
        _addLog('认证令牌已过期，需要重新登录');
        widget.onAuthStatusChanged(null, null, false);
        _showSnackBar('密码已更改，请重新登录');
      },
    );
    
    if (result) {
      _addLog('同步完成！共同步 $_totalFiles 个文件');
      _showSnackBar('同步完成！共同步 $_totalFiles 个文件');
    } else {
      _addLog('部分文件同步失败');
      _showSnackBar('部分文件同步失败，请查看日志');
    }
  } catch (e) {
    _addLog('同步出错: $e');
    
    // 更详细的错误处理
    if (e.toString().contains('密码已更改') || e is TokenExpiredException) {
      _showSnackBar('密码已更改，请重新登录');
      // 自动触发重新登录
      widget.onAuthStatusChanged(null, null, false);
    } else if (e.toString().contains('认证令牌')) {
      _showSnackBar('认证失败，请重新登录');
      // 自动触发重新登录
      widget.onAuthStatusChanged(null, null, false);
    } else {
      _showSnackBar('同步出错: $e');
    }
  } finally {
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
    });
  }
}

  void _addLog(String message) {
    if (!mounted) return;
    final timestamp = DateTime.now().toString().split('.').first;
    setState(() {
      _syncLogs.add('[$timestamp] $message');
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件同步'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!_hasStoragePermission)
            IconButton(
              icon: const Icon(Icons.warning_amber),
              onPressed: _requestPermissions,
              tooltip: '申请存储权限',
              color: Colors.orange,
            ),
          if (_syncLogs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                setState(() {
                  _showLogs = !_showLogs;
                });
              },
              tooltip: _showLogs ? '隐藏日志' : '显示日志',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 登录状态卡片
            Card(
              color: widget.isLoggedIn ? Colors.green[50] : Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      widget.isLoggedIn ? Icons.check_circle : Icons.info,
                      color: widget.isLoggedIn ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isLoggedIn ? '已登录' : '未登录',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isLoggedIn ? Colors.green[800] : Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isLoggedIn 
                                ? '当前用户: ${widget.loggedInUser}'
                                : '请先登录Openlist服务器',
                            style: TextStyle(
                              color: widget.isLoggedIn ? Colors.green[700] : Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_hasStoragePermission) ...[
              _buildPermissionWarning(),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '同步设置',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _sourcePathController,
                            label: 'Openlist 源路径 *',
                            hintText: '/folder/example',
                            icon: Icons.folder_open,
                          ),
                          const SizedBox(height: 16),
                          _buildLocalPathField(),
                          const SizedBox(height: 24),
                          if (_isSyncing && _totalFiles > 0) ...[
                            _buildProgressIndicator(),
                            const SizedBox(height: 16),
                          ],
                          if (_fileList.isNotEmpty && !_isSyncing) ...[
                            _buildFileListPreview(),
                            const SizedBox(height: 16),
                          ],
                          if (_syncLogs.isNotEmpty && _showLogs) ...[
                            _buildSyncLogs(),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSyncButton(),
          ],
        ),
      ),
    );
  }

  // ... 其余构建方法保持不变 (为节省篇幅省略)
  Widget _buildPermissionWarning() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '需要存储权限',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '同步文件需要"所有文件管理"权限',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: _requestPermissions,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('授权'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildLocalPathField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '本地路径 *',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _localPathController,
                decoration: const InputDecoration(
                  hintText: '手机存储路径',
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _selectLocalPath,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open),
                  SizedBox(width: 4),
                  Text('选择'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '同步进度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _totalFiles > 0 ? _processedFiles / _totalFiles : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_processedFiles / $_totalFiles 个文件',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${((_processedFiles / _totalFiles) * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (_currentFileName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '正在处理: $_currentFileName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileListPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '发现的文件',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '共 ${_fileList.length} 个文件',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_fileList.length > 5) ...[
              const SizedBox(height: 8),
              const Text('前5个文件:'),
              ..._fileList.take(5).map((file) => Text(
                '  • ${file.fsObject.name}',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              )).toList(),
              if (_fileList.length > 5) ...[
                Text(
                  '  ... 还有 ${_fileList.length - 5} 个文件',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ] else if (_fileList.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._fileList.map((file) => Text(
                '  • ${file.fsObject.name}',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncLogs() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '同步日志',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showLogs = false;
                    });
                  },
                  tooltip: '隐藏日志',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _syncLogs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      _syncLogs[index],
                      style: const TextStyle(fontSize: 12, fontFamily: 'Monospace'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: (_isSyncing || !widget.isLoggedIn || !_hasStoragePermission) ? null : _startSync,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSyncing
            ? const Row(
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
                  Text('同步中...'),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync),
                  const SizedBox(width: 8),
                  Text(!_hasStoragePermission ? '需要权限' : (widget.isLoggedIn ? '开始同步' : '请先登录')),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _sourcePathController.dispose();
    _localPathController.dispose();
    super.dispose();
  }
}