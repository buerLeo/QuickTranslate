import SwiftUI

@main
struct QuickTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(appDelegate: appDelegate)
        } label: {
            Image(systemName: "bubble.left.and.bubble.right")
                .accessibilityLabel("QuickTranslate")
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuContent: View {
    let appDelegate: AppDelegate
    @ObservedObject private var model: AppModel

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        self._model = ObservedObject(wrappedValue: appDelegate.model)
    }

    var body: some View {
        Text("QuickTranslate")
            .font(.headline)

        Text(model.status)
            .foregroundStyle(.secondary)

        Divider()

        Button("翻译当前选中文本") {
            Task { await appDelegate.translateSelection() }
        }
        .keyboardShortcut("a", modifiers: [.command, .shift])

        if !appDelegate.isAccessibilityTrusted {
            Button("授予辅助功能权限") {
                appDelegate.requestAccessibilityPermission()
            }
        }

        Divider()

        Button("退出 QuickTranslate") {
            NSApplication.shared.terminate(nil)
        }
    }
}
