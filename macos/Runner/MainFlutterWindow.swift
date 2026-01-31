import Cocoa
import FlutterMacOS
import Foundation
import Darwin

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "dcf_cleaner/fs",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "listDirectory":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing 'path'.",
              details: nil
            )
          )
          return
        }

        DispatchQueue.global(qos: .userInitiated).async {
          let fm = FileManager.default
          var out: [[String: Any]] = []
          do {
            let names = try fm.contentsOfDirectory(atPath: path)
            out.reserveCapacity(names.count)

            for name in names {
              let childPath = (path as NSString).appendingPathComponent(name)
              var st = stat()
              let ok = childPath.withCString { Darwin.lstat($0, &st) == 0 }
              if !ok { continue }

              let mode = st.st_mode & S_IFMT
              let type: String
              if mode == S_IFDIR {
                type = "directory"
              } else if mode == S_IFREG {
                type = "file"
              } else if mode == S_IFLNK {
                type = "link"
              } else {
                type = "other"
              }

              let dev = UInt64(bitPattern: Int64(st.st_dev))
              let ino = UInt64(st.st_ino)
              let fileId = String(format: "mac:%016llx:%016llx", dev, ino)

              let sizeBytes: Int
              if type == "file" {
                // Allocated size (aka "size on disk"): st_blocks is in 512-byte units.
                let allocated = Int64(st.st_blocks) * 512
                sizeBytes = Int(allocated)
              } else {
                sizeBytes = 0
              }

              out.append([
                "path": childPath,
                "name": name,
                "type": type,
                "sizeBytes": sizeBytes,
                "fileId": fileId,
              ])
            }

            DispatchQueue.main.async {
              result(out)
            }
          } catch {
            DispatchQueue.main.async {
              result(
                FlutterError(
                  code: "LIST_FAILED",
                  message: "Failed to list directory.",
                  details: String(describing: error)
                )
              )
            }
          }
        }
      case "trashItem":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(
            FlutterError(
              code: "BAD_ARGS",
              message: "Missing 'path'.",
              details: nil
            )
          )
          return
        }

        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let url = URL(fileURLWithPath: path)
            var _unused: NSURL? = nil
            try FileManager.default.trashItem(at: url, resultingItemURL: &_unused)
            DispatchQueue.main.async { result(true) }
          } catch {
            DispatchQueue.main.async {
              result(
                FlutterError(
                  code: "TRASH_FAILED",
                  message: "Failed to move item to Trash.",
                  details: String(describing: error)
                )
              )
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    if let screen = NSScreen.main {
      let screenSize = screen.visibleFrame.size
      let maxWidth = screenSize.width - 120
      let maxHeight = screenSize.height - 120

      let width = min(1200, maxWidth)
      let height = min(800, maxHeight)

      self.minSize = NSSize(width: width, height: height)

      let x = (screenSize.width - width) / 2 + screen.visibleFrame.origin.x
      let y = (screenSize.height - height) / 2 + screen.visibleFrame.origin.y
      self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    super.awakeFromNib()
  }
}
