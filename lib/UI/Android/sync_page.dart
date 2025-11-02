import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // 文件选择器
import 'package:permission_handler/permission_handler.dart'; // 权限处理
import 'package:path_provider/path_provider.dart'; // 路径提供器
import '../../services/openlist_service.dart'; // 导入Openlist服务

// 同步页面组件
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

// 同步页面状态类
class _SyncPageState extends State<SyncPage> {
  final TextEditingController _sourcePathController = TextEditingController(); // 源路径控制器
  final TextEditingController _localPathController = TextEditingController(); // 本地路径控制器
  final OpenlistService _openlistService = OpenlistService(); // Openlist服务实例

  bool _isSyncing = false; // 同步状态标识
  bool _hasStoragePermission = false; // 存储权限状态
  final List<SyncFile> _fileList = []; // 文件列表
  int _totalFiles = 0; // 总文件数
  int _processedFiles = 0; // 已处理文件数
  String _currentFileName = ''; // 当前文件名
  
  // 同步日志相关状态
  final List<String> _syncLogs = []; // 日志列表
  bool _showLogs = false; // 是否显示日志

  @override
  void initState() {
    super.initState();
    _initializeApp(); // 初始化应用
  }

  // 初始化应用
  Future<void> _initializeApp() async {
    await _checkPermissions(); // 检查权限
    await _initializeLocalPath(); // 初始化本地路径
  }

  // 检查权限
  Future<void> _checkPermissions() async {
    try {
      final storageStatus = await Permission.storage.status; // 存储权限状态
      final manageExternalStatus = await Permission.manageExternalStorage.status; // 外部存储管理权限
      
      if (!mounted) return;
      setState(() {
        _hasStoragePermission = storageStatus.isGranted || manageExternalStatus.isGranted; // 任一权限授予即可
      });
    } catch (e) {
      debugPrint('Permission check error: $e');
      if (!mounted) return;
      setState(() {
        _hasStoragePermission = false;
      });
    }
  }

  // 请求权限
  Future<void> _requestPermissions() async {
    try {
      final storageStatus = await Permission.storage.request(); // 请求存储权限
      final manageStatus = await Permission.manageExternalStorage.request(); // 请求外部存储管理权限
      
      if (!mounted) return;
      setState(() {
        _hasStoragePermission = storageStatus.isGranted || manageStatus.isGranted;
      });
      
      if (!_hasStoragePermission) {
        _showSnackBar('需要存储权限才能同步文件');
        if (storageStatus.isPermanentlyDenied || manageStatus.isPermanentlyDenied) {
          _showPermissionDialog(); // 显示权限请求对话框
        }
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
      _showSnackBar('权限请求失败: $e');
    }
  }

  // 显示权限请求对话框
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
              onPressed: () => Navigator.of(context).pop(), // 取消
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // 打开应用设置
              },
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
  }

  // 初始化本地路径
  Future<void> _initializeLocalPath() async {
    try {
      final directory = await getExternalStorageDirectory(); // 获取外部存储目录
      if (directory != null) {
        if (!mounted) return;
        setState(() {
          _localPathController.text = directory.path; // 设置外部存储路径
        });
        return;
      }
    } catch (e) {
      debugPrint('External storage not available: $e');
    }
    
    try {
      final directory = await getApplicationDocumentsDirectory(); // 获取应用文档目录
      if (!mounted) return;
      setState(() {
        _localPathController.text = directory.path; // 设置应用文档路径
      });
    } catch (e) {
      debugPrint('Application documents directory not available: $e');
      if (!mounted) return;
      setState(() {
        _localPathController.text = '/storage/emulated/0/Download'; // 默认下载路径
      });
    }
  }

  // 选择本地路径
  Future<void> _selectLocalPath() async {
    if (!_hasStoragePermission) {
      await _requestPermissions(); // 先请求权限
      if (!_hasStoragePermission) {
        return;
      }
    }

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择同步目录', // 对话框标题
        initialDirectory: _localPathController.text.isNotEmpty 
            ? _localPathController.text 
            : null, // 初始目录
      );

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _localPathController.text = selectedDirectory; // 更新本地路径
        });
      }
    } catch (e) {
      debugPrint('Error selecting directory: $e');
      _showSnackBar('选择路径时出错: $e');
      _showFallbackPathSelector(); // 显示备选路径选择器
    }
  }

  // 显示备选路径选择器
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
                Navigator.pop(context, directory?.path); // 返回外部存储路径
              },
              child: const Text('外部存储'),
            ),
            FilledButton(
              onPressed: () async {
                final directory = await getApplicationDocumentsDirectory();
                Navigator.pop(context, directory.path); // 返回应用文档路径
              },
              child: const Text('应用文档'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, '/storage/emulated/0/Download'), // 返回下载路径
              child: const Text('下载文件夹'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _localPathController.text = result; // 更新路径
      });
    }
  }

  // 开始同步
  Future<void> _startSync() async {
    // 验证输入字段
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
      _isSyncing = true; // 开始同步
      _fileList.clear(); // 清空文件列表
      _totalFiles = 0;
      _processedFiles = 0;
      _currentFileName = '';
      _syncLogs.clear(); // 清空日志
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
            _fileList.addAll(fileList); // 更新文件列表
            _totalFiles = totalFiles;
            _processedFiles = processedFiles;
            _currentFileName = currentFileName;
          });
        },
        onLog: _addLog, // 日志回调
        onTokenExpired: () { // 令牌过期回调
          if (!mounted) return;
          _addLog('认证令牌已过期，需要重新登录');
          widget.onAuthStatusChanged(null, null, false); // 清除认证状态
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
        _isSyncing = false; // 结束同步
      });
    }
  }

  // 添加日志
  void _addLog(String message) {
    if (!mounted) return;
    final timestamp = DateTime.now().toString().split('.').first; // 时间戳
    setState(() {
      _syncLogs.add('[$timestamp] $message'); // 添加带时间戳的日志
    });
  }

  // 显示提示消息
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
          if (!_hasStoragePermission) // 没有权限时显示警告图标
            IconButton(
              icon: const Icon(Icons.warning_amber),
              onPressed: _requestPermissions,
              tooltip: '申请存储权限',
              color: Colors.orange,
            ),
          if (_syncLogs.isNotEmpty) // 有日志时显示历史图标
            IconButton(
              icon: const Icon(Icons.article_outlined),
              onPressed: () {
                setState(() {
                  _showLogs = !_showLogs; // 切换日志显示状态
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
            if (!_hasStoragePermission) ...[ // 没有权限时显示警告
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
                                  color: Colors.green[100], // 绿色标签
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
                          _buildInputField( // 源路径输入字段
                            controller: _sourcePathController,
                            label: 'Openlist 源路径 *',
                            hintText: '/folder/example',
                            icon: Icons.folder_open,
                          ),
                          const SizedBox(height: 16),
                          _buildLocalPathField(), // 本地路径字段
                        ],
                      ),
                    ),
                  ),
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
                                  color: Colors.green[100], // 绿色标签
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '同步信息',
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (!_fileList.isNotEmpty && !_isSyncing) ...[ // 同步开始前显示提示
                            const Text(
                              '请先开始同步',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_isSyncing) ...[ // 同步中显示提示
                            if(_totalFiles > 0) ...[
                              const Text(
                                '正在同步...',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              const Text(
                                '正在准备同步...',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                          if (_fileList.isNotEmpty && !_isSyncing) ...[ // 同步完成显示提示
                            const Text(
                              '同步完成',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_isSyncing && _totalFiles > 0) ...[ // 同步中显示进度
                            _buildProgressIndicator(),
                            const SizedBox(height: 16),
                          ],
                          if (_syncLogs.isNotEmpty && _showLogs) ...[ // 显示日志
                            _buildSyncLogs(),
                            const SizedBox(height: 16),
                          ],
                          if (_fileList.isNotEmpty && !_isSyncing) ...[ // 同步完成显示文件列表
                            _buildFileListPreview(),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSyncButton(), // 同步按钮
          ],
        ),
      ),
    );
  }

  // 构建权限警告组件
  Widget _buildPermissionWarning() {
    return Card(
      color: Colors.orange[50], // 橙色警告背景
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
            FilledButton.tonal( // 授权按钮
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

  // 构建通用输入字段
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

  // 构建本地路径字段
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
                readOnly: true, // 只读，通过按钮选择
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

  // 构建进度指示器
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
            LinearProgressIndicator( // 线性进度条
              value: _totalFiles > 0 ? _processedFiles / _totalFiles : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary, // 使用主题色
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_processedFiles / $_totalFiles 个文件', // 文件计数
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${((_processedFiles / _totalFiles) * 100).toStringAsFixed(1)}%', // 百分比
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (_currentFileName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '正在处理: $_currentFileName', // 当前文件名
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis, // 溢出省略
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 构建文件列表预览
  Widget _buildFileListPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '同步的文件',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '共 ${_fileList.length} 个文件', // 文件总数
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_fileList.length > 50) ...[ // 文件较多时显示前5个
              const SizedBox(height: 8),
              const Text('包含:'),
              ..._fileList.take(5).map((file) => Text(
                '  • ${file.fsObject.name}', // 文件名
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              )).toList(),
              if (_fileList.length > 5) ...[
                Text(
                  '  ... 与其它 ${_fileList.length - 50} 个文件', // 剩余文件数
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ] else if (_fileList.isNotEmpty) ...[ // 文件较少时显示全部
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

  // 构建同步日志
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
                const Spacer(), // 占位空间
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showLogs = false; // 隐藏日志
                    });
                  },
                  tooltip: '隐藏日志',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200, // 固定高度
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
                      style: const TextStyle(fontSize: 12, fontFamily: 'Monospace'), // 等宽字体
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

  // 构建同步按钮
  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity, // 宽度填满
      child: FilledButton(
        onPressed: (_isSyncing || !widget.isLoggedIn || !_hasStoragePermission) ? null : _startSync, // 条件禁用
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSyncing
            ? const Row( // 同步中状态
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator( // 加载指示器
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('同步中...'),
                ],
              )
            : Row( // 正常状态
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync),
                  const SizedBox(width: 8),
                  Text(!_hasStoragePermission ? '需要权限' : (widget.isLoggedIn ? '开始同步' : '请先登录')), // 动态文本
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _sourcePathController.dispose(); // 销毁控制器
    _localPathController.dispose();
    super.dispose();
  }
}