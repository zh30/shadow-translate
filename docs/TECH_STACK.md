# Shadow Translate — 技术栈总览（MVP 对齐 PRD v1）

> 本文档由 Agent 团队（MLX Inference / Apple UI / Persistence / DevEx）四路并行评审 `docs/PRD.md` 后综合生成，作为工程启动的单一事实来源。

---

## 1. 执行摘要

### 1.1 三项锁定的架构决策
| # | 决策 | 原因 |
|---|---|---|
| D-1 | **Swift 原生 + MLX Swift**（不走 Python 桥接） | 满足 PRD §4.2 冷启 ≤5s / 推理 ≤2s；消除 IPC 开销；发布单 App 包 |
| D-2 | **SwiftData（主存储）+ SQLite FTS5 侧车（全文检索）** | SwiftData 无法满足 PRD §4.1 模块 3 全文搜索性能；双写方案 Apple 官方推荐 |
| D-3 | **Non-sandbox + Hardened Runtime + Developer ID + notarytool** | App Sandbox 与 Accessibility API（PRD §4.1 模块 2 替换按钮）不兼容；不上架 MAS |

### 1.2 工作区拓扑（6 包 Swift Package）
```
ShadowTranslate.xcworkspace
├── ShadowTranslate (app target, SwiftUI + AppKit 混合)
└── Packages/
    ├── InferenceKit          # MLX Swift + 推理 actor + 语言检测
    ├── PersistenceKit        # SwiftData + FTS5 侧车 + 导出
    ├── AccessibilityKit      # AX 读写 + 剪贴板回退 + 混合热键（MVP ⌘⇧T，Phase 1.5 opt-in ⌘+C+C）
    ├── ModelManager          # HF Hub 下载 + SHA256 + Gemma 许可同意
    ├── UIKit-Shared          # NSPanel 容器 + 共享 View + 主题
    └── SharedCore            # 类型 / 协议 / 日志 / 错误
```

### 1.3 部署形态
- **发布通道**：DMG + Sparkle 2（EdDSA 签名），不上架 Mac App Store。
- **最低系统**：macOS 15.2 Sequoia（SwiftData `#Unique` / MLX Swift API / Swift 6 严格并发）。
- **芯片**：Apple Silicon（M1+）。Intel 不支持（MLX 限制）。

---

## 2. 分层技术栈

### 2.1 推理层（InferenceKit）— 对应 PRD §4.1 模块 1

| 能力 | 技术选型 | 关键 API |
|---|---|---|
| 推理框架 | `ml-explore/mlx-swift` + `mlx-swift-examples` (`MLXLLM`, `MLXLLMCommon`) | `LLMModelFactory.shared.loadContainer(configuration:)` |
| 模型加载 | `ModelContainer`（actor 包装，线程安全） | `await container.perform { ... }` |
| 分词/聊天模板 | `huggingface/swift-transformers` | `tokenizer.applyChatTemplate(messages:)` |
| 流式输出 | `AsyncStream<Generation>` | `MLXLMCommon.generate(input:parameters:context:)` |
| 推理入口 | `actor InferenceEngine` | 封装并发安全；UI 层 `for await` 消费 token |
| 语言检测 | Apple `NaturalLanguage.NLLanguageRecognizer` | `dominantLanguage` + `languageHypotheses(withMaximum:)` Top-N |
| 输入协议 | 占位符 `<<<source>>>...<<<target>>>...<<<text>>>...` + OpenAI messages 双模式 | 通过 `ChatTemplate` 自动适配 |
| 参数 | `temperature=0.2`、`topP=0.95`、`maxTokens=1024`（可调） | `GenerateParameters` |
| 内存管理 | `MLX.GPU.set(cacheLimit: 2 * 1024 * 1024 * 1024)`；空闲 60s 卸载模型 | 低内存模式切换 int4 分组大小 |

**关键风险**：模型文件 2.18 GB（4-bit 量化权重），首次加载约 3–4s；预热一次假输入可把 p95 推理延迟压到 2s 内（PRD KPI）。

### 2.2 UI / 系统集成层（UIKit-Shared + AccessibilityKit）— 对应 PRD §4.1 模块 2 / 模块 3 主窗口

| 能力 | 技术选型 | 不可替代原因 |
|---|---|---|
| App 形态 | `LSUIElement=true` + `MenuBarExtra(.window)` | PRD 无 Dock 图标；菜单栏常驻 |
| 悬浮弹窗 | **`NSPanel` + `.nonactivatingPanel` + `NSHostingView`** | SwiftUI `.windowLevel(.floating)` 仍会抢焦，导致选中高亮丢失 |
| 面板属性 | `[.canJoinAllSpaces, .fullScreenAuxiliary, .transient]` | 跨桌面/全屏 App 可用 |
| 热键（MVP 默认） | `sindresorhus/KeyboardShortcuts`，默认 `⌘⇧T` | 用户自定义 + 冲突检测 UI；无需 AX 热键通道 |
| 热键（Phase 1.5 opt-in） | **`CGEventTap`**（tapForwardOnly；350ms 状态机）实现 `⌘+C+C` | DeepL 风格，用户在设置中显式启用；Carbon / HotKey 不支持双击检测 |
| 文本选择读取 | `AXUIElementCopyAttributeValue(kAXSelectedTextAttribute)` | PRD §4.1 模块 2 基础 |
| 可编辑判定 | `kAXRoleAttribute` ∈ {AXTextField, AXTextArea} ∧ `AXIsAttributeSettable(kAXSelectedTextAttribute)` | 决定显示"替换"按钮 |
| 替换通道 | **双轨**：(A) `AXUIElementSetAttributeValue` 优先；(B) 剪贴板粘贴 + CGEvent ⌘V 回退 | Electron/Chrome 的 AX 写入经常失败 |
| 权限引导 | `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt:true])` + 引导式 onboarding | PRD §6 风险 1 缓解 |
| 流式 UI 消费 | `.task(id:)` + `for await` 订阅 `AsyncStream` | 随语言切换自动取消重开 |
| Markdown 渲染 | `AttributedString(markdown:)`（MVP 内联） | 轻量；MVP 后替换为 `swift-markdown-ui` |
| 本地化 | Xcode 16 **String Catalog (.xcstrings)**，`.id(locale)` 触发重建 | 中/英双语 UI |
| 辅助技术 | VoiceOver / Dynamic Type / 高对比度 / 深色模式 | PRD §4.2 可访问性 |

### 2.3 持久化层（PersistenceKit）— 对应 PRD §4.1 模块 3

| 能力 | 技术选型 | 说明 |
|---|---|---|
| 主存储 | **SwiftData**（macOS 15+） | `@Model TranslationRecord`, `@Model Tag` |
| 唯一/索引 | `#Unique<TranslationRecord>([\.id])`、`#Index<TranslationRecord>([\.timestamp, \.sourceLang])` | 检索路径优化 |
| 关系 | `@Relationship(deleteRule: .nullify, inverse: \Tag.records)` | Tag ↔ TranslationRecord 多对多 |
| 并发写 | `@ModelActor` `HistoryWriter` | Swift 6 严格并发安全 |
| 全文搜索 | **SQLite FTS5 侧车**（Apple 官方推荐，SwiftData `localizedStandardContains` 不可扩展） | 双写：SwiftData 持久化 → FTS5 索引同步 |
| 搜索 API | `MATCH` 查询 + BM25 排序 | 原文 + 译文 + 标签全文检索 |
| 日期桶 | `dayBucket: String` 派生字段 | 趋势仪表盘 O(1) 聚合 |
| Schema 演化 | `VersionedSchema` + `SchemaMigrationPlan` | 向后兼容 |
| 云同步 | **不启用** CloudKit | 与 `#Unique` 不兼容；PRD §1 "完全离线" |
| 导出 | JSON / CSV（`Codable` + `Foundation`） | PRD §4.1 模块 3 |

**TranslationRecord 字段映射 PRD §4.1 模块 3**：
`id, sourceText, translatedText, sourceLang, targetLang, timestamp, sourceApp?, tags:[Tag], isFavorite, dayBucket`

### 2.4 模型与分发层（ModelManager）

| 能力 | 技术选型 |
|---|---|
| 模型仓库 | Hugging Face Hub Swift SDK |
| 国内镜像 | 可切换 `hf-mirror.com` |
| 完整性 | 逐文件 SHA256 校验 |
| 存储路径 | `~/Library/Application Support/<bundle-id>/Models/<version>/` |
| 首次下载 | 进度条 + 断点续传 + 带宽限速 |
| 许可协议 | **Gemma Terms of Use 必须在下载前接受**（同意状态持久化） |
| 更新策略 | Sparkle 2 推送新版本时提示模型更新（可选） |

### 2.5 工程化与发布（DevEx）

| 能力 | 技术选型 |
|---|---|
| 语言 / 工具链 | Swift 6.0 严格并发；Xcode 16 |
| 代码风格 | `swift-format` + SwiftLint（`--strict`） |
| 测试 | **Swift Testing**（新）+ XCTest（兼容）+ **XCUITest** 关键冒烟 |
| 本地化校验 | `xcrun xcstringstool validate` CI 步骤 |
| 签名 | Developer ID Application + Hardened Runtime |
| 公证 | `xcrun notarytool submit --wait` |
| 打包 | DMG（`create-dmg`）+ Sparkle 2 appcast |
| 崩溃遥测 | **MetricKit `MXCrashDiagnostic` 纯本地**（无上传）+ 应用内诊断面板 |
| 日志 | `os.Logger` 子系统化 |
| Entitlements | `com.apple.security.cs.disable-library-validation`（MLX dylib）；**不启用** App Sandbox |
| Info.plist | `NSAccessibilityUsageDescription` 明确说明用途 |
| CI | GitHub Actions macOS 15 runner：build / test / lint / xcstrings validate / notarize on tag |

---

## 3. PRD 需求追溯矩阵

| PRD 节号 | 需求点 | 技术实现 | 所属包 | 风险 | 评审 Agent |
|---|---|---|---|---|---|
| §1 | 完全离线 | 无 telemetry；仅 HF 下载一次 | ModelManager | 低 | ④ |
| §1 | 2.18 GB MLX 4-bit 模型 | `mlx-swift` + `LLMModelFactory` | InferenceKit | 低 | ① |
| §2 | 冷启 ≤5s | 预加载 + 假输入预热 | InferenceKit | 中 | ① |
| §2 | 翻译 ≤2s / p95 | `AsyncStream` 流式 + GPU cache 2GB | InferenceKit | 中 | ① |
| §2 | 崩溃率 <0.5% | MetricKit + 单元覆盖 | DevEx | 低 | ④ |
| §4.1-M1 | 占位符/OpenAI 双格式 | `ChatTemplate` 适配器 | InferenceKit | 低 | ① |
| §4.1-M1 | Auto 语言检测 | `NLLanguageRecognizer` Top-N | InferenceKit | 低 | ① |
| §4.1-M1 | temperature / top-p | `GenerateParameters` | InferenceKit | 低 | ① |
| §4.1-M2 | 全局选中触发（MVP 默认 `⌘⇧T`） | `KeyboardShortcuts` | AccessibilityKit | 低 | ② |
| §4.1-M2 | 全局选中触发（Phase 1.5 opt-in `⌘+C+C`） | `CGEventTap`（tapForwardOnly）+ 350ms 状态机 | AccessibilityKit | **高** | ② |
| §4.1-M2 | 可自定义快捷键 | `KeyboardShortcuts` 录制器 + 冲突检测 | AccessibilityKit | 低 | ② |
| §4.1-M2 | 不抢焦弹窗 | `NSPanel` + `.nonactivatingPanel` | UIKit-Shared | **高** | ② |
| §4.1-M2 | 靠近光标 / 多屏适配 | `NSScreen.screens` + 鼠标位置计算 | UIKit-Shared | 中 | ② |
| §4.1-M2 | 语言切换即时重译 | `.task(id:)` 取消重启流 | UIKit-Shared | 低 | ② |
| §4.1-M2 | 复制按钮 | `NSPasteboard.general` | UIKit-Shared | 低 | ② |
| §4.1-M2 | 替换按钮（仅可编辑） | AX 角色检测 + 双轨写入 | AccessibilityKit | **高** | ② |
| §4.1-M2 | Markdown 轻渲染 | `AttributedString(markdown:)` | UIKit-Shared | 低 | ② |
| §4.1-M3 | 永久本地历史 | SwiftData `@Model` | PersistenceKit | 低 | ③ |
| §4.1-M3 | 全文搜索 | **SQLite FTS5 侧车** | PersistenceKit | 中 | ③ |
| §4.1-M3 | 过滤（日期/语种/标签/App） | `#Index` + `FetchDescriptor` 谓词 | PersistenceKit | 低 | ③ |
| §4.1-M3 | 分析仪表盘 | `dayBucket` 聚合 + Charts | PersistenceKit + UIKit-Shared | 低 | ③ |
| §4.1-M3 | 导出 JSON/CSV | `Codable` | PersistenceKit | 低 | ③ |
| §4.1-M3 | 收藏 / 批量删除 | SwiftData 操作 | PersistenceKit | 低 | ③ |
| §4.2 | 深色模式 / VoiceOver | SwiftUI 原生 | UIKit-Shared | 低 | ② |
| §4.2 | 中英双语 UI | String Catalog | UIKit-Shared | 低 | ② |
| §4.2 | 模型手动更新 | Sparkle 2 + HF 增量 | ModelManager | 中 | ① ④ |
| §6 | Accessibility 权限引导 | onboarding + `AXIsProcessTrusted` | AccessibilityKit | **高** | ② |
| §6 | 低内存模式 | 空闲卸载 + 分组量化切换 | InferenceKit | 中 | ① |
| §6 | 快捷键冲突 | `KeyboardShortcuts` 内置检测 | AccessibilityKit | 低 | ② |
| §8 | 测试 10+ App | Chrome/Safari/Word/VS Code/Notes 冒烟 | DevEx | 中 | ② ④ |

---

## 4. 风险登记簿

| ID | 风险 | 影响 | 缓解措施 | 负责包 |
|---|---|---|---|---|
| R-1 | AX 权限被拒绝 | P0：核心功能失效 | 引导式 onboarding + 系统设置深链 | AccessibilityKit |
| R-2 | Electron/Chrome 无法写回 | 中：替换功能降级 | 剪贴板 + CGEvent ⌘V 回退 | AccessibilityKit |
| R-3 | MLX 首次加载 >5s | 中：首屏体验 | 启动时后台预加载 + 进度提示 | InferenceKit |
| R-4 | 2.18GB 模型首次下载慢 | 中：onboarding 流失 | 断点续传 + hf-mirror 切换 | ModelManager |
| R-5 | SwiftData 全文检索性能 | 高：搜索超时 | FTS5 侧车双写 | PersistenceKit |
| R-6 | Gemma 许可合规 | 高：下架风险 | 首次下载前强制接受并留存记录 | ModelManager |
| R-7 | CGEventTap 需 AX 权限（仅 Phase 1.5 opt-in `⌘+C+C`） | 中：Phase 1.5 热键与 AX 读写共享同一权限 | MVP 默认 `⌘⇧T` 走 `KeyboardShortcuts`，不经 CGEventTap；opt-in 启用时单次申请 AX 并提供关闭开关 | AccessibilityKit |
| R-8 | macOS 15 覆盖率 | 中：用户基数 | MVP 聚焦 15+；观察 14 降级可能 | DevEx |

---

## 5. MVP 范围 vs 路线图对齐

### Phase 1（MVP，对齐 PRD §7）
- ✅ 弹窗（NSPanel + 混合热键（MVP `⌘⇧T` / Phase 1.5 opt-in `⌘+C+C`）+ AX 读写 + 剪贴板回退）
- ✅ 主窗口历史（SwiftData + FTS5 搜索 + 过滤）
- ✅ MLX 推理（流式 + 语言检测 + 温度/top-p）
- ✅ 模型下载 + Gemma 许可 + SHA256
- ✅ DMG + Sparkle + notarytool

### Phase 2（PRD §7）
- 标签/仪表盘增强（`Swift Charts`）
- 主题/字体自定义
- 模型自动更新通道

### Phase 3（PRD §7）
- 多模型切换（架构已预留 `ModelContainer` 抽象）
- 语音输入（Speech framework）
- 批量文件翻译（后台队列）

---

## 6. 待用户决策的设计选项

以下决策不影响架构锁定，但会显著影响 onboarding 体验与首次使用曲线。建议在进入编码前确认：

| 选项 | A 方案 | B 方案 | 影响 |
|---|---|---|---|
| **Onboarding 顺序** | 许可→下载→AX→热键 | AX→热键→许可→下载 | A 更早暴露大文件下载；B 更早让用户试用 UI |
| **低内存触发** | 空闲 60s 卸载 | 仅手动开关 | A 更激进省内存；B 更可预测 |
| **国内镜像** | 自动探测网速切换 | 用户手动切换 | A 隐式；B 显式，更可控 |

---

## 7. 开发启动清单

启动前必须完成：
- [ ] 创建 6 个 Swift Package 骨架并接入工作区
- [ ] Xcode 项目启用 Swift 6 严格并发
- [ ] 配置 Hardened Runtime + AX 权限说明字段
- [ ] 申请 Developer ID 证书 + notarytool 凭据（App Store Connect API Key）
- [ ] 在 `hf-mirror.com` 测试模型下载路径
- [ ] 验证 macOS 15.2 目标设备（AX + MLX + MenuBarExtra）
- [ ] 建立 CI：build / test / lint / xcstrings validate / 可选 notarize on tag

---

**版本**：v1.1 · **生成日期**：2026-04-20 · **对齐 PRD**：`docs/PRD.md` v1
**评审 Agent**：① MLX Inference · ② Apple UI · ③ Persistence · ④ DevEx
