# ShadowTranslate

<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="ShadowTranslate Icon">
</p>

<p align="center">
  <strong>macOS 上的本地 AI 翻译工具</strong> — 选中即译，一键替换
</p>

<p align="center">
  <a href="#功能特性">功能特性</a> •
  <a href="#如何使用">如何使用</a> •
  <a href="#快捷键">快捷键</a> •
  <a href="#系统要求">系统要求</a> •
  <a href="#安装">安装</a> •
  <a href="#构建">构建</a> •
  <a href="#技术架构">技术架构</a> •
  <a href="#许可证">许可证</a>
</p>

---

## 📖 简介

ShadowTranslate 是一款专为 macOS 设计的本地 AI 翻译应用。它利用 MLX 框架在本地运行 Google 的 Gemma 4B 模型，无需联网即可实现高质量翻译。应用通过 Accessibility API 读取选中文本，并在原位置替换翻译结果。

**核心优势：**
- 🔒 **完全本地运行** — 文本不发送到云端，保护隐私
- ⚡ **即时翻译** — 选中文字后一键翻译
- 🔄 **原位替换** — 自动替换原文，保持写作流畅
- 🌐 **多语言支持** — 支持中文、英文、日文、韩文、法文、德文、西班牙文等

---

## ✨ 功能特性

| 特性 | 描述 |
|------|------|
| 🎯 **选中文本翻译** | 从任意应用中选中文字，一键翻译 |
| 🔄 **自动替换原文** | 将翻译结果直接替换回原位置 |
| 🌍 **自动语言检测** | 智能识别源语言，支持自动模式 |
| 📚 **翻译历史** | 保存历史记录，随时查阅 |
| 🎨 **浮动窗口** | 非激活式浮动面板，不打扰当前工作 |
| ⌨️ **全局快捷键** | 自定义快捷键，快速呼出翻译 |
| 🖥️ **菜单栏常驻** | 常驻菜单栏，随时可用 |

---

## 🚀 如何使用

### 第一步：首次启动

1. **下载应用**：从 [Releases](https://github.com/yourusername/ShadowTranslate/releases) 页面下载最新版本
2. **解压并拖入应用程序文件夹**：将 `ShadowTranslate.app` 拖到 `/Applications`
3. **首次打开**：双击应用图标，此时不会显示主窗口，而是常驻菜单栏
4. **授权辅助功能**：首次使用时会弹出系统提示，需要在「系统设置 → 隐私与安全性 → 辅助功能」中授权 ShadowTranslate

### 第二步：下载模型（首次使用）

应用首次启动时需要下载翻译模型（约 2.18GB）：

1. 点击菜单栏图标 🌐
2. 选择「偏好设置…」
3. 在「模型」标签页中，点击「下载模型」按钮
4. 等待下载完成（取决于网速，约几分钟到十几分钟）
5. 下载完成后模型状态将变为「就绪」

> 💡 **提示**：模型文件保存在本地，只需下载一次，之后可离线使用。

### 第三步：翻译文本

ShadowTranslate 提供**两种翻译方式**，可根据场景选择：

#### 方式一：快捷翻译（推荐）

这是最常用的翻译方式，适合快速翻译并替换文本：

1. **选中文字**：在任何应用（如浏览器、Word、邮件等）中选中要翻译的文本
2. **触发翻译**：
   - 按 `⌘ + ⇧ + T`（默认快捷键）
   - 或点击菜单栏图标选择「翻译选中文本」
3. **查看翻译**：浮动窗口将显示原文和译文
4. **使用结果**：
   - 点击「复制」按钮将译文复制到剪贴板
   - 点击「替换」按钮将原文直接替换为译文（如果应用支持）
5. **关闭窗口**：按 `Esc` 或点击空白处关闭浮动窗口

#### 方式二：手动输入翻译

适合需要查看历史记录或手动输入文本的场景：

1. **打开主窗口**：点击菜单栏图标 → 「打开历史窗口」
2. **输入文本**：在「原文」框中输入或粘贴要翻译的文本
3. **选择语言**：
   - 源语言：选择「自动」让应用自动检测，或手动指定
   - 目标语言：选择需要翻译成的语言
4. **开始翻译**：文本输入完成后，应用会自动开始翻译
5. **查看结果**：译文将显示在下方
6. **语言切换**：点击中间的「⇄」按钮可快速交换源语言和目标语言

### 第四步：管理翻译历史

1. **打开历史窗口**：点击菜单栏图标 → 「打开历史窗口」
2. **查看记录**：历史记录按时间倒序显示，包含原文、译文和时间戳
3. **复制条目**：点击任意历史条目可复制该条翻译
4. **搜索历史**：在历史窗口顶部搜索框中输入关键词，快速查找过往翻译

### 第五步：自定义设置

根据你的使用习惯调整应用设置：

1. **打开偏好设置**：点击菜单栏图标 → 「偏好设置…」
2. **修改快捷键**：在「快捷键」标签页中，点击想要修改的快捷键，按下新的组合键
3. **调整模型设置**：
   - 自动卸载时间：设置空闲多久后自动释放模型（节省内存）
   - 重新加载模型：如果模型出现问题，可点击「重新加载」
4. **清除历史**：在「历史」标签页中点击「清除所有历史记录」

---

## ⌨️ 快捷键

| 快捷键 | 功能 |
|--------|------|
|`⌘ + ⇧ + T`| 翻译选中文本（可自定义）|
|`Esc`| 关闭浮动窗口 |
|`⌘ + C`| 复制译文（在浮动窗口中）|
|`⌘ + R`| 替换原文（在浮动窗口中）|
|`⌘ + ,`| 打开偏好设置 |

> 💡 **自定义快捷键**：在「偏好设置 → 快捷键」中可自定义全局快捷键。

---

## 💻 系统要求

- **操作系统**：macOS 15.0 (Sequoia) 或更高版本
- **架构**：Apple Silicon (M1/M2/M3/M4) 或 Intel Mac
- **内存**：建议 8GB 及以上
- **存储空间**：约 3GB（应用 + 模型文件）
- **权限**：需要「辅助功能」权限以读取和替换选中文本

---

## 📥 安装

### 方式一：下载预编译版本（推荐）

1. 前往 [Releases](https://github.com/yourusername/ShadowTranslate/releases) 页面
2. 下载最新版本的 `ShadowTranslate.dmg`
3. 打开 DMG，将 `ShadowTranslate.app` 拖到「应用程序」文件夹
4. 从「应用程序」文件夹启动 ShadowTranslate

### 方式二：使用 Homebrew（即将支持）

```bash
brew install --cask shadow-translate
```

### 方式三：从源码构建

见下方「构建」章节。

---

## 🔨 构建

如果你想从源码构建 ShadowTranslate，需要以下环境：

### 前置依赖

- **Xcode 16.0+**（需要 Swift 6 支持）
- **macOS 15.0+**
- **xcodegen**（用于生成 Xcode 项目）

```bash
# 安装 xcodegen
brew install xcodegen
```

### 构建步骤

```bash
# 1. 克隆仓库
git clone https://github.com/yourusername/ShadowTranslate.git
cd ShadowTranslate

# 2. 生成 Xcode 项目
xcodegen generate

# 3. 构建应用
xcodebuild -workspace ShadowTranslate.xcworkspace -scheme ShadowTranslate \
  -destination 'platform=macOS' -skipPackagePluginValidation build

# 4. 运行应用
open ~/Library/Developer/Xcode/DerivedData/ShadowTranslate-*/Build/Products/Debug/ShadowTranslate.app
```

### 运行测试

```bash
xcodebuild -workspace ShadowTranslate.xcworkspace -scheme ShadowTranslate \
  -destination 'platform=macOS' -skipPackagePluginValidation test
```

> ⚠️ **注意**：本项目没有根级的 `Package.swift`，必须使用 `xcodegen` + `.xcworkspace` 方式构建，不要直接从根目录运行 `swift build`。

---

## 🏗️ 技术架构

ShadowTranslate 采用模块化架构，使用 Swift 6 严格并发模式：

```
ShadowTranslate.app
├── SharedCore         # 共享核心（语言定义、错误类型、日志）
├── InferenceKit       # MLX 推理引擎（Gemma 4B 模型）
├── PersistenceKit     # SwiftData 持久化（历史记录存储）
├── AccessibilityKit   # 辅助功能 API（文本读取/替换）
├── ModelManager       # 模型下载管理（HuggingFace Hub）
└── UIKitShared        # 共享 UI（浮动面板、SwiftUI 视图）
```

**数据流：**
```
快捷键 → AXReplacer.readSelectedText() → InferenceEngine.translate()
  → AsyncStream<String> → TranslationPopupView → AXReplacer.replaceSelectedText()
  + HistoryWriter.insert()
```

**核心技术栈：**
- **MLX Swift**: Apple Silicon 上的高效机器学习
- **SwiftData**: 本地数据持久化
- **Accessibility API**: 跨应用文本操作
- **Swift 6**: 严格并发安全

---

## 🛣️ 路线图

- [x] 基础翻译功能
- [x] 选中文本替换
- [x] 翻译历史记录
- [ ] 翻译质量优化
- [ ] 支持更多模型
- [ ] 自定义提示词
- [ ] OCR 图片翻译
- [ ] 浏览器插件
- [ ] 划词翻译增强

---

## 🤝 贡献

我们欢迎所有形式的贡献！请阅读 [AGENTS.md](AGENTS.md) 了解项目结构和贡献指南。

### 提交 Issue

如果你遇到问题或有功能建议，请[提交 Issue](https://github.com/yourusername/ShadowTranslate/issues)。

### 提交 PR

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

---

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE) 开源。

---

## 🙏 致谢

- [MLX Swift](https://github.com/ml-explore/mlx-swift) — Apple 的机器学习框架
- [mlx-swift-lm](https://github.com/ml-explore/mlx-swift-lm) — MLX 语言模型支持
- [Google Gemma](https://ai.google.dev/gemma) — 开源语言模型
- [Hugging Face](https://huggingface.co) — 模型托管与分发

---

<p align="center">
  Made with ❤️ by Henry Zhang
</p>

<p align="center">
  <a href="README_EN.md">English</a>
</p>
