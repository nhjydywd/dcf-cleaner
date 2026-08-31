import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dcf_cleaner/l10n/app_localizations.dart';

import '../ai/ai_config.dart';
import '../ai/ai_config_dialog.dart';
import '../ai/ai_suggest.dart' as ai;
import '../fs/fs_item.dart';
import '../widgets/dashed_border.dart';

class DetailPanel extends StatefulWidget {
  const DetailPanel({
    super.key,
    required this.selected,
  });

  final FSItem? selected;

  @override
  State<DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends State<DetailPanel> {
  Future<FileStat>? _statFuture;
  String? _path;

  @override
  void initState() {
    super.initState();
    _kickoff();
  }

  @override
  void didUpdateWidget(covariant DetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPath = widget.selected?.path;
    if (nextPath != _path) {
      _kickoff();
    }
  }

  void _kickoff() {
    final item = widget.selected;
    _path = item?.path;
    _statFuture = _path == null ? null : FileStat.stat(_path!);
  }

  String _typeText(AppLocalizations l10n, FileSystemEntityType type) {
    return switch (type) {
      FileSystemEntityType.file => l10n.detailTypeFile,
      FileSystemEntityType.directory => l10n.detailTypeDirectory,
      FileSystemEntityType.link => l10n.detailTypeLink,
      _ => l10n.detailTypeOther,
    };
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              v,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.selected;
    if (item == null) return const SizedBox.shrink();

    final sizeBase = formatSizeBytes(item.sizeBytes);
    final computedSizeText = item.isDirectory && !item.isSizeConfirmed ? '>$sizeBase' : sizeBase;

    Future<void> onAiSuggest() async {
      final repo = AiConfigRepository.instance;
      var cfg = await repo.load();
      if (!cfg.isComplete) {
        if (!context.mounted) return;
        await showAiConfigDialog(context);
      }

      if (!context.mounted) return;
      final fut = item.requestAiSuggestion(l10n);
      setState(() {}); // reflect loading state stored on FSItem
      await fut;
      if (!context.mounted) return;
      setState(() {});

      if (!identical(widget.selected, item)) return;
      final res = item.aiSuggestResult;
      if (res == null || res.ok) return;
      if (res.type == ai.AiSuggestFailureType.configIncomplete) return;

      final friendly = _userFriendlyAiSuggestError(l10n, res);
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final d = (res.detail ?? '').trim();
          final detail = d.isEmpty ? null : d;
          return AlertDialog(
            title: Text(l10n.aiSuggestFailedTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friendly),
                if (detail != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(detail),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonOk),
              ),
            ],
          );
        },
      );
    }

    final aiRes = item.aiSuggestResult;
    final aiFriendlyError = (aiRes != null && !aiRes.ok) ? _userFriendlyAiSuggestError(l10n, aiRes) : null;
    final aiRawText = (aiRes != null && aiRes.ok) ? (aiRes.text ?? '').trim() : null;
    final aiParsed = item.aiSuggestParsed;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          l10n.detailTitle,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        FutureBuilder<FileStat>(
          future: _statFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l10n.detailLoadFailed,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }

            final stat = snapshot.data!;
            final typeText = _typeText(l10n, stat.type);
            final diskSizeBytes = item.isDirectory ? null : item.sizeBytes;
            final diskSizeText = diskSizeBytes == null ? null : '${formatSizeBytes(diskSizeBytes)} (${diskSizeBytes}B)';

            final rows = <Widget>[
              _kv(context, l10n.detailName, item.name),
              _kv(context, l10n.detailPath, item.path),
              _kv(context, l10n.detailType, typeText),
              if (diskSizeText != null) _kv(context, l10n.detailSize, diskSizeText),
              if (item.isDirectory) _kv(context, l10n.detailFolderSizeCalculated, computedSizeText),
              _kv(context, l10n.detailModified, _formatDateTime(stat.modified)),
              _kv(context, l10n.detailAccessed, _formatDateTime(stat.accessed)),
              _kv(context, l10n.detailChanged, _formatDateTime(stat.changed)),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i != rows.length - 1) const Divider(height: 1),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: item.isAiSuggestLoading ? null : onAiSuggest,
            child: Text(item.isAiSuggestLoading ? l10n.aiSuggestLoading : l10n.aiSuggestButton),
          ),
        ),
        if (aiFriendlyError != null) ...[
          const SizedBox(height: 12),
          Text(
            aiFriendlyError,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (aiRawText != null && aiRawText.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashedBorder(
                    color: Colors.orange,
                    radius: 10,
                    dashLength: 6,
                    gapLength: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.aiSuggestDisclaimer,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  aiParsed == null
                      ? SelectableText(
                          aiRawText,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : SelectableText.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodySmall,
                            children: [
                              TextSpan(
                                text: '${l10n.aiSuggestParsedSummaryLabel}  ',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: aiParsed.summary),
                              const TextSpan(text: '\n\n'),
                              TextSpan(
                                text: '${l10n.aiSuggestParsedAdviceLabel}  ',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: aiParsed.advice),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _userFriendlyAiSuggestError(AppLocalizations l10n, ai.AiSuggestResult res) {
    final t = res.type;
    if (t == ai.AiSuggestFailureType.configIncomplete) return l10n.aiSuggestErrorConfigIncomplete;
    if (t == ai.AiSuggestFailureType.badUrl) return l10n.aiSuggestErrorBadUrl;
    if (t == ai.AiSuggestFailureType.timeout) return l10n.aiSuggestErrorTimeout;
    if (t == ai.AiSuggestFailureType.connectionFailed) return l10n.aiSuggestErrorConnectFailed;
    if (t == ai.AiSuggestFailureType.httpNon200) {
      final code = res.httpStatusCode;
      return code == null ? l10n.aiSuggestErrorHttpUnknown : l10n.aiSuggestErrorHttp(code);
    }
    if (t == ai.AiSuggestFailureType.jsonParse || t == ai.AiSuggestFailureType.responseSchema) {
      return l10n.aiSuggestErrorInternal;
    }
    return l10n.aiSuggestErrorUnknown;
  }
}
