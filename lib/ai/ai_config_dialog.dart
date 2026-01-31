import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'ai_config.dart';
import 'ai_validator.dart';

Future<void> showAiConfigDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final repo = AiConfigRepository.instance;
  final existing = await repo.load();
  if (!context.mounted) return;

  final keyCtrl = TextEditingController(text: existing.apiKey);
  final urlCtrl = TextEditingController(text: existing.baseUrl);
  final modelCtrl = TextEditingController(text: existing.model);

  var validating = false;
  Timer? saveDebounce;

  void scheduleSave() {
    if (validating) return;
    saveDebounce?.cancel();
    saveDebounce = Timer(const Duration(milliseconds: 200), () {
      final cfg = AiConfig(
        apiKey: keyCtrl.text,
        baseUrl: urlCtrl.text,
        model: modelCtrl.text,
      );
      // Update in-memory immediately (so reopening the dialog reflects edits),
      // then persist in background.
      repo.updateCached(cfg);
      unawaited(repo.save(cfg));
    });
  }

  Future<void> flushSave() async {
    saveDebounce?.cancel();
    saveDebounce = null;
    final cfg = AiConfig(
      apiKey: keyCtrl.text,
      baseUrl: urlCtrl.text,
      model: modelCtrl.text,
    );
    repo.updateCached(cfg);
    // On close, make it deterministic: await the last write.
    await repo.save(cfg);
  }

  keyCtrl.addListener(scheduleSave);
  urlCtrl.addListener(scheduleSave);
  modelCtrl.addListener(scheduleSave);

  String userFriendlyError(AiValidationResult res) {
    final t = res.type;
    if (t == AiValidateFailureType.configIncomplete) return l10n.aiConfigErrorIncomplete;
    if (t == AiValidateFailureType.badUrl) return l10n.aiConfigErrorBadUrl;
    if (t == AiValidateFailureType.timeout) return l10n.aiConfigErrorTimeout;
    if (t == AiValidateFailureType.connectionFailed) return l10n.aiConfigErrorConnectFailed;
    if (t == AiValidateFailureType.httpNon200) {
      final code = res.httpStatusCode;
      return code == null ? l10n.aiConfigErrorHttpUnknown : l10n.aiConfigErrorHttp(code);
    }
    if (t == AiValidateFailureType.jsonParse || t == AiValidateFailureType.responseSchema) {
      return l10n.aiConfigErrorInternal;
    }
    return l10n.aiConfigErrorUnknown;
  }

  Future<void> showFail(BuildContext dialogContext, AiValidationResult res) async {
    final detail = (res.detail ?? '').trim();
    final d = detail.isEmpty ? null : detail;
    final friendly = userFriendlyError(res);
    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.aiConfigValidateFailedTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(friendly),
              if (d != null) ...[
                const SizedBox(height: 12),
                SelectableText(d),
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

  Future<void> showSuccess(BuildContext dialogContext) async {
    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.aiConfigSuccessTitle),
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

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> onConfirm() async {
            if (validating) return;
            setState(() => validating = true);

            final cfg = AiConfig(
              apiKey: keyCtrl.text,
              baseUrl: urlCtrl.text,
              model: modelCtrl.text,
            );
            // Save immediately after any change (subocr-style), even before validation.
            repo.updateCached(cfg);
            unawaited(repo.save(cfg));

            final res = await validateAiConfig(cfg);
            if (!ctx.mounted) return;
            if (!res.ok) {
              setState(() => validating = false);
              await showFail(ctx, res);
              return;
            }

            await repo.save(cfg);
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop();
            if (!context.mounted) return;
            await showSuccess(context);
          }

          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(l10n.aiConfigTitle),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: urlCtrl,
                      enabled: !validating,
                      decoration: InputDecoration(
                        labelText: l10n.aiConfigBaseUrlLabel,
                        hintText: l10n.aiConfigBaseUrlHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modelCtrl,
                      enabled: !validating,
                      decoration: InputDecoration(
                        labelText: l10n.aiConfigModelLabel,
                        hintText: l10n.aiConfigModelHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keyCtrl,
                      enabled: !validating,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.aiConfigApiKeyLabel,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: validating ? null : () => Navigator.of(ctx).pop(),
                  child: Text(l10n.commonCancel),
                ),
                TextButton(
                  onPressed: validating ? null : onConfirm,
                  child: Text(validating ? l10n.aiConfigValidating : l10n.commonConfirm),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  // Ensure we persist the last edits even if the user closes the dialog quickly.
  await flushSave();

  keyCtrl.removeListener(scheduleSave);
  urlCtrl.removeListener(scheduleSave);
  modelCtrl.removeListener(scheduleSave);

  saveDebounce?.cancel();
  keyCtrl.dispose();
  urlCtrl.dispose();
  modelCtrl.dispose();
}
