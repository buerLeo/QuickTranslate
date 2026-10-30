import AppKit
import SwiftUI

@MainActor
final class TranslationPopupController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private var dismissMonitor: Any?

    func showLoading(sourceText: String) {
        present(content: TranslationLoadingView(sourceText: sourceText))
    }

    func show(sourceText: String, translatedText: String, engineName: String) {
        present(content: TranslationResultView(
            sourceText: sourceText,
            translatedText: translatedText,
            engineName: engineName
        ))
    }

    func showError(_ message: String) {
        present(content: TranslationErrorView(message: message))
    }

    func close() {
        panel?.orderOut(nil)
        removeDismissMonitor()
    }

    private func present<Content: View>(content: Content) {
        close()

        let hostingView = NSHostingView(rootView: content)
        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 220),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newPanel.contentView = hostingView
        newPanel.level = .floating
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.hidesOnDeactivate = false
        newPanel.isMovableByWindowBackground = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        newPanel.delegate = self

        panel = newPanel
        position(newPanel)
        newPanel.orderFrontRegardless()
        installDismissMonitor()
    }

    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let visibleFrame = NSScreen.screens.first(where: { $0.visibleFrame.contains(mouse) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? .zero
        let preferredX = mouse.x + 14
        let preferredY = mouse.y - panel.frame.height - 16
        let x = min(max(preferredX, visibleFrame.minX + 8), visibleFrame.maxX - panel.frame.width - 8)
        let y = max(preferredY, visibleFrame.minY + 8)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func installDismissMonitor() {
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .keyDown]
        ) { [weak self] _ in
            Task { @MainActor in self?.close() }
        }
    }

    private func removeDismissMonitor() {
        if let dismissMonitor {
            NSEvent.removeMonitor(dismissMonitor)
            self.dismissMonitor = nil
        }
    }

    func windowWillClose(_ notification: Notification) {
        removeDismissMonitor()
    }

    deinit {
        if let dismissMonitor { NSEvent.removeMonitor(dismissMonitor) }
    }
}

private struct TranslationLoadingView: View {
    let sourceText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("翻译为简体中文")
                    .font(.caption.weight(.semibold))
                Spacer()
                ProgressView()
                    .controlSize(.small)
            }
            .foregroundStyle(.secondary)

            Text("正在翻译…")
                .font(.system(size: 16))

            Text(sourceText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .frame(width: 460, height: 160, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct TranslationResultView: View {
    let sourceText: String
    let translatedText: String
    let engineName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("翻译为简体中文")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(engineName)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)

            ScrollView {
                Text(translatedText)
                    .font(.system(size: 16))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 120)

            Divider()

            Text(sourceText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .frame(width: 460, height: 220)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct TranslationErrorView: View {
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("无法翻译", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text(message)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 400)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
