# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Generate Xcode project from project.yml (run after any project.yml change)
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

**No root `Package.swift`** — this project uses xcodegen + .xcworkspace with local Swift packages. Do not run `swift build` from the repo root.

## Architecture

6-package workspace, all Swift 6 strict concurrency (`swiftLanguageModes: [.v6]`), macOS 15.0 deployment target.

```
App target (ShadowTranslateApp + AppDelegate)
  ├── SharedCore      — Language enum, ShadowError, os.Logger categories
  ├── InferenceKit    — MLX Swift LM inference via custom Downloader/TokenizerLoader bridges
  ├── PersistenceKit  — SwiftData models + @ModelActor writer + singleton query store
  ├── AccessibilityKit — AX read/replace (dual-track) + clipboard+⌘V fallback
  ├── ModelManager    — HuggingFace Hub download + Gemma ToU gate
  └── UIKitShared     — NSPanel floating popup, SwiftUI views, theme constants
```

**Data flow**: Hotkey → AXReplacer.readSelectedText() → InferenceEngine.translate() → AsyncStream<String> → TranslationPopupView → AXReplacer.replaceSelectedText() + HistoryWriter.insert()

### Key patterns

- **Actors everywhere**: InferenceEngine, AXReplacer, ModelDownloader, HistoryWriter (@ModelActor) are all actors. Shared mutable state must be actor-isolated.
- **@unchecked Sendable singletons**: HistoryStore (creates fresh ModelContext per call), FloatingPanelController (@MainActor singleton).
- **MLX model lifecycle**: warmUp() loads + 1-token dummy → translate() streams → idle timer (60s) unloads + MLX.GPU.clearCache().
- **Non-activating popup**: NSPanel with .nonactivatingPanel + .hudWindow, level .floating. Does NOT steal focus from frontmost app.
- **Dual-track text replace**: Try AX kAXSelectedTextAttribute first → fallback clipboard+CGEvent ⌘V (restore clipboard after 500ms).

### MLX integration (no macros)

InferenceKit does NOT use MLXHuggingFace macros (trust validation issues). Instead it manually implements:
- `HubDownloader`: conforms to `MLXLMCommon.Downloader`, wraps `HuggingFace.HubClient`
- `TransformersTokenizerLoader`: conforms to `MLXLMCommon.TokenizerLoader`, wraps `Tokenizers.AutoTokenizer`
- `TokenizerBridge`: conforms to `MLXLMCommon.Tokenizer`, wraps `any Tokenizers.Tokenizer`

Model ID: `mlx-community/translategemma-4b-it-4bit_immersive-translate` (~2.18GB)

## Concurrency Gotchas

- `@preconcurrency import ApplicationServices` needed for AX C APIs lacking Sendable annotations.
- `nonisolated(unsafe)` used for `kAXTrustedCheckOptionPrompt` (immutable CFString constant).
- `ModelContainer` (from MLX) is itself an actor — always use `await container.prepare/generate`.
- `InferenceEngine.translate()` returns `AsyncStream<String>` — the Task inside the stream closure cannot directly mutate actor properties. Use public actor methods (e.g. `touchLastUse()`, `rescheduleIdleTimer()`).
- `HistoryStore` creates a new `ModelContext` per query call. Do not share `ModelContext` instances.

## SwiftData

- `VersionedSchema` requires `versionIdentifier` (not `version`).
- `SchemaMigrationPlan.stages` type is `[MigrationStage]` (not `[MigrationStage.Type]`).
- `@Model` types must be top-level (not nested in enums) for the macro to expand correctly.
- `PersistenceMigrationPlan` currently has empty stages — future schema changes need explicit migration.

## Build Requirements

- App is **not sandboxed** (`ENABLE_APP_SANDBOX: NO`). Required for AX write access.
- Hardened Runtime ON with entitlements: `disable-library-validation`, `allow-jit`, `allow-unsigned-executable-memory` (all needed by MLX).
- `SKIP_MACRO_VALIDATION: YES` in project.yml + `-skipPackagePluginValidation` CLI flag.
- `LSUIElement = true` in Info.plist — no Dock icon, menu bar only.

## Model Lifecycle & AppState

- `AppState` (`@MainActor @Observable`) in UIKitShared is the single source of truth for model state.
- `ModelState` enum: `.notDownloaded` → `.termsRequired` → `.downloading(progress, speed, eta)` → `.verifying` → `.loading` → `.ready` → `.error(String)`
- First launch flow: `AppDelegate.checkModelState()` → if no model, shows `OnboardingWindowController` with `OnboardingView`
- `OnboardingView` auto-closes via `.onChange(of: isReady)` when model becomes ready
- `FloatingPanelController.shared.configure(appState:)` must be called in `AppDelegate` so popup views get the environment
- `InferenceEngine.warmUpFromDirectory(_:)` loads from local path (no remote download); `warmUp()` uses `ModelConfiguration(id:)` (triggers download)
- `ModelDownloader.cancelDownload()` cancels an in-progress download task

## Incomplete Wire-ups

These integration points are stubbed and need real implementation:
- `TranslationPopupView` replace button → `AccessibilityKit.AXReplacer.replaceSelectedText()`
- `MainWindowView` history list → `PersistenceKit.HistoryStore` queries