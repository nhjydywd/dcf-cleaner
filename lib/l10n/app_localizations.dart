import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'DCF Cleaner'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @chooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get chooseFolder;

  /// No description provided for @reselectFolder.
  ///
  /// In en, this message translates to:
  /// **'Re-select'**
  String get reselectFolder;

  /// No description provided for @selectedFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected folder:'**
  String get selectedFolderLabel;

  /// No description provided for @currentDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Current root: {path}'**
  String currentDirectoryTitle(String path);

  /// No description provided for @chooseFolderNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Folder picker is not supported on this platform.'**
  String get chooseFolderNotSupported;

  /// No description provided for @chooseFolderCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled.'**
  String get chooseFolderCanceled;

  /// No description provided for @chooseFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder picker.'**
  String get chooseFolderFailed;

  /// No description provided for @chooseFolderTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Folder picker timed out.'**
  String get chooseFolderTimedOut;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailTitle;

  /// No description provided for @detailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load file details.'**
  String get detailLoadFailed;

  /// No description provided for @detailName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get detailName;

  /// No description provided for @detailPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get detailPath;

  /// No description provided for @detailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get detailType;

  /// No description provided for @detailSize.
  ///
  /// In en, this message translates to:
  /// **'Size on disk'**
  String get detailSize;

  /// No description provided for @detailFolderSizeCalculated.
  ///
  /// In en, this message translates to:
  /// **'Folder size (calculated)'**
  String get detailFolderSizeCalculated;

  /// No description provided for @detailModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get detailModified;

  /// No description provided for @detailAccessed.
  ///
  /// In en, this message translates to:
  /// **'Accessed'**
  String get detailAccessed;

  /// No description provided for @detailChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get detailChanged;

  /// No description provided for @detailTypeFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get detailTypeFile;

  /// No description provided for @detailTypeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get detailTypeDirectory;

  /// No description provided for @detailTypeLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get detailTypeLink;

  /// No description provided for @detailTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get detailTypeOther;

  /// No description provided for @aiSuggestButton.
  ///
  /// In en, this message translates to:
  /// **'AI Suggest'**
  String get aiSuggestButton;

  /// No description provided for @aiSuggestLoading.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get aiSuggestLoading;

  /// No description provided for @aiSuggestFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion failed'**
  String get aiSuggestFailedTitle;

  /// No description provided for @aiSuggestErrorConfigIncomplete.
  ///
  /// In en, this message translates to:
  /// **'AI configuration is incomplete.'**
  String get aiSuggestErrorConfigIncomplete;

  /// No description provided for @aiSuggestErrorBadUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL is invalid.'**
  String get aiSuggestErrorBadUrl;

  /// No description provided for @aiSuggestErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out.'**
  String get aiSuggestErrorTimeout;

  /// No description provided for @aiSuggestErrorConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed.'**
  String get aiSuggestErrorConnectFailed;

  /// No description provided for @aiSuggestErrorHttpUnknown.
  ///
  /// In en, this message translates to:
  /// **'Request failed (HTTP error).'**
  String get aiSuggestErrorHttpUnknown;

  /// No description provided for @aiSuggestErrorHttp.
  ///
  /// In en, this message translates to:
  /// **'Request failed (HTTP {code}).'**
  String aiSuggestErrorHttp(int code);

  /// No description provided for @aiSuggestErrorInternal.
  ///
  /// In en, this message translates to:
  /// **'Request failed due to an internal error.'**
  String get aiSuggestErrorInternal;

  /// No description provided for @aiSuggestErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Request failed.'**
  String get aiSuggestErrorUnknown;

  /// No description provided for @aiSuggestSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are an expert in file cleanup. Analyze the provided file/folder information, focusing on whether deletion is recommended and what serious consequences deletion may cause.\n\nOutput requirements:\n- Plain text only (no Markdown, no bold, no bullet points).\n- You must strictly use the following 3 tags (tags must be output verbatim, in order), and write content after each tag:\n[[DCF_SUMMARY]]\n(one short summary)\n[[DCF_ADVICE]]\n(one short deletion advice)\n[[DCF_END]]\n- Output ONLY the tags and their contents. Output nothing else.\n- Within 200 words.'**
  String get aiSuggestSystemPrompt;

  /// No description provided for @aiSuggestUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get aiSuggestUnknown;

  /// No description provided for @aiSuggestUserPromptFile.
  ///
  /// In en, this message translates to:
  /// **'File info:\nPath: {path}\nName: {name}\nTotal size (allocated on disk): {sizeText} ({sizeBytes}B)\nModified: {modified}\nAccessed: {accessed}\nChanged: {changed}'**
  String aiSuggestUserPromptFile(String path, String name, String sizeText,
      int sizeBytes, String modified, String accessed, String changed);

  /// No description provided for @aiSuggestUserPromptFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder info:\nPath: {path}\nName: {name}\nTotal size (allocated on disk): {sizeText} ({sizeBytes}B)\nModified: {modified}\nAccessed: {accessed}\nChanged: {changed}\n\nTop 10 largest direct children (non-recursive):\n{top10}\n\nNote: If a child name starts with \"*\", it may be a hard-link duplicate; disk usage may have already been counted elsewhere.'**
  String aiSuggestUserPromptFolder(
      String path,
      String name,
      String sizeText,
      int sizeBytes,
      String modified,
      String accessed,
      String changed,
      String top10);

  /// No description provided for @aiSuggestParsedSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get aiSuggestParsedSummaryLabel;

  /// No description provided for @aiSuggestParsedAdviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get aiSuggestParsedAdviceLabel;

  /// No description provided for @aiSuggestDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This suggestion is generated by AI and is not affiliated with this app. You are solely responsible. Please proceed with caution.'**
  String get aiSuggestDisclaimer;

  /// No description provided for @aiSuggestTop10Empty.
  ///
  /// In en, this message translates to:
  /// **'- (empty)'**
  String get aiSuggestTop10Empty;

  /// No description provided for @aiConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get aiConfigTitle;

  /// No description provided for @aiConfigBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get aiConfigBaseUrlLabel;

  /// No description provided for @aiConfigBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. https://api.openai.com/v1'**
  String get aiConfigBaseUrlHint;

  /// No description provided for @aiConfigModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiConfigModelLabel;

  /// No description provided for @aiConfigModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. gpt-4o-mini'**
  String get aiConfigModelHint;

  /// No description provided for @aiConfigApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get aiConfigApiKeyLabel;

  /// No description provided for @aiConfigValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get aiConfigValidating;

  /// No description provided for @aiConfigValidateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Validation failed'**
  String get aiConfigValidateFailedTitle;

  /// No description provided for @aiConfigSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Configured successfully!'**
  String get aiConfigSuccessTitle;

  /// No description provided for @aiConfigErrorIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Configuration is incomplete.'**
  String get aiConfigErrorIncomplete;

  /// No description provided for @aiConfigErrorBadUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL is invalid.'**
  String get aiConfigErrorBadUrl;

  /// No description provided for @aiConfigErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out.'**
  String get aiConfigErrorTimeout;

  /// No description provided for @aiConfigErrorConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed.'**
  String get aiConfigErrorConnectFailed;

  /// No description provided for @aiConfigErrorHttpUnknown.
  ///
  /// In en, this message translates to:
  /// **'Request failed (HTTP error).'**
  String get aiConfigErrorHttpUnknown;

  /// No description provided for @aiConfigErrorHttp.
  ///
  /// In en, this message translates to:
  /// **'Request failed (HTTP {code}).'**
  String aiConfigErrorHttp(int code);

  /// No description provided for @aiConfigErrorInternal.
  ///
  /// In en, this message translates to:
  /// **'Validation failed due to an internal error.'**
  String get aiConfigErrorInternal;

  /// No description provided for @aiConfigErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Validation failed.'**
  String get aiConfigErrorUnknown;

  /// No description provided for @menuOpenInFileManager.
  ///
  /// In en, this message translates to:
  /// **'Open in File Manager'**
  String get menuOpenInFileManager;

  /// No description provided for @menuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menuDelete;

  /// No description provided for @menuPermanentDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete'**
  String get menuPermanentDelete;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed.'**
  String get deleteFailed;

  /// No description provided for @permanentDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Permanent delete failed.'**
  String get permanentDeleteFailed;

  /// No description provided for @binNameMac.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get binNameMac;

  /// No description provided for @binNameWindows.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin'**
  String get binNameWindows;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteToBinConfirmPrimaryFile.
  ///
  /// In en, this message translates to:
  /// **'This will move \"{name}\" to {bin}.'**
  String deleteToBinConfirmPrimaryFile(String name, String bin);

  /// No description provided for @deleteToBinConfirmPrimaryFolder.
  ///
  /// In en, this message translates to:
  /// **'This will move the folder \"{name}\" to {bin}.'**
  String deleteToBinConfirmPrimaryFolder(String name, String bin);

  /// No description provided for @deleteToBinConfirmUndo.
  ///
  /// In en, this message translates to:
  /// **'You can undo this from {bin}.'**
  String deleteToBinConfirmUndo(String bin);

  /// No description provided for @deleteToBinConfirmReleaseSpace.
  ///
  /// In en, this message translates to:
  /// **'Only after you empty {bin} will the storage space be fully freed.'**
  String deleteToBinConfirmReleaseSpace(String bin);

  /// No description provided for @permanentDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete?'**
  String get permanentDeleteConfirmTitle;

  /// No description provided for @permanentDeleteConfirmMessageFile.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{name}\".'**
  String permanentDeleteConfirmMessageFile(String name);

  /// No description provided for @permanentDeleteConfirmMessageFolder.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the folder \"{name}\" and all of its contents.'**
  String permanentDeleteConfirmMessageFolder(String name);

  /// No description provided for @permanentDeleteIrreversibleWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone!'**
  String get permanentDeleteIrreversibleWarning;

  /// No description provided for @counterPrompt.
  ///
  /// In en, this message translates to:
  /// **'You have pushed the button this many times:'**
  String get counterPrompt;

  /// No description provided for @incrementTooltip.
  ///
  /// In en, this message translates to:
  /// **'Increment'**
  String get incrementTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
