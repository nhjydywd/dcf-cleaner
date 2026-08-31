import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dcf_cleaner/l10n/app_localizations.dart';

import '../ai/ai_config.dart';
import '../ai/ai_suggest.dart' as ai;
import '../ai/ai_suggest_parser.dart';

const MethodChannel _fsChannel = MethodChannel('dcf_cleaner/fs');

/// A per-scan global set of file-ids that have already been counted.
///
/// Used for hard-link de-duplication. Reset this when starting a new scan.
final Set<String> processedFileIds = <String>{};

void resetProcessedFileIds() => processedFileIds.clear();

class FSItem {
  FSItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.children,
    this.fileId,
    required this.isDuplicate,
    required this.isSizeConfirmed,
    required this.isChildrenListed,
    required this.hasListingError,
    required this.isListingChildren,
    this.aiSuggestResult,
    this.aiSuggestParsed,
  });

  FSItem.file({
    required this.path,
    required this.name,
    required this.sizeBytes,
    this.fileId,
    this.isDuplicate = false,
  })  : children = null,
        isSizeConfirmed = true,
        isChildrenListed = true,
        hasListingError = false,
        isListingChildren = false,
        aiSuggestResult = null,
        aiSuggestParsed = null;

  /// `null` means this item is a file.
  /// Non-null means this item is a directory; it may be empty if not loaded.
  List<FSItem>? children;
  final String? fileId;

  /// Only meaningful for files.
  ///
  /// If `true`, this file is a hard-link duplicate (same underlying fileId)
  /// and should not contribute to directory size aggregation.
  final bool isDuplicate;

  /// Only meaningful for directories.
  ///
  /// If `false`, the displayed size should be treated as a lower bound.
  bool isSizeConfirmed;

  /// Only meaningful for directories.
  ///
  /// `true` means we've finished listing this directory's direct children.
  /// Until this becomes `true`, the directory can never be "confirmed", because
  /// we don't know whether more children will show up later.
  bool isChildrenListed;

  /// Only meaningful for directories.
  ///
  /// If listing fails due to permissions or IO errors, we keep the directory
  /// unconfirmed (best-effort) instead of incorrectly "confirming" a partial/empty tree.
  bool hasListingError;

  /// Only meaningful for directories.
  ///
  /// Prevents multiple concurrent list requests for the same item.
  bool isListingChildren;

  FSItem.directory({
    required this.path,
    required this.name,
    this.fileId,
    this.isDuplicate = false,
    this.children = const [],
    this.sizeBytes = 0,
  })  : isSizeConfirmed = false,
        isChildrenListed = false,
        hasListingError = false,
        isListingChildren = false,
        aiSuggestResult = null,
        aiSuggestParsed = null;

  String path;
  String name;
  int sizeBytes;

  bool get isDirectory => children != null;

  // --- AI suggestion state (stored on the FSItem itself) ---
  ai.AiSuggestResult? aiSuggestResult;
  ParsedAiSuggestion? aiSuggestParsed;
  bool isAiSuggestLoading = false;
  int _aiSuggestSeq = 0;

  /// Lists this directory's direct children (non-recursive).
  ///
  /// After listing, this item becomes `isChildrenListed=true` (even if empty).
  /// Errors set `hasListingError=true`.
  Future<void> listChildren({
    required bool Function() isCanceled,
    void Function(FSItem dir)? onDirectoryListed,
  }) async {
    if (isCanceled()) return;
    if (!isDirectory) return;
    if (isChildrenListed) return;
    if (isListingChildren) return;
    isListingChildren = true;

    final items = <FSItem>[];
    var canceled = false;

    try {
      // Always use platform listing so we can also fetch a stable file-id for
      // hard-link de-duplication. If a platform isn't implemented yet, let it
      // throw (no dart:io fallback).
      final raw = await _fsChannel.invokeMethod<List<dynamic>>(
        'listDirectory',
        <String, Object?>{'path': path},
      );
      if (isCanceled()) {
        canceled = true;
        return;
      }

      final list = (raw ?? const <dynamic>[]).cast<dynamic>().toList(growable: false);
      list.sort((a, b) {
        final am = (a as Map).cast<String, Object?>();
        final bm = (b as Map).cast<String, Object?>();
        final ap = (am['path'] as String?) ?? '';
        final bp = (bm['path'] as String?) ?? '';
        return ap.compareTo(bp);
      });

      for (final e in list) {
        if (isCanceled()) {
          canceled = true;
          break;
        }
        final map = (e as Map).cast<String, Object?>();
        final childPath = map['path'] as String?;
        if (childPath == null) continue;
        final childName = (map['name'] as String?) ?? fsBasename(childPath);
        final type = map['type'] as String?;
        final fileId = map['fileId'] as String?;

        if (type == 'directory') {
          items.add(FSItem.directory(path: childPath, name: childName, fileId: fileId));
        } else {
          final size = (map['sizeBytes'] as int?) ?? 0;
          var duplicate = false;
          if (fileId != null && fileId.isNotEmpty) {
            // First occurrence counts, subsequent ones get marked with "*".
            duplicate = !processedFileIds.add(fileId);
          }
          items.add(
            FSItem.file(
              path: childPath,
              name: childName,
              sizeBytes: size,
              fileId: fileId,
              isDuplicate: duplicate,
            ),
          );
        }
      }
    } catch (_) {
      hasListingError = true;
      // Keep logs short; permission-denied directories are common on macOS.
      debugPrint('DCF Cleaner: failed to list directory, skipped: $path');
    } finally {
      isListingChildren = false;
      if (!canceled && !hasListingError) {
        items.sort((a, b) {
          final aIsDir = a.isDirectory;
          final bIsDir = b.isDirectory;
          if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        children = items;
        isChildrenListed = true;
        onDirectoryListed?.call(this);
      } else if (!canceled && hasListingError) {
        // Mark as "listed" to avoid endless retries; keep unconfirmed via hasListingError.
        children = const [];
        isChildrenListed = true;
        onDirectoryListed?.call(this);
      }
    }
  }

  /// Recursively scans this directory into a full FSItem tree.
  ///
  /// Each directory lists its own children, then recursively asks directory-children
  /// to do the same.
  Future<void> scanRecursively({
    required bool Function() isCanceled,
    void Function(FSItem dir)? onDirectoryListed,
  }) async {
    if (!isDirectory) return;
    await listChildren(isCanceled: isCanceled, onDirectoryListed: onDirectoryListed);
    if (isCanceled()) return;

    final currentChildren = children;
    if (currentChildren == null) return;

    for (final child in currentChildren) {
      if (isCanceled()) return;
      if (!child.isDirectory) continue;
      await child.scanRecursively(isCanceled: isCanceled, onDirectoryListed: onDirectoryListed);
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  String _buildAiUserPrompt(AppLocalizations l10n, String sizeText, FileStat? stat) {
    final modified = stat == null ? l10n.aiSuggestUnknown : _formatDateTime(stat.modified);
    final accessed = stat == null ? l10n.aiSuggestUnknown : _formatDateTime(stat.accessed);
    final changed = stat == null ? l10n.aiSuggestUnknown : _formatDateTime(stat.changed);

    if (!isDirectory) {
      return l10n.aiSuggestUserPromptFile(
        path,
        name,
        sizeText,
        sizeBytes,
        modified,
        accessed,
        changed,
      );
    }

    final kids = (children ?? const <FSItem>[]).toList(growable: false);
    kids.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    final top = kids.take(10).toList(growable: false);

    String childSizeText(FSItem c) {
      final base = formatSizeBytes(c.sizeBytes);
      return c.isDirectory && !c.isSizeConfirmed ? '>$base' : base;
    }

    final lines = top.isEmpty
        ? l10n.aiSuggestTop10Empty
        : top
            .map((c) {
              final star = (!c.isDirectory && c.isDuplicate) ? '*' : '';
              final type = c.isDirectory ? l10n.detailTypeDirectory : l10n.detailTypeFile;
              return '- ${childSizeText(c)}  $type  $star${c.name}';
            })
            .join('\n');

    return l10n.aiSuggestUserPromptFolder(
      path,
      name,
      sizeText,
      sizeBytes,
      modified,
      accessed,
      changed,
      lines,
    );
  }

  /// Requests an AI suggestion for this item and stores the result on this FSItem.
  ///
  /// Note: This does not show any UI. The caller should ensure AI config is
  /// complete (or handle `configIncomplete` by prompting the user to configure).
  Future<void> requestAiSuggestion(AppLocalizations l10n) async {
    final seq = ++_aiSuggestSeq;
    isAiSuggestLoading = true;
    aiSuggestResult = null;
    aiSuggestParsed = null;

    final repo = AiConfigRepository.instance;
    final cfg = await repo.load();
    if (!cfg.isComplete) {
      if (seq != _aiSuggestSeq) return;
      aiSuggestResult = ai.AiSuggestResult.fail(ai.AiSuggestFailureType.configIncomplete);
      isAiSuggestLoading = false;
      return;
    }

    final base = formatSizeBytes(sizeBytes);
    final computedSizeText = isDirectory && !isSizeConfirmed ? '>$base' : base;

    FileStat? stat;
    try {
      stat = await FileStat.stat(path);
    } catch (_) {
      stat = null;
    }

    final res = await ai.requestAiSuggestion(
      cfg,
      systemPrompt: l10n.aiSuggestSystemPrompt,
      userPrompt: _buildAiUserPrompt(l10n, computedSizeText, stat),
    );

    if (seq != _aiSuggestSeq) return;
    aiSuggestResult = res;
    if (res.ok) {
      final out = (res.text ?? '').trim();
      aiSuggestParsed = tryParseAiSuggestion(out);
    }
    isAiSuggestLoading = false;
  }
}

/// Recomputes directory sizes bottom-up.
///
/// Returns whether anything changed (sizeBytes / isSizeConfirmed).
bool recomputeSizesFromChildren(FSItem item) {
  if (!item.isDirectory) return false;
  final children = item.children;
  if (children == null) return false;

  var changed = false;
  var sum = 0;
  var allChildrenConfirmed = true;

  for (final child in children) {
    changed = recomputeSizesFromChildren(child) || changed;
    if (!child.isDirectory && child.isDuplicate) {
      // Hard-link duplicates shouldn't contribute to aggregated directory sizes.
      continue;
    }
    sum += child.sizeBytes;
    if (!child.isSizeConfirmed) allChildrenConfirmed = false;
  }

  final confirmed = item.isChildrenListed && !item.hasListingError && allChildrenConfirmed;

  if (item.sizeBytes != sum) {
    item.sizeBytes = sum;
    changed = true;
  }
  if (item.isSizeConfirmed != confirmed) {
    item.isSizeConfirmed = confirmed;
    changed = true;
  }

  return changed;
}

String fsBasename(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  return parts.isEmpty ? path : (parts.last.isEmpty ? path : parts.last);
}

String formatSizeBytes(int bytes) {
  if (bytes < 0) bytes = 0;

  const k = 1000.0;
  const kb = k;
  const mb = k * k;
  const gb = k * k * k;
  const tb = k * k * k * k;
  const pb = k * k * k * k * k;

  double value;
  String unit;

  if (bytes < kb) {
    value = bytes.toDouble();
    unit = 'B';
  } else if (bytes < 1000 * kb) {
    value = bytes / kb;
    unit = 'KB';
  } else if (bytes < 1000 * mb) {
    value = bytes / mb;
    unit = 'MB';
  } else if (bytes < 1000 * gb) {
    value = bytes / gb;
    unit = 'GB';
  } else if (bytes < 1000 * tb) {
    value = bytes / tb;
    unit = 'TB';
  } else {
    value = bytes / pb;
    unit = 'PB';
  }

  return '${value.toStringAsFixed(1)}$unit';
}
