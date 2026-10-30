# QuickTranslate

QuickTranslate 是一款 macOS 菜单栏翻译工具。选中英文文本后，按 **⌘⇧A**，应用会调用本机 Ollama，将文本翻译为简体中文，并在鼠标附近显示结果。

## 运行要求

- macOS 14 或更高版本。
- 当前已在 Apple Silicon（arm64）Mac 上构建验证；Intel Mac 尚未验证。
- [Ollama](https://ollama.com/download) 已安装并运行。
- 已下载 Qwen3 4B Instruct：

```bash
ollama pull qwen3:4b-instruct
```

应用请求本机 `http://127.0.0.1:11434/api/generate`。模型名称目前写在 `QuickTranslate/OllamaClient.swift` 中。

## 使用方法

1. 启动 Ollama 和 QuickTranslate。
2. 在其他应用中选中要翻译的英文文本。
3. 按 **⌘⇧A**，或从菜单栏点击“翻译当前选中文本”。
4. 在弹出的窗口中查看译文；点击窗口外部可关闭它。

首次使用时，请在“系统设置 → 隐私与安全性 → 辅助功能”中允许 QuickTranslate，然后退出并重新启动应用。应用通过模拟复制读取选中文本，并在读取后恢复原有剪贴板内容。

## 从源码构建

项目使用 Swift Package Manager，要求 Swift 6 工具链。安装 Xcode 或 Xcode Command Line Tools 后，在仓库根目录执行：

```bash
swift build -c release
```

可执行文件位于 `.build/release/QuickTranslate`。本地打包菜单栏 `.app`：

```bash
mkdir -p dist/QuickTranslate.app/Contents/MacOS
cp .build/release/QuickTranslate dist/QuickTranslate.app/Contents/MacOS/
cp QuickTranslate/Info.plist dist/QuickTranslate.app/Contents/
codesign --force --sign - dist/QuickTranslate.app
open dist/QuickTranslate.app
```

`Info.plist` 中的 `LSUIElement` 设置使应用以菜单栏模式运行。上面的签名仅用于本地测试；若要向其他用户分发应用，还需使用适当的开发者签名和公证。

## 项目结构

```text
Package.swift                 Swift Package 配置
QuickTranslate/              Swift 源码与 Info.plist
```

## 数据处理

选中的文本会发送给本机 Ollama 服务进行翻译。首次下载模型需要网络连接；翻译请求使用本机地址。

## 当前限制

翻译方向（英文到简体中文）、模型名称和快捷键目前写在源码中。修改后需要重新构建应用。
