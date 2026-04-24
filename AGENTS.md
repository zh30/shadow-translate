# Repository Guidelines

## Project Structure & Module Organization

ShadowTranslate is a macOS menu bar translation app. The main app target lives in `apps/ShadowTranslate/`, with `Sources/` for app entry points, `Info.plist`, and `project.yml` for XcodeGen.

Reusable code is split into Swift packages under `packages/`:

- `SharedCore`: common language types, errors, and logging categories.
- `InferenceKit`: MLX local inference for the Gemma translation model.
- `PersistenceKit`: SwiftData models and model actors.
- `AccessibilityKit`: Accessibility API text capture/replacement and clipboard fallback.
- `ModelManager`: HuggingFace model download and local model management.
- `UIKitShared`: SwiftUI views and floating `NSPanel` UI.

Tests live in `packages/<PackageName>/Tests/`. Project documentation is in `README.md`, `README_EN.md`, `docs/`, and `CLAUDE.md`.

## Build, Test, and Development Commands

Regenerate the Xcode project after editing `apps/ShadowTranslate/project.yml`:

```bash
xcodegen generate
```

Build the app through the workspace:

```bash
xcodebuild -workspace ShadowTranslate.xcworkspace -scheme ShadowTranslate \
  -destination 'platform=macOS' -skipPackagePluginValidation build
```

Run tests:

```bash
xcodebuild -workspace ShadowTranslate.xcworkspace -scheme ShadowTranslate \
  -destination 'platform=macOS' -skipPackagePluginValidation test
```

Run the debug app:

```bash
open ~/Library/Developer/Xcode/DerivedData/ShadowTranslate-*/Build/Products/Debug/ShadowTranslate.app
```

There is no root `Package.swift`; use the workspace and XcodeGen flow.

## Coding Style & Naming Conventions

Use Swift 6 strict concurrency. Keep shared mutable state actor-isolated, prefer `@MainActor` for AppKit/SwiftUI controllers, and use `@preconcurrency import ApplicationServices` where AX APIs lack Sendable annotations. Indent with 4 spaces. Follow Swift naming conventions: types in `UpperCamelCase`, methods and properties in `lowerCamelCase`, and tests named for expected behavior.

## Testing Guidelines

Add package tests under `packages/<Name>/Tests/<Name>Tests/`. Focus coverage on concurrency boundaries, SwiftData persistence, model-management state transitions, and AX replacement fallbacks. Run the full `xcodebuild ... test` command before opening a PR.

## Commit & Pull Request Guidelines

Git history uses concise imperative subjects, often prefixed by scope or intent, such as `Scaffold ...`, `Implement Stage 2-8: ...`, or `Fix ...`. Keep commits focused.

Pull requests should include a short summary, test results, linked issues when applicable, and screenshots or screen recordings for visible menu bar, onboarding, or floating panel changes. Mention any Accessibility permission, model download, or macOS configuration impact.

## Security & Configuration Tips

The app targets macOS 15.0+, runs non-sandboxed for AX write access, and uses hardened runtime exceptions for MLX/JIT behavior. Do not re-enable the app sandbox or remove runtime entitlements without validating text replacement and local inference.


<claude-mem-context>
# Memory Context

# [shadow-translate] recent context, 2026-04-24 2:09pm GMT+8

No previous sessions found.
</claude-mem-context>