import 'package:flutter/material.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = '0.0.2 - Beta 2'; // 应用版本
  int _clickCount = 0; // 点击计数器
  bool _showHiddenText = false; // 是否显示隐藏文本

  void _handleCardTap() {
    setState(() {
      _clickCount++;
      
      // 点击5次后显示隐藏文本
      if (_clickCount >= 5 && !_showHiddenText) {
        _showHiddenText = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('你知道的太多了！'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 应用图标和名称
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              /*child: Icon(
                Icons.cloud_sync,
                color: Colors.white,
                size: 40,
              ),*/
            ),
            const SizedBox(height: 16),
            Text(
              'Openlist 同步器',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '版本 ' + _appVersion,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 应用介绍卡片
            GestureDetector(
              onTap: _handleCardTap,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '应用介绍',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Openlist 同步器（Openlist Syncer）是一个专为 Openlist 服务器设计的文件同步应用。\n'
                        '它可以帮助您轻松地（也许）将服务器上的文件同步到本地设备。',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.justify,
                      ),
                      // 点击5次后显示的隐藏文本
                      if (_showHiddenText) ...[
                        const SizedBox(height: 12),
                        Text(
                          '事情的起因是我不想用某软件的收费的同步服务……\n'
                          '诶，同步不就是把一台设备的数据文件发送到另一台设备的相应位置吗？\n'
                          '那我一台设备运行个网盘，当服务器用……\n'
                          '…………\n'
                          '手动下载太麻烦了，要不自动化一下吧……\n'
                          '…………\n'
                          '然后越写越多就变成这样了。',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                      // 可选：添加点击计数提示（调试用）
                      /* if (!_showHiddenText && _clickCount > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '点击次数: $_clickCount/5',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],*/
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 功能特性卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主要功能',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context,
                      icon: Icons.cloud_download,
                      title: '文件同步',
                      description: '支持从 Openlist 服务器同步文件和文件夹',
                    ),
                    _buildFeatureItem(
                      context,
                      icon: Icons.security,
                      title: '安全认证',
                      description: '支持用户名密码和两步验证登录',
                    ),
                    _buildFeatureItem(
                      context,
                      icon: Icons.speed,
                      title: '进度跟踪',
                      description: '实时显示同步进度和详细日志',
                    ),
                    _buildFeatureItem(
                      context,
                      icon: Icons.folder_open,
                      title: '路径选择',
                      description: '灵活选择本地存储路径',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 技术信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '技术信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(context, '框架', 'Flutter'),
                    _buildInfoItem(context, '目标平台', 'Android'),
                    //_buildInfoItem(context, '最小SDK', 'API 21 (Android 5.0)'),
                    _buildInfoItem(context, '开发语言', 'Dart'),
                  ],
                ),
              ),
            ),
            

            const SizedBox(height: 16),
            
            // 许可证信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '许可证信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Openlist Syncer 是基于 AGPL-3.0 许可证发布的自由软件。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '您有权在遵守AGPL-3.0条款的前提下使用、修改和分发本软件。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    // 添加查看完整许可证的按钮
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          showLicensePage(
                            context: context,
                            applicationName: 'Openlist Syncer',
                            applicationVersion: _appVersion,
                            applicationLegalese: 'Licensed under GNU Affero General Public License v3.0',
                          );
                        },
                        child: const Text('查看完整许可证'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 许可和版权信息
            Text(
              'GNU Affero General Public License v3.0 Licensed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            
            Text(
              '版权所有 © 2025 域空 Hollow。保留所有权利。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Copyright © 2025 域空Hollow. All Rights Reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建功能特性项
  Widget _buildFeatureItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建信息项
  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}