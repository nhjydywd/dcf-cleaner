import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dcf_cleaner/l10n/app_localizations.dart';

import '../fs/fs_item.dart';

enum FileListMenuAction { deleteToBin, permanentDelete, openInFileManager }

class FileList extends StatefulWidget {
  const FileList({
    super.key,
    required this.root,
    required this.loading,
    this.onTap,
    this.onSelect,
    this.onMenuAction,
    this.selectedPath,
    this.openedPath,
    required this.sizeColumnWidth,
  });

  /// The directory whose direct children should be displayed.
  ///
  /// If this is a file, or if its children are not yet available, the list is empty.
  final FSItem root;
  final bool loading;
  final ValueChanged<FSItem>? onTap;
  final ValueChanged<FSItem>? onSelect;
  final Future<void> Function(FSItem item, FileListMenuAction action)? onMenuAction;
  final String? selectedPath;

  /// If this list is showing `root`'s children, and one of those children is
  /// currently "opened" (its children shown in the next column), provide its path
  /// here so it can be highlighted.
  final String? openedPath;

  final double sizeColumnWidth;

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  final ScrollController _controller = ScrollController();
  Timer? _sortTimer;
  List<FSItem> _entries = const [];

  @override
  void initState() {
    super.initState();
    _refreshSortedEntries();
    _sortTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      _refreshSortedEntries();
    });
  }

  @override
  void didUpdateWidget(covariant FileList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.root, widget.root)) {
      _refreshSortedEntries(force: true);
    }
  }

  void _refreshSortedEntries({bool force = false}) {
    final children = widget.root.children;
    final next = (children ?? const <FSItem>[]).toList(growable: false);

    next.sort((a, b) {
      final bySize = b.sizeBytes.compareTo(a.sizeBytes);
      if (bySize != 0) return bySize;
      final aIsDir = a.isDirectory;
      final bIsDir = b.isDirectory;
      if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    if (!force && _entries.length == next.length) {
      var sameOrder = true;
      for (var i = 0; i < next.length; i++) {
        if (_entries[i].path != next[i].path) {
          sameOrder = false;
          break;
        }
      }
      if (sameOrder) return;
    }

    setState(() => _entries = next);
  }

  @override
  void dispose() {
    _sortTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _displaySize(FSItem item) {
    final base = formatSizeBytes(item.sizeBytes);
    if (!item.isDirectory) {
      return item.isDuplicate ? '*$base' : base;
    }
    return item.isSizeConfirmed ? base : '>$base';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final l10n = AppLocalizations.of(context)!;
    final entries = _entries;
    final selectedPath = widget.selectedPath;
    final openedPath = widget.openedPath;
    final openedColor = Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.45);
    final selectedColor = Colors.blue.withValues(alpha: 0.18);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scrollbar(
        controller: _controller,
        scrollbarOrientation: ScrollbarOrientation.left,
        child: ListView.separated(
          controller: _controller,
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isSelected = selectedPath != null && entry.path == selectedPath;
            final isOpened = openedPath != null && entry.path == openedPath;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapDown: (details) async {
                widget.onSelect?.call(entry);
                final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                final position = RelativeRect.fromLTRB(
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                  overlay.size.width - details.globalPosition.dx,
                  overlay.size.height - details.globalPosition.dy,
                );
                final action = await showMenu<FileListMenuAction>(
                  context: context,
                  position: position,
                  items: [
                    PopupMenuItem(
                      value: FileListMenuAction.openInFileManager,
                      child: Text(l10n.menuOpenInFileManager),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: FileListMenuAction.deleteToBin,
                      child: Text(
                        l10n.menuDelete,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                    PopupMenuItem(
                      value: FileListMenuAction.permanentDelete,
                      child: Text(
                        l10n.menuPermanentDelete,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                );
                if (action == null) return;
                final handler = widget.onMenuAction;
                if (handler == null) return;
                await handler(entry, action);
              },
              child: ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: selectedColor,
                tileColor: isSelected ? null : (isOpened ? openedColor : null),
                leading: Icon(
                  entry.children != null ? Icons.folder : Icons.insert_drive_file,
                ),
                title: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: SizedBox(
                  width: widget.sizeColumnWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _displaySize(entry),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                    ),
                  ),
                ),
                onTap: widget.onTap == null ? null : () => widget.onTap!(entry),
              ),
            );
          },
        ),
      ),
    );
  }
}
