# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.



## Build and Run

This is a Swift Playgrounds App (.swiftpm) targeting iOS 26.0. Build using Xcode's standard build system or through the MCP xcode-tools.

## Architecture Overview

**Memory Trace** is a voice recording app that captures audio stories and automatically transcribes them using on-device speech recognition.

### Core Data Flow

1. **Recording**: `AudioRecorderManager` (singleton, `@MainActor`) handles AVAudioRecorder for capturing audio to `.m4a` files in the documents directory
2. **Persistence**: `Recording` model (SwiftData `@Model`) stores metadata with audio filename reference
3. **Transcription**: After saving, `Recording.startTranscription()` dispatches work to `SpeechTranscriber` (Swift actor) which runs Speech framework recognition off the main actor, then updates the model on completion

### Key Patterns

- **Concurrency**: Uses Swift 6 strict concurrency. `SpeechTranscriber` is an `actor` for thread-safe transcription. Background work uses `nonisolated static` functions with results returned to MainActor
- **SwiftData**: `ModelContainer` configured in app entry point with `Item` and `Recording` schemas. Views use `@Query` for reactive data binding
- **Liquid Glass UI**: iOS 26 `.glassEffect()` modifier throughout with `GlassEffectContainer` for grouped elements

### Navigation Structure

```
ContentView
├── SplashScreenView (one-time, outside NavigationStack)
└── NavigationStack
    └── MainScreen
        ├── RecordStoryView (recording interface)
        └── RecordingDetailView (playback + transcript)
```

### File Organization

- Root: App entry, models (`Recording.swift`), managers (`AudioRecordingManager.swift`, `SpeechTranscriber.swift`)
- `views/`: UI screens
- `views/components/`: Reusable UI components (`SoundWaveView`)

### Error Types

- `RecordingError`: Microphone permission, file system, recording failures
- `TranscriptionError`: Speech permission, recognizer availability, transcription failures
