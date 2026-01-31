import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fs_item.dart';

const MethodChannel _fsChannel = MethodChannel('dcf_cleaner/fs');

Future<void> openInFileManager(FSItem item) async {
  final path = item.path;
  if (Platform.isMacOS) {
    if (item.isDirectory) {
      await Process.run('open', <String>[path]);
    } else {
      // Reveal (select) the file in Finder.
      await Process.run('open', <String>['-R', path]);
    }
    return;
  }

  if (Platform.isWindows) {
    if (item.isDirectory) {
      await Process.run('explorer', <String>[path]);
    } else {
      // Explorer's /select parsing is finicky; keep it as one argument.
      await Process.run('explorer', <String>['/select,$path']);
    }
    return;
  }

  if (Platform.isLinux) {
    final openPath = item.isDirectory ? path : File(path).parent.path;
    await Process.run('xdg-open', <String>[openPath]);
    return;
  }

  debugPrint('DCF Cleaner: open in file manager not supported: $path');
}

Future<void> deleteFromDisk(FSItem item) async {
  // Always use a platform call so "Delete" behaves like moving to Trash/Recycle Bin.
  //
  // If a platform isn't implemented yet, let it throw (we'll surface a short error).
  await _fsChannel.invokeMethod<void>(
    'trashItem',
    <String, Object?>{'path': item.path},
  );
}

Future<void> permanentlyDeleteFromDisk(FSItem item) async {
  final path = item.path;

  // Never read file contents; only touch metadata + delete.
  final type = await FileSystemEntity.type(path, followLinks: false);
  switch (type) {
    case FileSystemEntityType.directory:
      await Directory(path).delete(recursive: true);
      return;
    case FileSystemEntityType.link:
      await Link(path).delete();
      return;
    case FileSystemEntityType.file:
      await File(path).delete();
      return;
    case FileSystemEntityType.notFound:
      return;
    default:
      // Best effort: try directory then file then link.
      try {
        await Directory(path).delete(recursive: true);
      } catch (_) {
        try {
          await File(path).delete();
        } catch (_) {
          await Link(path).delete();
        }
      }
      return;
  }
}
