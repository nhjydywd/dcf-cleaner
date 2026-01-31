import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmptyPage extends StatelessWidget {
  const EmptyPage({
    super.key,
    required this.pickingFolder,
    required this.onChooseFolder,
  });

  final bool pickingFolder;
  final VoidCallback onChooseFolder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: false,
        title: Text(l10n.appTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: pickingFolder ? null : onChooseFolder,
                icon: const Icon(Icons.folder_open),
                label: Text(l10n.chooseFolder),
              ),
              if (pickingFolder) ...[
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
