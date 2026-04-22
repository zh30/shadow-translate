# ShadowTranslate

<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="ShadowTranslate Icon">
</p>

<p align="center">
  <strong>Local AI Translation for macOS</strong> — Select, Translate, Replace
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#how-to-use">How to Use</a> •
  <a href="#keyboard-shortcuts">Shortcuts</a> •
  <a href="#system-requirements">Requirements</a> •
  <a href="#installation">Installation</a> •
  <a href="#building">Building</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#license">License</a>
</p>

---

## 📖 Introduction

ShadowTranslate is a local AI translation app designed specifically for macOS. It uses the MLX framework to run Google's Gemma 4B model locally, enabling high-quality translation without an internet connection. The app reads selected text via Accessibility API and replaces it with the translation in-place.

**Key Advantages:**
- 🔒 **Fully Local** — Text never leaves your device, protecting your privacy
- ⚡ **Instant Translation** — One-click translation of selected text
- 🔄 **Replace in Place** — Automatically replaces original text, maintaining workflow
- 🌐 **Multi-language Support** — Chinese, English, Japanese, Korean, French, German, Spanish, and more

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎯 **Selected Text Translation** | Select text in any app and translate instantly |
| 🔄 **Automatic Replacement** | Replace original text directly with translation |
| 🌍 **Auto Language Detection** | Smart source language identification with auto mode |
| 📚 **Translation History** | Save history for easy reference |
| 🎨 **Floating Window** | Non-activating floating panel that doesn't interrupt your work |
| ⌨️ **Global Shortcuts** | Customizable shortcuts for quick translation |
| 🖥️ **Menu Bar Resident** | Lives in the menu bar, always available |

---

## 🚀 How to Use

### Step 1: First Launch

1. **Download the App**: Download the latest version from [Releases](https://github.com/yourusername/ShadowTranslate/releases)
2. **Install**: Drag `ShadowTranslate.app` to your `/Applications` folder
3. **First Open**: Double-click the app icon. No main window will appear; the app lives in the menu bar
4. **Authorize Accessibility**: On first use, a system prompt will appear. Go to "System Settings → Privacy & Security → Accessibility" to authorize ShadowTranslate

### Step 2: Download the Model (First Time Only)

The app needs to download the translation model (~2.18GB) on first launch:

1. Click the menu bar icon 🌐
2. Select "Preferences..."
3. In the "Model" tab, click the "Download Model" button
4. Wait for the download to complete (minutes to tens of minutes depending on connection)
5. The model status will change to "Ready" when complete

> 💡 **Tip**: Model files are stored locally. Only needs to be downloaded once, can be used offline afterward.

### Step 3: Translate Text

ShadowTranslate offers **two translation modes** to suit different scenarios:

#### Method 1: Quick Translation (Recommended)

This is the most common way to translate and replace text:

1. **Select Text**: In any app (browser, Word, email, etc.), select the text you want to translate
2. **Trigger Translation**:
   - Press `⌘ + ⇧ + T` (default shortcut)
   - Or click the menu bar icon and select "Translate Selected Text"
3. **View Translation**: A floating window will show the source and translated text
4. **Use the Result**:
   - Click "Copy" button to copy the translation to clipboard
   - Click "Replace" button to replace the original text with the translation (if the app supports it)
5. **Close Window**: Press `Esc` or click outside the window to close

#### Method 2: Manual Input Translation

Ideal for viewing history or manually entering text:

1. **Open Main Window**: Click menu bar icon → "Open History Window"
2. **Enter Text**: Type or paste text in the "Source" box
3. **Select Languages**:
   - Source Language: Choose "Auto" for automatic detection, or manually specify
   - Target Language: Choose the language to translate to
4. **Start Translation**: Translation begins automatically when text is entered
5. **View Result**: The translation appears in the bottom section
6. **Swap Languages**: Click the "⇄" button to quickly swap source and target languages

### Step 4: Manage Translation History

1. **Open History Window**: Click menu bar icon → "Open History Window"
2. **View Records**: History is displayed in reverse chronological order, with source text, translation, and timestamp
3. **Copy Entry**: Click any history entry to copy that translation
4. **Search History**: Type keywords in the search box at the top of the history window to find past translations

### Step 5: Customize Settings

Adjust the app to your preferences:

1. **Open Preferences**: Click menu bar icon → "Preferences..."
2. **Modify Shortcuts**: In the "Shortcuts" tab, click the shortcut you want to change and press your preferred key combination
3. **Adjust Model Settings**:
   - Auto-unload time: Set how long before the model is automatically released (saves memory)
   - Reload Model: Click "Reload" if the model encounters issues
4. **Clear History**: Click "Clear All History" in the "History" tab

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Function |
|----------|----------|
| `⌘ + ⇧ + T` | Translate selected text (customizable) |
| `Esc` | Close floating window |
| `⌘ + C` | Copy translation (in floating window) |
| `⌘ + R` | Replace original text (in floating window) |
| `⌘ + ,` | Open Preferences |

> 💡 **Custom Shortcuts**: Customize global shortcuts in "Preferences → Shortcuts".

---

## 💻 System Requirements

- **OS**: macOS 15.0 (Sequoia) or later
- **Architecture**: Apple Silicon (M1/M2/M3/M4) or Intel Mac
- **Memory**: 8GB or more recommended
- **Storage**: ~3GB (app + model files)
- **Permissions**: "Accessibility" permission required to read and replace selected text

---

## 📥 Installation

### Method 1: Download Pre-built Release (Recommended)

1. Go to the [Releases](https://github.com/yourusername/ShadowTranslate/releases) page
2. Download the latest `ShadowTranslate.dmg`
3. Open the DMG and drag `ShadowTranslate.app` to your "Applications" folder
4. Launch ShadowTranslate from the "Applications" folder

### Method 2: Using Homebrew (Coming Soon)

```bash
brew install --cask shadow-translate
```

### Method 3: Build from Source

See the "Building" section below.

---

## 🔨 Building

If you want to build ShadowTranslate from source, you'll need:

### Prerequisites

- **Xcode 16.0+** (requires Swift 6 support)
- **macOS 15.0+**
- **xcodegen** (for generating the Xcode project)

```bash
# Install xcodegen
brew install xcodegen
```

### Build Steps

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/ShadowTranslate.git
cd ShadowTranslate

# 2. Generate Xcode project
xcodegen generate

# 3. Build the app
xcodebuild -workspace ShadowTranslate.xcworkspace -scheme ShadowTranslate \
  -destination 'platform=macOS' -skipPackagePluginValidation build

# 4. Run the app
open ~/Library/Developer/Xcode/DerivedData/ShadowTranslate-*/Build/Products/Debug/ShadowTranslate.app
```

### Running Tests

```bash
xcodebuild -workspace ShadowTranslate.xcworkspace -scheme ShadowTranslate \
  -destination 'platform=macOS' -skipPackagePluginValidation test
```

> ⚠️ **Note**: This project has no root-level `Package.swift`. Must use `xcodegen` + `.xcworkspace`. Do not run `swift build` from the repo root.

---

## 🏗️ Architecture

ShadowTranslate uses a modular architecture with Swift 6 strict concurrency:

```
ShadowTranslate.app
├── SharedCore         # Shared core (language definitions, errors, logging)
├── InferenceKit       # MLX inference engine (Gemma 4B model)
├── PersistenceKit     # SwiftData persistence (history storage)
├── AccessibilityKit   # Accessibility API (text read/replace)
├── ModelManager       # Model download manager (HuggingFace Hub)
└── UIKitShared        # Shared UI (floating panels, SwiftUI views)
```

**Data Flow:**
```
Hotkey → AXReplacer.readSelectedText() → InferenceEngine.translate()
  → AsyncStream<String> → TranslationPopupView → AXReplacer.replaceSelectedText()
  + HistoryWriter.insert()
```

**Tech Stack:**
- **MLX Swift**: Efficient machine learning on Apple Silicon
- **SwiftData**: Local data persistence
- **Accessibility API**: Cross-app text operations
- **Swift 6**: Strict concurrency safety

---

## 🛣️ Roadmap

- [x] Basic translation functionality
- [x] Selected text replacement
- [x] Translation history
- [ ] Translation quality improvements
- [ ] Support for more models
- [ ] Custom prompt templates
- [ ] OCR image translation
- [ ] Browser extension
- [ ] Enhanced text selection translation

---

## 🤝 Contributing

We welcome all forms of contributions! Please read [AGENTS.md](AGENTS.md) for project structure and contribution guidelines.

### Submit an Issue

If you encounter problems or have feature suggestions, please [submit an issue](https://github.com/yourusername/ShadowTranslate/issues).

### Submit a PR

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is open-sourced under the [MIT License](LICENSE).

---

## 🙏 Acknowledgments

- [MLX Swift](https://github.com/ml-explore/mlx-swift) — Apple's machine learning framework
- [mlx-swift-lm](https://github.com/ml-explore/mlx-swift-lm) — MLX language model support
- [Google Gemma](https://ai.google.dev/gemma) — Open source language model
- [Hugging Face](https://huggingface.co) — Model hosting and distribution

---

<p align="center">
  Made with ❤️ by Henry Zhang
</p>

<p align="center">
  <a href="README.md">中文</a>
</p>
