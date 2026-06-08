import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/miuix_theme.dart';
import '../widgets/miuix_widgets.dart';

class LogDetailSheet extends StatefulWidget {
  final Map<String, dynamic> log;
  final ScrollController scrollController;

  const LogDetailSheet({
    super.key,
    required this.log,
    required this.scrollController,
  });

  @override
  State<LogDetailSheet> createState() => _LogDetailSheetState();
}

class _LogDetailSheetState extends State<LogDetailSheet> {
  final ScrollController _logContentScrollController = ScrollController();

  String _cleanContent(dynamic rawContent) => MiuixLogUtils.cleanContent(rawContent?.toString());

  @override
  void dispose() {
    _logContentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final taskName = log['task_name'] ?? log['task']?['name'] ?? log['taskName'] ?? '未知任务';
    final content = log['content'] ?? log['output'] ?? log['message'] ?? '';
    final status = log['status'] ?? 0;
    final createdAt = log['created_at'] ?? log['createdAt'] ?? '';
    final startedAt = log['started_at'] ?? log['startedAt'] ?? '';
    final endedAt = log['ended_at'] ?? log['endedAt'] ?? '';
    final duration = log['duration'] ?? log['execution_time'] ?? 0;
    final taskType = log['task_type'] ?? log['task']?['task_type'] ?? log['taskType'] ?? '';
    final taskId = log['task_id'] ?? log['taskId'] ?? '';
    final logId = log['id'] ?? '';
    final errorMsg = log['error'] ?? log['error_message'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    String statusText;
    switch (status) {
      case 0:
        statusColor = Colors.green;
        statusText = '成功';
        break;
      case 1:
        statusColor = Colors.red;
        statusText = '失败';
        break;
      case 2:
        statusColor = Colors.orange;
        statusText = '运行中';
        break;
      default:
        statusColor = Colors.grey;
        statusText = '未知';
    }

    String durationText = '';
    if (duration is num && duration > 0) {
      if (duration < 1000) {
        durationText = '${duration}ms';
      } else if (duration < 60000) {
        durationText = '${(duration / 1000).toStringAsFixed(1)}s';
      } else {
        durationText = '${(duration / 60000).toStringAsFixed(1)}min';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? MiuixColors.darkOutline : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  taskName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('日志ID', logId.toString(), isDark),
          _buildDetailRow('任务ID', taskId.toString(), isDark),
          _buildDetailRow('任务类型', taskType.toString(), isDark),
          _buildDetailRow('创建时间', createdAt.toString(), isDark),
          _buildDetailRow('开始时间', startedAt.toString().isEmpty ? '无' : startedAt.toString(), isDark),
          _buildDetailRow('结束时间', endedAt.toString().isEmpty ? '无' : endedAt.toString(), isDark),
          _buildDetailRow('执行耗时', durationText.isEmpty ? '无' : durationText, isDark),
          if (errorMsg.toString().isNotEmpty) _buildDetailRow('错误信息', _cleanContent(errorMsg), isDark),
          const Divider(height: 32),
          Row(
            children: [
              Text(
                '执行日志',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _cleanContent(content)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('日志已复制'), backgroundColor: Colors.green),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? MiuixColors.darkSurfaceContainerHighest : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Scrollbar(
              controller: _logContentScrollController,
              thumbVisibility: true,
              thickness: 8.0,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                controller: _logContentScrollController,
                child: SelectableText(
                  _cleanContent(content).isEmpty ? '无日志内容' : _cleanContent(content),
                  style: MiuixTextStyles.monospace.copyWith(
                    color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? MiuixColors.darkOnSurfaceVariantSummary : MiuixColors.onSurfaceVariantSummary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showLogDetail(BuildContext context, Map<String, dynamic> log) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => LogDetailSheet(
        log: log,
        scrollController: scrollController,
      ),
    ),
  );
}
