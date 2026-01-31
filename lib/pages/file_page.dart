import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../fs/fs_actions.dart';
import '../fs/fs_item.dart';
import '../widgets/drag_divider.dart';
import 'detail_panel.dart';
import 'file_list.dart';

class FilePage extends StatefulWidget {
  const FilePage({
    super.key,
    required this.root,
    required this.loadingEntries,
    required this.pickingFolder,
    required this.onReselectFolder,
  });

  final FSItem root;
  final bool loadingEntries;
  final bool pickingFolder;
  final VoidCallback onReselectFolder;

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  static const double _defaultColumnWidth = 250;
  static const double _minColumnWidth = 180;
  static const double _maxColumnWidth = 400;
  static const double _resizeHandleWidth = 10;
  static const double _sizeColumnWidth = 60;
  static const double _detailPanelWidth = 320;

  final ScrollController _hController = ScrollController();
  List<FSItem> _stack = const [];
  List<double> _widths = const [];
  FSItem? _selected;
  int _navToken = 0;
  bool _hScrollable = false;

  @override
  void initState() {
    super.initState();
    _stack = [widget.root];
    _widths = const [_defaultColumnWidth];
  }

  @override
  void didUpdateWidget(covariant FilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.root, widget.root)) {
      _navToken++;
      _stack = [widget.root];
      _widths = const [_defaultColumnWidth];
      _selected = null;
    }
  }

  @override
  void dispose() {
    _hController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_hController.hasClients) return;
      final max = _hController.position.maxScrollExtent;
      _hController.animateTo(
        max,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _scheduleUpdateHScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_hController.hasClients) return;
      final next = _hController.position.maxScrollExtent > 0;
      if (next == _hScrollable) return;
      setState(() => _hScrollable = next);
    });
  }

  void _ensureChildrenListed(FSItem dir) {
    if (!dir.isDirectory) return;
    if (dir.isChildrenListed) return;
    if (dir.isListingChildren) return;

    final token = ++_navToken;
    setState(() {});
    unawaited(
      dir
          .listChildren(
        isCanceled: () => !mounted || token != _navToken,
      )
          .whenComplete(() {
        if (!mounted || token != _navToken) return;
        setState(() {});
      }),
    );
  }

  void _onItemTap(int level, FSItem item) {
    setState(() => _selected = item);

    if (!item.isDirectory) return;

    setState(() {
      _navToken++;
      _stack = [
        ..._stack.take(level + 1),
        item,
      ];
      _widths = [
        ..._widths.take(level + 1),
        (_widths.isEmpty ? _defaultColumnWidth : _widths.last),
      ];
    });
    _ensureChildrenListed(item);
    _scrollToEnd();
  }

  bool _isSameOrDescendantPath(String ancestorPath, String childPath) {
    if (childPath == ancestorPath) return true;
    if (!childPath.startsWith(ancestorPath)) return false;
    if (childPath.length <= ancestorPath.length) return false;
    final next = childPath[ancestorPath.length];
    return next == '/' || next == '\\';
  }

  String _binName(AppLocalizations l10n) {
    if (Platform.isMacOS) return l10n.binNameMac;
    if (Platform.isWindows) return l10n.binNameWindows;
    return l10n.binNameMac;
  }

  Future<bool> _confirmDeleteToBin(BuildContext context, FSItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final bin = _binName(l10n);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final primary = item.isDirectory
            ? l10n.deleteToBinConfirmPrimaryFolder(item.name, bin)
            : l10n.deleteToBinConfirmPrimaryFile(item.name, bin);
        return AlertDialog(
          title: Text(l10n.deleteConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(primary),
              const SizedBox(height: 8),
              Text(l10n.deleteToBinConfirmUndo(bin)),
              const SizedBox(height: 12),
              Text(
                l10n.deleteToBinConfirmReleaseSpace(bin),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.menuDelete),
            ),
          ],
        );
      },
    );
    return ok ?? false;
  }

  Future<bool> _confirmPermanentDelete(BuildContext context, FSItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final primary = item.isDirectory
            ? l10n.permanentDeleteConfirmMessageFolder(item.name)
            : l10n.permanentDeleteConfirmMessageFile(item.name);
        return AlertDialog(
          title: Text(l10n.permanentDeleteConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(primary),
              const SizedBox(height: 12),
              Text(
                l10n.permanentDeleteIrreversibleWarning,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(l10n.menuPermanentDelete),
            ),
          ],
        );
      },
    );
    return ok ?? false;
  }

  Future<void> _deleteItem(
    int level,
    FSItem item, {
    required Future<void> Function(FSItem item) deleteFn,
    required String failMessage,
  }) async {
    try {
      await deleteFn(item);
    } catch (_) {
      debugPrint('DCF Cleaner: failed to delete, skipped: ${item.path}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failMessage)),
      );
      return;
    }
    if (!mounted) return;

    setState(() {
      // Remove from the parent directory's children list.
      if (level >= 0 && level < _stack.length) {
        final parent = _stack[level];
        final kids = parent.children;
        if (kids != null) {
          parent.children = [
            for (final k in kids)
              if (k.path != item.path) k,
          ];
        }
      }

      // Clear selection if it points into the deleted subtree.
      final selected = _selected;
      if (selected != null && _isSameOrDescendantPath(item.path, selected.path)) {
        _selected = null;
      }

      // If this deleted directory is currently "opened", close those columns.
      final stackIndex = _stack.indexWhere((e) => e.path == item.path);
      if (stackIndex != -1) {
        _stack = _stack.take(stackIndex).toList(growable: false);
        _widths = _widths.take(_stack.length).toList(growable: false);
      } else if (level + 1 < _stack.length && _stack[level + 1].path == item.path) {
        _stack = _stack.take(level + 1).toList(growable: false);
        _widths = _widths.take(_stack.length).toList(growable: false);
      }
    });
  }

  Future<void> _onItemMenuAction(int level, FSItem item, FileListMenuAction action) async {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case FileListMenuAction.openInFileManager:
        try {
          await openInFileManager(item);
        } catch (_) {
          debugPrint('DCF Cleaner: failed to open in file manager: ${item.path}');
        }
        return;
      case FileListMenuAction.deleteToBin:
        final ok = await _confirmDeleteToBin(context, item);
        if (!ok) return;
        await _deleteItem(
          level,
          item,
          deleteFn: deleteFromDisk,
          failMessage: l10n.deleteFailed,
        );
        return;
      case FileListMenuAction.permanentDelete:
        final ok = await _confirmPermanentDelete(context, item);
        if (!ok) return;
        await _deleteItem(
          level,
          item,
          deleteFn: permanentlyDeleteFromDisk,
          failMessage: l10n.permanentDeleteFailed,
        );
        return;
    }
  }

  void _setColumnWidth(int index, double width) {
    if (index < 0 || index >= _widths.length) return;
    final next = width.clamp(_minColumnWidth, _maxColumnWidth);
    if (next == _widths[index]) return;
    setState(() {
      _widths = [
        for (var i = 0; i < _widths.length; i++) i == index ? next : _widths[i],
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleUpdateHScrollable();
    final l10n = AppLocalizations.of(context)!;

    final base = formatSizeBytes(widget.root.sizeBytes);
    final rootSizeText = widget.root.isSizeConfirmed ? base : '>$base';

    final columns = <Widget>[];
    for (var i = 0; i < _stack.length; i++) {
      final dir = _stack[i];
      final loading = i == 0
          ? widget.loadingEntries
          : (dir.isDirectory && !dir.isChildrenListed && dir.isListingChildren);
      final width = i < _widths.length ? _widths[i] : _defaultColumnWidth;
      final openedPath = i + 1 < _stack.length ? _stack[i + 1].path : null;

      columns.add(
        SizedBox(
          width: width,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: FileList(
                  root: dir,
                  loading: loading,
                  onTap: (item) => _onItemTap(i, item),
                  onSelect: (item) => setState(() => _selected = item),
                  onMenuAction: (item, action) => _onItemMenuAction(i, item, action),
                  selectedPath: _selected?.path,
                  openedPath: openedPath,
                  sizeColumnWidth: _sizeColumnWidth,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: DragDivider(
                  hitWidth: _resizeHandleWidth,
                  getInitialPosition: () => _widths[i],
                  onPositionChanged: (position) => _setColumnWidth(i, position),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: false,
        title: Row(
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      l10n.currentDirectoryTitle(widget.root.path),
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($rootSizeText)',
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: widget.pickingFolder ? null : widget.onReselectFolder,
              child: Text(l10n.reselectFolder),
            ),
          ],
        ),
      ),
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Row(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _hController,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                thumbVisibility: _hScrollable,
                trackVisibility: _hScrollable,
                child: SingleChildScrollView(
                  controller: _hController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: columns,
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            SizedBox(
              width: _detailPanelWidth,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: DetailPanel(selected: _selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
