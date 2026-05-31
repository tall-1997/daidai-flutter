import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'dart:async';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _commandController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _output = [];
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  bool _isExecuting = false;
  bool _isWebSocketConnected = false;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _initWebSocket();
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _initWebSocket() {
    // WebSocket initialization would go here
    // For now, we'll use HTTP API
    setState(() {
      _isWebSocketConnected = false;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _navigateHistory(int direction) {
    if (_commandHistory.isEmpty) return;

    setState(() {
      _historyIndex += direction;
      if (_historyIndex < 0) _historyIndex = 0;
      if (_historyIndex >= _commandHistory.length) {
        _historyIndex = _commandHistory.length - 1;
      }
      _commandController.text = _commandHistory[_historyIndex];
      _commandController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commandController.text.length),
      );
    });
  }

  Future<void> _executeCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    // Handle clear command locally
    if (command == 'clear' || command == 'cls') {
      setState(() {
        _output.clear();
        _commandController.clear();
      });
      return;
    }

    // Add to history
    if (_commandHistory.isEmpty || _commandHistory.last != command) {
      _commandHistory.add(command);
    }
    _historyIndex = _commandHistory.length;

    setState(() {
      _output.add({
        'command': command,
        'status': 'running',
        'output': '',
        'timestamp': DateTime.now().toString(),
        'startTime': DateTime.now().millisecondsSinceEpoch,
      });
      _isExecuting = true;
      _commandController.clear();
    });

    _scrollToBottom();

    try {
      final authService = context.read<AuthService>();
      final api = authService.apiService;

      final response = await api.post('/system/execute', body: {'command': command});

      if (mounted) {
        final endTime = DateTime.now().millisecondsSinceEpoch;
        final startTime = _output.last['startTime'] as int;
        final duration = endTime - startTime;

        setState(() {
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final output = data['output'] ?? data['data']?['output'] ?? '命令已执行';
            _output.last['output'] = output.toString().trim();
            _output.last['status'] = 'success';
          } else {
            _output.last['output'] = '执行失败: HTTP ${response.statusCode}';
            _output.last['status'] = 'error';
          }
          _output.last['duration'] = duration;
          _isExecuting = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final endTime = DateTime.now().millisecondsSinceEpoch;
        final startTime = _output.last['startTime'] as int;
        final duration = endTime - startTime;

        setState(() {
          _output.last['output'] = '执行错误: $e';
          _output.last['status'] = 'error';
          _output.last['duration'] = duration;
          _isExecuting = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('在线终端'),
        actions: [
          // Command count badge
          if (_output.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_output.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          IconButton(
            icon: Icon(_isWebSocketConnected ? Icons.cloud_done : Icons.cloud_off),
            color: _isWebSocketConnected ? Colors.green : Colors.grey,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isWebSocketConnected ? 'WebSocket已连接' : 'WebSocket未连接')),
              );
            },
            tooltip: _isWebSocketConnected ? 'WebSocket已连接' : 'WebSocket未连接',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => _output.clear()),
            tooltip: '清空输出',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick commands
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '快捷命令',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildQuickCommand('ls', 'ls -la'),
                    _buildQuickCommand('pwd', 'pwd'),
                    _buildQuickCommand('date', 'date'),
                    _buildQuickCommand('uname', 'uname -a'),
                    _buildQuickCommand('df', 'df -h'),
                    _buildQuickCommand('free', 'free -h'),
                    _buildQuickCommand('ps', 'ps aux | head -20'),
                    _buildQuickCommand('top', 'top -bn1 | head -20'),
                    _buildQuickCommand('netstat', 'netstat -tlnp'),
                    _buildQuickCommand('whoami', 'whoami'),
                    _buildQuickCommand('uptime', 'uptime'),
                    _buildQuickCommand('ip', 'ip addr show'),
                    _buildQuickCommand('disk', 'du -sh /* 2>/dev/null | sort -hr | head -10'),
                    _buildQuickCommand('memory', 'cat /proc/meminfo | head -10'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Output
          Expanded(
            child: Container(
              color: Colors.black87,
              child: _output.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.terminal, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            '输入命令开始执行',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '支持 ↑↓ 键浏览历史命令',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _output.length,
                      itemBuilder: (context, index) {
                        final item = _output[index];
                        final duration = item['duration'] as int?;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Command header
                            Row(
                              children: [
                                const Text('\$ ', style: TextStyle(color: Colors.green, fontFamily: 'monospace')),
                                Expanded(
                                  child: Text(
                                    item['command'],
                                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                                  ),
                                ),
                                if (item['status'] == 'running')
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                                  ),
                                if (duration != null)
                                  Text(
                                    '${duration}ms',
                                    style: TextStyle(
                                      color: item['status'] == 'error' ? Colors.red : Colors.grey,
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                    ),
                                  ),
                                if (item['status'] == 'success')
                                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                                if (item['status'] == 'error')
                                  const Icon(Icons.error, color: Colors.red, size: 14),
                              ],
                            ),
                            // Output
                            if (item['output'].isNotEmpty)
                              GestureDetector(
                                onLongPress: () {
                                  // Copy output to clipboard
                                  final data = ClipboardData(text: item['output']);
                                  Clipboard.setData(data);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('已复制到剪贴板'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                                  child: Text(
                                    item['output'],
                                    style: TextStyle(
                                      color: item['status'] == 'error' ? Colors.red : Colors.white70,
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            // Divider between commands
                            if (index < _output.length - 1)
                              const Divider(height: 1, color: Colors.grey),
                          ],
                        );
                      },
                    ),
            ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[900],
            child: Row(
              children: [
                const Text('\$ ', style: TextStyle(color: Colors.green, fontFamily: 'monospace')),
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          _navigateHistory(-1);
                        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          _navigateHistory(1);
                        }
                      }
                    },
                    child: TextField(
                      controller: _commandController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: '输入命令... (↑↓ 历史记录)',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: _commandHistory.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.history, color: Colors.grey, size: 18),
                                onPressed: () => _showHistoryDialog(),
                                tooltip: '命令历史',
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _executeCommand(),
                      enabled: !_isExecuting,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isExecuting ? Icons.hourglass_empty : Icons.send),
                  color: Colors.green,
                  onPressed: _isExecuting ? null : _executeCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommand(String label, String command) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _commandController.text = command;
        _executeCommand();
      },
    );
  }

  void _showHistoryDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '命令历史',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _commandHistory.clear();
                      _historyIndex = -1;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('清空', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _commandHistory.length,
                itemBuilder: (context, index) {
                  final command = _commandHistory[_commandHistory.length - 1 - index];
                  return ListTile(
                    leading: const Icon(Icons.terminal, size: 20),
                    title: Text(
                      command,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    onTap: () {
                      _commandController.text = command;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
