// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'DCF Cleaner';

  @override
  String get homeTitle => '首页';

  @override
  String get chooseFolder => '选择文件夹';

  @override
  String get reselectFolder => '重新选择';

  @override
  String get selectedFolderLabel => '已选择文件夹：';

  @override
  String currentDirectoryTitle(String path) {
    return '当前根目录：$path';
  }

  @override
  String get chooseFolderNotSupported => '当前平台不支持选择文件夹。';

  @override
  String get chooseFolderCanceled => '已取消。';

  @override
  String get chooseFolderFailed => '打开文件夹选择器失败。';

  @override
  String get chooseFolderTimedOut => '打开文件夹选择器超时。';

  @override
  String get detailTitle => '详情';

  @override
  String get detailLoadFailed => '读取文件详情失败。';

  @override
  String get detailName => '名称';

  @override
  String get detailPath => '路径';

  @override
  String get detailType => '类型';

  @override
  String get detailSize => '占用空间';

  @override
  String get detailFolderSizeCalculated => '文件夹大小（计算值）';

  @override
  String get detailModified => '修改时间';

  @override
  String get detailAccessed => '访问时间';

  @override
  String get detailChanged => '变更时间';

  @override
  String get detailTypeFile => '文件';

  @override
  String get detailTypeDirectory => '文件夹';

  @override
  String get detailTypeLink => '链接';

  @override
  String get detailTypeOther => '其他';

  @override
  String get aiSuggestButton => 'AI建议';

  @override
  String get aiSuggestLoading => '生成中...';

  @override
  String get aiSuggestFailedTitle => 'AI建议失败';

  @override
  String get aiSuggestErrorConfigIncomplete => 'AI配置未填写完整。';

  @override
  String get aiSuggestErrorBadUrl => 'Base URL 不合法。';

  @override
  String get aiSuggestErrorTimeout => '请求超时。';

  @override
  String get aiSuggestErrorConnectFailed => '连接失败。';

  @override
  String get aiSuggestErrorHttpUnknown => '请求失败（HTTP错误）。';

  @override
  String aiSuggestErrorHttp(int code) {
    return '请求失败（HTTP $code）。';
  }

  @override
  String get aiSuggestErrorInternal => '请求失败（软件内部错误）。';

  @override
  String get aiSuggestErrorUnknown => '请求失败。';

  @override
  String get aiSuggestSystemPrompt =>
      '你是一名资深文件清理专家。请基于用户提供的文件/文件夹信息进行分析，重点判断是否建议删除、以及删除可能带来的严重后果。\n\n输出要求：\n- 纯文本输出（不要 Markdown，不要加粗，不要列表符号）。\n- 必须严格使用以下三段标记（标记必须原样输出，顺序不变），并在标记后写内容：\n[[DCF_SUMMARY]]\n(一段简要说明)\n[[DCF_ADVICE]]\n(一段删除建议)\n[[DCF_END]]\n- 只允许输出上述标记和对应内容，不要输出任何其它内容。\n- 总字数 200 字以内。';

  @override
  String get aiSuggestUnknown => '未知';

  @override
  String aiSuggestUserPromptFile(String path, String name, String sizeText,
      int sizeBytes, String modified, String accessed, String changed) {
    return '文件信息：\n路径：$path\n名称：$name\n总大小（磁盘分配）：$sizeText（${sizeBytes}B）\n修改时间：$modified\n访问时间：$accessed\n变更时间：$changed';
  }

  @override
  String aiSuggestUserPromptFolder(
      String path,
      String name,
      String sizeText,
      int sizeBytes,
      String modified,
      String accessed,
      String changed,
      String top10) {
    return '文件夹信息：\n路径：$path\n名称：$name\n总大小（磁盘分配）：$sizeText（${sizeBytes}B）\n修改时间：$modified\n访问时间：$accessed\n变更时间：$changed\n\n前10个最大的子项（仅直系，不递归）：\n$top10\n\n说明：若子项名称前带\"*\"，表示它可能是硬链接重复项，空间可能已在其它位置计入。';
  }

  @override
  String get aiSuggestParsedSummaryLabel => '简介';

  @override
  String get aiSuggestParsedAdviceLabel => '建议';

  @override
  String get aiSuggestDisclaimer => '该建议为AI生成, 与本软件无关. 您是唯一责任人, 请谨慎操作';

  @override
  String get aiSuggestTop10Empty => '- （空）';

  @override
  String get aiConfigTitle => 'AI配置';

  @override
  String get aiConfigBaseUrlLabel => 'Base URL';

  @override
  String get aiConfigBaseUrlHint => '例如 https://api.openai.com/v1';

  @override
  String get aiConfigModelLabel => '模型';

  @override
  String get aiConfigModelHint => '例如 gpt-4o-mini';

  @override
  String get aiConfigApiKeyLabel => 'API Key';

  @override
  String get aiConfigValidating => '验证中';

  @override
  String get aiConfigValidateFailedTitle => '验证失败';

  @override
  String get aiConfigSuccessTitle => '配置成功!';

  @override
  String get aiConfigErrorIncomplete => '配置未填写完整。';

  @override
  String get aiConfigErrorBadUrl => 'Base URL 不合法。';

  @override
  String get aiConfigErrorTimeout => '请求超时。';

  @override
  String get aiConfigErrorConnectFailed => '连接失败。';

  @override
  String get aiConfigErrorHttpUnknown => '请求失败（HTTP错误）。';

  @override
  String aiConfigErrorHttp(int code) {
    return '请求失败（HTTP $code）。';
  }

  @override
  String get aiConfigErrorInternal => '验证失败（软件内部错误）。';

  @override
  String get aiConfigErrorUnknown => '验证失败。';

  @override
  String get menuOpenInFileManager => '在文件管理器中打开';

  @override
  String get menuDelete => '删除';

  @override
  String get menuPermanentDelete => '彻底删除';

  @override
  String get commonOk => '确定';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确定';

  @override
  String get deleteFailed => '删除失败。';

  @override
  String get permanentDeleteFailed => '彻底删除失败。';

  @override
  String get binNameMac => '废纸篓';

  @override
  String get binNameWindows => '回收站';

  @override
  String get deleteConfirmTitle => '确认删除？';

  @override
  String deleteToBinConfirmPrimaryFile(String name, String bin) {
    return '将“$name”移到$bin。';
  }

  @override
  String deleteToBinConfirmPrimaryFolder(String name, String bin) {
    return '将文件夹“$name”移到$bin。';
  }

  @override
  String deleteToBinConfirmUndo(String bin) {
    return '您可以从$bin中撤销删除。';
  }

  @override
  String deleteToBinConfirmReleaseSpace(String bin) {
    return '只有在您清空$bin后，存储空间才会彻底被释放。';
  }

  @override
  String get permanentDeleteConfirmTitle => '确认彻底删除？';

  @override
  String permanentDeleteConfirmMessageFile(String name) {
    return '将彻底删除“$name”。';
  }

  @override
  String permanentDeleteConfirmMessageFolder(String name) {
    return '将彻底删除文件夹“$name”及其所有内容。';
  }

  @override
  String get permanentDeleteIrreversibleWarning => '该操作无法撤销!';

  @override
  String get counterPrompt => '你已经点击按钮这么多次：';

  @override
  String get incrementTooltip => '加一';
}
