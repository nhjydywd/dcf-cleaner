#include "flutter_window.h"

#include <optional>
#include <algorithm>
#include <windows.h>
#include <shlobj.h>
#include <shellapi.h>
#include <shlwapi.h>
#include <string>
#include <vector>
#include <thread>
#include <future>
#include <cstdio>

#include "flutter/generated_plugin_registrant.h"

#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "shell32.lib")

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Set up the method channel for file system operations.
  SetupMethodChannel();

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_GETMINMAXINFO: {
      MINMAXINFO* minMaxInfo = reinterpret_cast<MINMAXINFO*>(lparam);
      int screenWidth = GetSystemMetrics(SM_CXSCREEN);
      int screenHeight = GetSystemMetrics(SM_CYSCREEN);
      int maxWidth = screenWidth - 120;
      int maxHeight = screenHeight - 120;
      minMaxInfo->ptMinTrackSize.x = std::min(1200, maxWidth);
      minMaxInfo->ptMinTrackSize.y = std::min(800, maxHeight);
      return 0;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

// Helper function to convert wide string to UTF-8
static std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return std::string();
  int size_needed = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(),
                                        static_cast<int>(wide.size()),
                                        nullptr, 0, nullptr, nullptr);
  std::string result(size_needed, 0);
  WideCharToMultiByte(CP_UTF8, 0, wide.c_str(),
                      static_cast<int>(wide.size()),
                      &result[0], size_needed, nullptr, nullptr);
  return result;
}

// Helper function to convert UTF-8 to wide string
static std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int size_needed = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                                        static_cast<int>(utf8.size()),
                                        nullptr, 0);
  std::wstring result(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                      static_cast<int>(utf8.size()),
                      &result[0], size_needed);
  return result;
}

// List directory contents
static flutter::EncodableValue ListDirectory(const std::string& path) {
  std::wstring widePath = Utf8ToWide(path);

  // Ensure path ends with backslash for FindFirstFile
  if (!widePath.empty() && widePath.back() != L'\\' && widePath.back() != L'/') {
    widePath += L'\\';
  }
  widePath += L'*';

  WIN32_FIND_DATAW findData;
  HANDLE hFind = FindFirstFileW(widePath.c_str(), &findData);

  if (hFind == INVALID_HANDLE_VALUE) {
    DWORD error = GetLastError();
    if (error == ERROR_FILE_NOT_FOUND || error == ERROR_PATH_NOT_FOUND) {
      // Empty directory or not found - return empty list
      return flutter::EncodableValue(flutter::EncodableList());
    }
    throw std::runtime_error("Failed to list directory");
  }

  flutter::EncodableList results;
  std::wstring basePath = Utf8ToWide(path);
  if (!basePath.empty() && basePath.back() != L'\\' && basePath.back() != L'/') {
    basePath += L'\\';
  }

  do {
    std::wstring fileName(findData.cFileName);

    // Skip . and ..
    if (fileName == L"." || fileName == L"..") {
      continue;
    }

    std::wstring fullPath = basePath + fileName;
    std::string fullPathUtf8 = WideToUtf8(fullPath);
    std::string fileNameUtf8 = WideToUtf8(fileName);

    // Determine file type
    std::string type;
    if (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
      type = "directory";
    } else if (findData.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) {
      type = "link";
    } else {
      type = "file";
    }

    // Get file size (allocated size on disk)
    int64_t sizeBytes = 0;
    if (type == "file") {
      // Try to get compressed file size (actual disk usage)
      DWORD highSize = 0;
      DWORD lowSize = GetCompressedFileSizeW(fullPath.c_str(), &highSize);
      if (lowSize != INVALID_FILE_SIZE || GetLastError() == NO_ERROR) {
        sizeBytes = (static_cast<int64_t>(highSize) << 32) | lowSize;
      } else {
        // Fall back to logical file size
        sizeBytes = (static_cast<int64_t>(findData.nFileSizeHigh) << 32) |
                    findData.nFileSizeLow;
      }
    }

    // Get file ID for hard link detection
    std::string fileId;
    HANDLE hFile = CreateFileW(
        fullPath.c_str(),
        0,  // No access needed, just query info
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        nullptr,
        OPEN_EXISTING,
        (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
            ? FILE_FLAG_BACKUP_SEMANTICS : 0,
        nullptr);

    if (hFile != INVALID_HANDLE_VALUE) {
      BY_HANDLE_FILE_INFORMATION fileInfo;
      if (GetFileInformationByHandle(hFile, &fileInfo)) {
        // Format: win:VolumeSerialNumber:FileIndexHigh:FileIndexLow
        char idBuffer[64];
        snprintf(idBuffer, sizeof(idBuffer), "win:%08lx:%08lx%08lx",
                 fileInfo.dwVolumeSerialNumber,
                 fileInfo.nFileIndexHigh,
                 fileInfo.nFileIndexLow);
        fileId = idBuffer;
      }
      CloseHandle(hFile);
    }

    flutter::EncodableMap item;
    item[flutter::EncodableValue("path")] = flutter::EncodableValue(fullPathUtf8);
    item[flutter::EncodableValue("name")] = flutter::EncodableValue(fileNameUtf8);
    item[flutter::EncodableValue("type")] = flutter::EncodableValue(type);
    item[flutter::EncodableValue("sizeBytes")] = flutter::EncodableValue(sizeBytes);
    item[flutter::EncodableValue("fileId")] = flutter::EncodableValue(fileId);

    results.push_back(flutter::EncodableValue(item));

  } while (FindNextFileW(hFind, &findData));

  FindClose(hFind);

  return flutter::EncodableValue(results);
}

// Move item to Recycle Bin
static bool TrashItem(const std::string& path) {
  std::wstring widePath = Utf8ToWide(path);

  // SHFileOperation requires double-null terminated string
  std::vector<wchar_t> from(widePath.begin(), widePath.end());
  from.push_back(L'\0');
  from.push_back(L'\0');

  SHFILEOPSTRUCTW fileOp = {};
  fileOp.wFunc = FO_DELETE;
  fileOp.pFrom = from.data();
  fileOp.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_NOERRORUI | FOF_SILENT;

  int result = SHFileOperationW(&fileOp);

  if (result != 0 || fileOp.fAnyOperationsAborted) {
    return false;
  }

  return true;
}

void FlutterWindow::SetupMethodChannel() {
  fs_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "dcf_cleaner/fs",
      &flutter::StandardMethodCodec::GetInstance());

  fs_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

        if (call.method_name() == "listDirectory") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (!args) {
            result->Error("BAD_ARGS", "Missing arguments.");
            return;
          }

          auto pathIt = args->find(flutter::EncodableValue("path"));
          if (pathIt == args->end()) {
            result->Error("BAD_ARGS", "Missing 'path'.");
            return;
          }

          const auto* pathValue = std::get_if<std::string>(&pathIt->second);
          if (!pathValue) {
            result->Error("BAD_ARGS", "'path' must be a string.");
            return;
          }

          std::string path = *pathValue;
          auto resultPtr = std::move(result);

          // Run in background thread to avoid blocking UI
          std::thread([path, resultPtr = std::move(resultPtr)]() mutable {
            try {
              auto listResult = ListDirectory(path);
              // Post result back to main thread
              resultPtr->Success(listResult);
            } catch (const std::exception& e) {
              resultPtr->Error("LIST_FAILED", "Failed to list directory.",
                              flutter::EncodableValue(e.what()));
            }
          }).detach();

        } else if (call.method_name() == "trashItem") {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (!args) {
            result->Error("BAD_ARGS", "Missing arguments.");
            return;
          }

          auto pathIt = args->find(flutter::EncodableValue("path"));
          if (pathIt == args->end()) {
            result->Error("BAD_ARGS", "Missing 'path'.");
            return;
          }

          const auto* pathValue = std::get_if<std::string>(&pathIt->second);
          if (!pathValue) {
            result->Error("BAD_ARGS", "'path' must be a string.");
            return;
          }

          std::string path = *pathValue;
          auto resultPtr = std::move(result);

          // Run in background thread
          std::thread([path, resultPtr = std::move(resultPtr)]() mutable {
            if (TrashItem(path)) {
              resultPtr->Success(flutter::EncodableValue(true));
            } else {
              resultPtr->Error("TRASH_FAILED", "Failed to move item to Recycle Bin.");
            }
          }).detach();

        } else {
          result->NotImplemented();
        }
      });
}
