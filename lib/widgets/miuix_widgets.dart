import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/miuix_theme.dart';

// ==================== Miuix Dialog Components ====================

Future<T?> showMiuixDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

Future<T?> showMiuixConfirmDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '确认',
  String cancelText = '取消',
  Color? confirmColor,
  bool isDestructive = false,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: confirmColor != null
              ? FilledButton.styleFrom(backgroundColor: confirmColor)
              : isDestructive
                  ? FilledButton.styleFrom(backgroundColor: MiuixColors.error)
                  : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

Future<void> showMiuixExportDialog({
  required BuildContext context,
  required String title,
  required String content,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SelectableText(content, style: MiuixTextStyles.monospace),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: content));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已复制到剪贴板'), backgroundColor: Colors.green),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('复制'),
        ),
      ],
    ),
  );
}

// ==================== Miuix Detail Row ====================

class MiuixDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const MiuixDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: MiuixTextStyles.body2.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? MiuixColors.darkOnSurfaceVariantSummary
                    : MiuixColors.onSurfaceVariantSummary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: MiuixTextStyles.body2.copyWith(
                color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Miuix Code Block ====================

class MiuixCodeBlock extends StatefulWidget {
  final String content;
  final double? maxHeight;

  const MiuixCodeBlock({super.key, required this.content, this.maxHeight});

  @override
  State<MiuixCodeBlock> createState() => _MiuixCodeBlockState();
}

class _MiuixCodeBlockState extends State<MiuixCodeBlock> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: widget.maxHeight != null ? BoxConstraints(maxHeight: widget.maxHeight!) : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? MiuixColors.darkSurfaceContainerHighest : MiuixColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 8.0,
        radius: const Radius.circular(4),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SelectableText(widget.content, style: MiuixTextStyles.monospace),
        ),
      ),
    );
  }
}

// ==================== Miuix Log Utils ====================

class MiuixLogUtils {
  static String cleanContent(String? content) {
    if (content == null || content.isEmpty) return '';

    // Try base64 decode
    String decoded = content;
    try {
      final bytes = base64Decode(content);
      decoded = decompressBytes(bytes);
    } catch (_) {
      // Not base64, use as-is
    }

    return stripAnsi(decoded);
  }

  static String decompressBytes(List<int> bytes) {
    if (bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      try {
        return utf8.decode(GZipCodec().decode(bytes), allowMalformed: true);
      } catch (_) {}
    }
    if (bytes.length > 2 && bytes[0] == 0x78) {
      try {
        return utf8.decode(ZLibCodec().decode(bytes), allowMalformed: true);
      } catch (_) {}
    }
    try {
      return utf8.decode(ZLibCodec().decode(bytes), allowMalformed: true);
    } catch (_) {}
    try {
      return utf8.decode(GZipCodec().decode(bytes), allowMalformed: true);
    } catch (_) {}
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String stripAnsi(String str) {
    str = str.replaceAll(RegExp(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])'), '');
    str = str.replaceAll(RegExp(r'\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)'), '');
    str = str.replaceAll(RegExp(r'\[(?:\d+;)*\d+[A-Za-z]'), '');
    str = str.replaceAll(RegExp(r'\[\d+m'), '');
    str = str.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
    return str.trim();
  }
}

// ==================== Miuix Format Utils ====================

class MiuixFormatUtils {
  static String formatDuration(dynamic duration) {
    if (duration == null || duration == 0) return '';
    final ms = duration is int ? duration : (duration as num).toInt();
    if (ms < 1000) return '${ms}ms';
    if (ms < 60000) return '${(ms / 1000).toStringAsFixed(1)}s';
    return '${(ms / 60000).toStringAsFixed(1)}min';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static (Color, String) getStatusColorText(dynamic status, {String type = 'task'}) {
    if (type == 'task') {
      final statusNum = status is int ? status.toDouble() : (status ?? 0.0);
      if (statusNum == 0) return (Colors.grey, '禁用');
      if (statusNum == 1) return (Colors.green, '启用');
      if (statusNum == 2) return (MiuixColors.primary, '运行中');
      if (statusNum > 0 && statusNum < 1) return (Colors.orange, '排队中');
      return (Colors.grey, '未知');
    } else if (type == 'log') {
      if (status == 0) return (Colors.green, '成功');
      if (status == 1) return (MiuixColors.error, '失败');
      if (status == 2) return (Colors.orange, '运行中');
      return (Colors.grey, '未知');
    } else if (type == 'dep') {
      switch (status) {
        case 'installed': return (Colors.green, '已安装');
        case 'installing': return (Colors.orange, '安装中');
        case 'queued': return (MiuixColors.primary, '排队中');
        case 'failed': return (MiuixColors.error, '失败');
        case 'removing': return (Colors.orange, '卸载中');
        case 'cancelled': return (Colors.grey, '已取消');
        default: return (Colors.grey, status?.toString() ?? '未知');
      }
    }
    return (Colors.grey, '未知');
  }
}

// ==================== Existing Widgets ====================

class MiuixCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const MiuixCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? MiuixColors.darkSurfaceContainer : MiuixColors.surfaceContainer);
    final borderColor = isDark ? MiuixColors.darkOutline : MiuixColors.outline;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(MiuixSpacing.cardCornerRadius),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(MiuixSpacing.cardCornerRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MiuixSpacing.cardCornerRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }
}

class MiuixSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const MiuixSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: MiuixTextStyles.headline2.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class MiuixStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;

  const MiuixStatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? color,
        ),
      ),
    );
  }
}

class MiuixEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const MiuixEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark
                  ? MiuixColors.darkOnSurfaceContainerVariant
                  : MiuixColors.onSurfaceContainerVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: MiuixTextStyles.headline2.copyWith(
                color: isDark
                    ? MiuixColors.darkOnSurfaceVariantSummary
                    : MiuixColors.onSurfaceVariantSummary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: MiuixTextStyles.body2.copyWith(
                  color: isDark
                      ? MiuixColors.darkOnSurfaceVariantActions
                      : MiuixColors.onSurfaceVariantActions,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class MiuixLoadingState extends StatelessWidget {
  final String? message;

  const MiuixLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: MiuixTextStyles.body2.copyWith(
                color: MiuixColors.onSurfaceVariantSummary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MiuixErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const MiuixErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: MiuixColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: MiuixTextStyles.body1.copyWith(
                color: MiuixColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MiuixInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const MiuixInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark
                  ? MiuixColors.darkOnSurfaceVariantSummary
                  : MiuixColors.onSurfaceVariantSummary,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: MiuixTextStyles.body2.copyWith(
                color: isDark
                    ? MiuixColors.darkOnSurfaceVariantSummary
                    : MiuixColors.onSurfaceVariantSummary,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: MiuixTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? MiuixColors.darkOnSurface : MiuixColors.onSurface,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
