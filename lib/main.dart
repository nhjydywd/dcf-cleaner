import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dcf_cleaner/l10n/app_localizations.dart';

import 'fs/fs_item.dart';
import 'pages/empty_page.dart';
import 'pages/file_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FSItem? _root;
  bool _pickingFolder = false;
  bool _loadingEntries = false;
  int _rootRevision = 0;
  Timer? _sizeTimer;

  @override
  void dispose() {
    _sizeTimer?.cancel();
    super.dispose();
  }

  Future<String?> _pickFolderPath() async {
    final l10n = AppLocalizations.of(context)!;

    final isSupportedPlatform = switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux => true,
      _ => false,
    };

    if (kIsWeb || !isSupportedPlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chooseFolderNotSupported)),
      );
      return null;
    }

    setState(() => _pickingFolder = true);
    try {
      final selectedDirectory = await FilePicker.platform
          .getDirectoryPath(
            dialogTitle: l10n.chooseFolder,
          )
          .timeout(
            const Duration(seconds: 30),
          );
      if (!mounted) return null;
      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chooseFolderCanceled)),
        );
        return null;
      }
      return selectedDirectory;
    } on TimeoutException {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chooseFolderTimedOut)),
      );
      return null;
    } catch (e) {
      if (!mounted) return null;
      debugPrint('getDirectoryPath failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chooseFolderFailed)),
      );
      return null;
    } finally {
      if (mounted) setState(() => _pickingFolder = false);
    }
  }

  Future<void> _chooseFolderAndStartScan() async {
    final selectedDirectory = await _pickFolderPath();
    if (!mounted || selectedDirectory == null) return;
    _startScan(selectedDirectory);
  }

  Future<void> _reselectAndStartScan() async {
    final selectedDirectory = await _pickFolderPath();
    if (!mounted || selectedDirectory == null) return;
    _startScan(selectedDirectory);
  }

  void _startScan(String path) {
    final rev = ++_rootRevision;
    _sizeTimer?.cancel();
    resetProcessedFileIds();

    final root = FSItem.directory(
      path: path,
      name: fsBasename(path),
    );

    setState(() {
      _root = root;
      _loadingEntries = true;
    });

    _sizeTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || rev != _rootRevision) {
        timer.cancel();
        if (identical(_sizeTimer, timer)) _sizeTimer = null;
        return;
      }
      final currentRoot = _root;
      if (currentRoot == null) return;

      final changed = recomputeSizesFromChildren(currentRoot);
      if (changed) setState(() {});

      if (currentRoot.isSizeConfirmed) {
        timer.cancel();
        if (identical(_sizeTimer, timer)) _sizeTimer = null;
      }
    });

    final scan = root.scanRecursively(
      isCanceled: () => !mounted || rev != _rootRevision,
      onDirectoryListed: (dir) {
        if (!mounted || rev != _rootRevision) return;
        if (!identical(dir, root)) return;
        setState(() => _loadingEntries = false);
      },
    );

    unawaited(
      scan.whenComplete(() {
        if (!mounted || rev != _rootRevision) return;
        _sizeTimer?.cancel();
        _sizeTimer = null;
        recomputeSizesFromChildren(root);
        setState(() => _loadingEntries = false);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final root = _root;
    if (root == null) {
      return EmptyPage(
        pickingFolder: _pickingFolder,
        onChooseFolder: _chooseFolderAndStartScan,
      );
    }

    return FilePage(
      root: root,
      loadingEntries: _loadingEntries,
      pickingFolder: _pickingFolder,
      onReselectFolder: _reselectAndStartScan,
    );
  }
}
