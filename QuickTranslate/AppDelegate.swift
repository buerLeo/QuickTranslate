import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var status = "就绪 · ⌘⇧A 翻译选中文本"
    @Published var isBusy = false
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    let hotKeyManager = HotKeyManager()
    let selectionService = TextSelectionService()
    let ollamaClient = OllamaClient()
    private(set) var popupController: TranslationPopupController!

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        popupController = TranslationPopupController()
        hotKeyManager.onTrigger = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.translateSelection()
            }
        }
        hotKeyManager.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.stop()
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        model.status = "请在系统设置 → 隐私与安全性 → 辅助功能中打开 QuickTranslate"
    }

    func translateSelection() async {
        guard !model.isBusy else { return }
        guard isAccessibilityTrusted else {
            model.status = "需要“辅助功能”权限才能读取选中文本"
            popupController.showError("请在系统设置 → 隐私与安全性 → 辅助功能中允许 QuickTranslate，然后退出并重新启动应用。")
            requestAccessibilityPermission()
            return
        }

        model.isBusy = true
        model.status = "正在读取选中文本…"
        defer { model.isBusy = false }

        do {
            let selectedText = try await selectionService.readSelectedText()
            guard !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw QuickTranslateError.noSelection
            }

            popupController.showLoading(sourceText: selectedText)
            model.status = "正在翻译…"
            let translation = try await ollamaClient.translate(selectedText)
            model.status = "翻译完成 · ⌘⇧A 继续翻译"
            popupController.show(
                sourceText: selectedText,
                translatedText: translation,
                engineName: "Qwen3 4B Instruct · Ollama"
            )
        } catch {
            let message = userMessage(for: error)
            model.status = message
            popupController.showError(message)
        }
    }

    private func userMessage(for error: Error) -> String {
        if let error = error as? QuickTranslateError {
            switch error {
            case .accessibilityDenied:
                return "需要“辅助功能”权限"
            case .noSelection:
                return "没有读取到选中文本"
            case .ollamaUnavailable:
                return "Ollama 未启动，请先运行 ollama serve"
            case .modelMissing:
                return "Qwen3 4B Instruct 尚未下载，请运行 ollama pull qwen3:4b-instruct"
            case .invalidResponse:
                return "Ollama 返回了无效结果"
            case .requestFailed(let reason):
                return "翻译失败：\(reason)"
            }
        }
        return "翻译失败：\(error.localizedDescription)"
    }
}
