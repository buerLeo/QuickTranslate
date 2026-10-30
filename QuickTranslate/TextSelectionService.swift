import AppKit

enum QuickTranslateError: LocalizedError {
    case accessibilityDenied
    case noSelection
    case ollamaUnavailable
    case modelMissing
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessibilityDenied: return "辅助功能权限不足"
        case .noSelection: return "没有读取到选中文本"
        case .ollamaUnavailable: return "Ollama 未启动"
        case .modelMissing: return "翻译模型尚未下载"
        case .invalidResponse: return "返回结果无效"
        case .requestFailed(let reason): return reason
        }
    }
}

final class TextSelectionService {
    private struct ClipboardItem {
        let representations: [(NSPasteboard.PasteboardType, Data)]
    }

    func readSelectedText() async throws -> String {
        guard AXIsProcessTrusted() else { throw QuickTranslateError.accessibilityDenied }

        let pasteboard = NSPasteboard.general
        let snapshot = snapshotPasteboard(pasteboard)
        defer { restore(snapshot, to: pasteboard) }

        postCopyShortcut()
        try await Task.sleep(for: .milliseconds(180))

        guard let text = pasteboard.string(forType: .string) else {
            throw QuickTranslateError.noSelection
        }
        return text
    }

    private func postCopyShortcut() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func snapshotPasteboard(_ pasteboard: NSPasteboard) -> [ClipboardItem] {
        (pasteboard.pasteboardItems ?? []).map { item in
            let representations = item.types.compactMap { type -> (NSPasteboard.PasteboardType, Data)? in
                guard let data = item.data(forType: type) else { return nil }
                return (type, data)
            }
            return ClipboardItem(representations: representations)
        }
    }

    private func restore(_ snapshot: [ClipboardItem], to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        let items = snapshot.map { saved -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in saved.representations {
                item.setData(data, forType: type)
            }
            return item
        }
        if !items.isEmpty { pasteboard.writeObjects(items) }
    }
}
