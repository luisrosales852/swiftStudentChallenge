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


Your task is to help me learn and do this project. Search documentation always to get the most up to date information and dont write anything on my behalf, tell me your suggestions in code snippets instead and why. If you think its a learning moment give me hints not repsonses so i can figure it out myself. If anything your a tool for retrieving documentation and guiding me


This is the main idea:
Yep lets add an info card beforehand
ALL SCREENS (5 Total)
Screen 1: Welcome/Onboarding (First Launch Only)
* Photo or illustration showing family/memories
* Brief explanation: "Preserve your family's stories before they're lost"
* Your personal story in 2-3 sentences (grandmother with Alzheimer's)
* "Get Started" button
Screen 2: Timeline/Home View (Main Screen)
* Top: Search bar
* Main area: List or grid of all recordings shown as cards
* Each card shows: title, date, duration, language flag (🇸🇻 or 🇺🇸), first line of transcript
* Can filter/sort by: date, category/tag, language
* Bottom: Large "+" button to create new recording
* Tap any card to go to detail view
Screen 3: Prompt Selection (Before Recording) (smart prompts estancia buenos) (usamos apples foundational model para pesto) v 
* Header: "What would you like to record about?"
* Categories displayed: Childhood, Family, Immigration, Career, Recipes, Traditions
* Tap a category to see 3-5 specific questions in that category
* Questions shown in both Spanish and English
* "Start Recording" button at bottom
* Option to skip prompts and just start recording
Screen 4: Recording Screen
* Large circular record button in center (red when recording)
* Timer showing current duration (00:00:45)
* If came from prompt screen, show the selected question at top
* Waveform animation while recording (optional visual)
* "Stop & Save" button
* After stopping: prompt to add title/edit auto-generated title
* Option to add tags (childhood, family, etc.)
* "Save" button stores the recording
Screen 5: Detail/Playback View
* Top: Back button, recording title, date, language flag
* Audio player with: play/pause button, progress bar, current time/total duration
* Full transcript displayed below player (scrollable)
* Transcript auto-scrolls as audio plays (synced)
* "Translate" button (if recording is in Spanish, shows English translation)
* Tags shown as colored pills
* Option to attach photos (shows thumbnails if any attached)
* Edit/delete buttons
* Share button (future feature)

ALL FEATURES (Must Have)
Recording Features:
1. Record audio with one tap
2. Show recording duration while recording
3. Save with custom title or auto-generated title
4. Support Spanish and English (auto-detect or let user choose)
5. Store recordings permanently on device
Transcription Features:
1. Automatically transcribe audio to text after recording finishes
2. Work completely offline using Apple's Speech framework
3. Show transcription progress
4. Store transcript with the recording
5. Display transcript in detail view
Browsing Features:
1. Show all recordings in a timeline/list view
2. Display key info on each card (title, date, duration, preview text)
3. Sort by: newest first, oldest first, or by category
4. Visual indicators for language (Spanish flag vs US flag)
5. Tap to open detail view and play
Search Features:
1. Search bar at top of timeline
2. Searches through all transcript text
3. Shows matching recordings
4. Highlights search terms in results
Smart Prompt Features:
1. Pre-loaded question bank organized by life categories
2. Questions in both Spanish and English
3. Suggest 3-5 questions before recording
4. Basic keyword detection: if transcript mentions "El Salvador" suggest immigration questions, if mentions "cocina/cooking" suggest recipe questions
5. Always allow option to skip prompts and free-form record
Organization Features:
1. Tag recordings by category (childhood, family, immigration, career, recipes, traditions)
2. Color-code tags for visual distinction
3. Filter timeline by tag
4. Auto-suggest tags based on which prompt was used
Playback Features:
1. Simple audio player controls (play, pause, skip forward/back)
2. Scrub through audio with progress bar
3. Shows current time and total duration
4. Transcript follows along as audio plays (optional but cool)
Translation Features (Optional but Recommended):
1. "Translate" button on Spanish recordings
2. Uses Apple Translation framework (offline)
3. Shows English translation below Spanish transcript
4. Save translation for future viewing

FEATURES FOR DEMO ONLY (Pre-loaded Content)
Demo Recordings (What Judges See):
1. 5-6 pre-recorded family stories already in the app
2. Mix of Spanish (2-3) and English (2-3) recordings
3. Each 30-60 seconds long
4. Already transcribed and tagged
5. Topics: grandmother's childhood in El Salvador, how she met grandfather, pupusa recipe, immigration story, family tradition, your favorite memory
Demo User Flow:
1. Judge opens app and immediately sees timeline with demo recordings
2. Judge taps a Spanish recording, hears audio, sees Spanish transcript
3. Judge taps translate button, sees English translation appear
4. Judge navigates back, sees a suggested prompt
5. Judge records 10-20 seconds of their own voice
6. Judge sees their recording transcribe in real-time
7. Judge sees it added to timeline

DATA THAT NEEDS TO BE STORED
For each recording:
* Unique ID
* Title (user can edit)
* Audio file (saved to device storage)
* Transcript text
* Language (Spanish or English)
* Date and time recorded
* Duration in seconds
* Category tags (array of strings)
* Translation text (if translated)
* Photo attachments (optional, array of image files)
Question bank data:
* Category name
* List of questions for that category
* Both Spanish and English versions

USER FLOW (Step by Step)
First Time User:
1. Opens app → sees welcome screen
2. Reads your story about grandmother
3. Taps "Get Started"
4. Sees timeline (empty or with tutorial card)
5. Taps "+" button
6. Sees prompt categories
7. Taps "Family" → sees questions about family
8. Chooses "How did you meet your spouse?"
9. Recording screen opens with that question shown
10. Taps red button to record
11. Speaks for 30 seconds
12. Taps "Stop & Save"
13. Adds title or keeps auto-generated one
14. Adds tags
15. Saves
16. App transcribes in background
17. Returns to timeline → sees new recording card
18. Taps card → sees detail view
19. Plays recording while reading transcript
Returning User: 20. Opens app → sees timeline with all previous recordings 21. Can search for specific memory 22. Can browse by category/tag 23. Can play any recording 24. Can translate Spanish recordings to English 25. Can add new recording anytime
Judge Experience (3 minutes): 26. Opens app → sees welcome with your story (30 sec) 27. Taps through to timeline → sees 6 demo recordings (10 sec) 28. Taps one in Spanish → plays, reads transcript, translates (45 sec) 29. Returns to timeline → sees suggested prompt (15 sec) 30. Taps "+" → sees prompt categories (10 sec) 31. Chooses a prompt → records 15 seconds about their own grandparent (30 sec) 32. Sees it transcribe instantly (20 sec) 33. Returns to timeline → sees their recording added (10 sec) 34. Understands: "This app preserves family stories before they're lost"

WHAT MAKES IT SPECIAL
Emotional Impact:
* Solves the regret: "I wish I'd asked grandma more questions"
* Deeply personal (your two grandmothers, current aunt)
* Proactive vs reactive (Care Capsule)
Technical Innovation:
* Speech-to-text that works offline
* Bilingual support (Spanish + English)
* Smart question suggestions based on content
* Real-time transcription
Social Impact:
* Serves 50+ million families dealing with cognitive decline
* Preserves immigrant stories and cultural heritage
* Works in the language memories were lived in
* Captures intergenerational family history
Design Excellence:
* Beautiful, emotional UI (your frontend strength)
* Simple enough for elderly to use
* Engaging enough for young people to want to use
* Three-minute demo is compelling and complete

MINIMUM VIABLE DEMO (If Short on Time)
Absolutely must have:
* Timeline with 5 demo recordings
* Can play recordings with transcripts
* Can record new 10-second clip
* Sees transcription happen
* Shows suggested prompts
Can skip:
* Translation (nice but not essential)
* Photos
* Complex search
* Advanced tagging
* Fancy animations

