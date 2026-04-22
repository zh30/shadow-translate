# Repository Guidelines

## Project Overview

ShadowTranslate is a macOS translation app using MLX for local LLM inference. It captures selected text via Accessibility APIs, translates it using mlx-community/translategemma-4b, and replaces the original text in-place.

## Project Structure

```
shadow-translate/
├── apps/
│   └── ShadowTranslate/          # Main app target
│       ├── Sources/              # AppDelegate, main.swift
│       ├── project.yml           # XcodeGen configuration
│       └── Info.plist
├── packages/                     # 6 Swift package modules
│   ├── SharedCore/               # Language enum, ShadowError, Logger categories
│   ├── InferenceKit/             # MLX inference (Gemma 4B)
│   ├── PersistenceKit/           # SwiftData models + @ModelActor
│   ├── AccessibilityKit/         # AX read/replace + clipboard fallback
│   ├── ModelManager/             # HuggingFace Hub downloads
│   └── UIKitShared/              # SwiftUI views, NSPanel floating popup
├── ShadowTranslate.xcworkspace   # Xcode workspace
└── CLAUDE.md                     # Detailed architecture notes
```

## Build Commands

```bash
# Generate Xcode project from project.yml (required after any project.yml change)
xcodegen generate

# Build (always pass -skipPackagePluginValidation for MLX/SwiftData macros)
xcodebuild -workspace ShadowTranslate.xcworkspace -scheme ShadowTranslate \
  -destination 'platform=macOS' -skipPackagePluginValidation build

# Test
xcodebuild -workspace ShadowTranslate.xcworkspace -scheme ShadowTranslate \
  -destination 'platform=macOS' -skipPackagePluginValidation test

# Run the built app
open ~/Library/Developer/Xcode/DerivedData/ShadowTranslate-*/Build/Products/Debug/ShadowTranslate.app
```

**Important:** No root `Package.swift` — always use `xcodegen generate` + `xcodebuild` via the workspace.

## Coding Style

- **Swift 6 strict concurrency** — all packages use `swiftLanguageModes: [.v6]`
- **Actors everywhere** — all shared mutable state must be actor-isolated
- **4-space indentation**
- **Trailing closures** for SwiftUI view builders
- **Explicit self** only when required by Swift 6 isolation

## Concurrency Patterns

Use `@preconcurrency import ApplicationServices` for AX APIs lacking Sendable annotations. Annotate immutable CFString constants with `nonisolated(unsafe)`.

```swift
// Correct: Actor-isolated state
actor InferenceEngine {
    private var container: ModelContainer?
    func warmUp() async throws { ... }
}

// Correct: @unchecked Sendable singleton with proper isolation
@MainActor
final class FloatingPanelController: @unchecked Sendable {
    static let shared = FloatingPanelController()
}
```

## Testing

Tests live in `packages/<Name>/Tests/`. Run via Xcode scheme or `xcodebuild -scheme ShadowTranslate test`.

## Commits

Prefix with stage/implement/fix per git history:

```
Scaffold ShadowTranslate project with modular Swift package architecture
Implement Stage 2-8: full Mac app with inference, persistence, accessibility
Fix: AXReplacer now correctly handles empty text selections
```

## Key Constraints

- **macOS 15.0+** deployment target
- **Non-sandboxed** (`ENABLE_APP_SANDBOX: NO`) — required for AX write access
- **Hardened Runtime** with `disable-library-validation`, `allow-jit`, `allow-unsigned-executable-memory`
- **LSUIElement = true** — no Dock icon, menu bar only
- **Model**: ~2.18GB downloaded on first run from HuggingFace Hub

## Architecture Notes

See `CLAUDE.md` for detailed patterns: MLX model lifecycle, dual-track text replacement, SwiftData migration, and incomplete wire-ups.
