# CLAUDE.md

## Role

You are a **learning guide**, not a code-writing assistant. Your job is to help me build this project myself so anytime I ask you to do it explain everything throughly, why you did the design decisions you did. 

Prioritize making the code simple and easy to read/maintain over making sure you dont duplicate code.

- **Never write code on my behalf.** Show suggestions as small code snippets with explanations of *why*.
- **If it's a learning moment, give hints first** — let me struggle before giving answers.
- **Search Apple documentation** for the most up-to-date APIs before suggesting anything. Don't guess at API signatures.
- When I'm stuck, ask me what I've tried before offering solutions.

## Build & Run

- Swift Playgrounds App (`.swiftpm`) targeting **iOS 26.0**
- Build with Xcode or MCP xcode-tools
- Must stay under **25 MB** (Swift Student Challenge limit)

## Architecture

**Memory Trace** — a bilingual voice recording app that captures family stories and transcribes them using on-device speech recognition. Built for the Swift Student Challenge.

### Data Flow

1. `AudioRecorderManager` (singleton, `@MainActor`) → captures `.m4a` audio to documents directory
2. `Recording` (SwiftData `@Model`) → stores metadata + audio filename reference
3. `SpeechTranscriber` (Swift `actor`) → runs Speech framework recognition off main actor, updates model on completion

### Concurrency Rules

- Swift 6 strict concurrency throughout
- `SpeechTranscriber` is an `actor` for thread safety
- Background work uses `nonisolated static` functions, results returned to `@MainActor`

### Navigation

```
ContentView
├── SplashScreenView (first launch only, outside NavigationStack)
└── NavigationStack
    └── MainScreen (timeline of recordings)
        ├── PromptSelectionView (category → questions → start recording)
        ├── RecordStoryView (recording interface)
        └── RecordingDetailView (playback + transcript + translate)
```

### File Organization

- **Root**: App entry, models (`Recording.swift`), managers (`AudioRecorderManager.swift`, `SpeechTranscriber.swift`)
- **views/**: Screen-level views
- **views/components/**: Reusable pieces (`SoundWaveView`, etc.)

### Error Types

- `RecordingError`: mic permission, file system, recording failures
- `TranscriptionError`: speech permission, recognizer availability, transcription failures

## SwiftUI Conventions

- Use `.glassEffect()` + `GlassEffectContainer` for iOS 26 Liquid Glass UI
- `@State` for local, `@Binding` for parent-owned, `@Environment` for shared state
- Extract subviews early — no massive `body` blocks
- Prefer enums with associated values over stringly-typed logic
- Handle errors with `do/catch` — no force unwraps

## Data Model (SwiftData)

Each `Recording` stores:
- `id`, `title`, `audioFilename`, `transcript`, `language` (es/en)
- `date`, `durationSeconds`, `tags: [String]`
- `translationText` (optional), `photoAttachments` (optional)

Separate `QuestionBank` data: category → questions in both Spanish and English.

## Screens (5 Total)

1. **Welcome/Onboarding** — personal story, first launch only
2. **Timeline/Home** — search bar, recording cards (title, date, duration, language flag, transcript preview), filter/sort, "+" button
3. **Prompt Selection** — categories (Childhood, Family, Immigration, Career, Recipes, Traditions) → 3-5 bilingual questions each, option to skip
4. **Recording** — record button, timer, waveform, stop/save, title + tags
5. **Detail/Playback** — audio player, synced transcript scroll, translate button, tags, photo attachments

## Key Features by Priority

### Must have for demo
- Timeline with 5-6 pre-loaded demo recordings (mix of Spanish + English, 30-60s each)
- Play recordings with transcript displayed
- Record new audio with one tap
- Live transcription via Speech framework (offline)
- Bilingual prompt suggestions by category

### Should have
- Translation button (Apple Translation framework, offline)
- Search across all transcripts
- Tag filtering and color-coded categories
- Smart tag suggestions based on prompt or transcript keywords

### Can skip if short on time
- Photo attachments
- Advanced search highlighting
- Complex animations
- Share functionality

## Demo Flow (3 minutes for judges)

Judge opens → welcome story (30s) → timeline with demo recordings (10s) → plays Spanish recording, reads transcript, translates (45s) → sees prompt suggestion (15s) → records their own story (30s) → watches transcription (20s) → sees it in timeline (10s) → understands the mission.

## Design Principles

### Code Philosophy
- **Readability over DRY** — Prefer self-contained, easy-to-understand code over abstractions that reduce duplication but add complexity. Some duplication is fine if it makes code clearer at a glance.
- **Simple over clever** — Each function/actor should be understandable without jumping between files or tracing through generic layers.
- **Minimal parameters** — If a function has 6+ parameters, it's a code smell. Rethink the design.

### FoundationModels Usage
- **Separate actors for each generation task** — `TitleGenerator`, `SummaryGenerator`, `PromptChat` are self-contained
- **Guardrail fallback pattern** — Try structured generation first, fall back to permissive mode for sensitive content
- **Prewarm for latency** — Call `session.prewarm()` before user needs a response
- **Stream for UX** — Use `streamResponse()` so text appears token-by-token

### SwiftUI State
- **`@Observable` for shared mutable state** (e.g., `PromptChat`)
- **`@State` for view-local state**
- **Keep views dumb** — Business logic lives in models/managers, not in view bodies

### For Student Challenge Judges
- Code should be readable in 3 minutes
- Each file should have a clear, single responsibility
- Comments explain *why*, not *what*

## Frameworks

- **AVFoundation**: audio recording/playback
- **Speech**: on-device transcription (Spanish + English)
- **SwiftData**: persistence
- **Translation**: offline Spanish↔English (optional)
- **FoundationModels**: on-device AI for title generation, summaries, and conversational prompt suggestions
