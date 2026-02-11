
# Project Structure

## Views Folder Organization

```
Views/
├── SplashScreenView.swift   - First launch splash screen
├── MainScreen.swift          - Main app screen with navigation
└── RecordStoryView.swift     - Screen for recording audio stories
```

## How Navigation Works

### First Launch Flow:
1. User opens app for the first time
2. `ContentView` checks `@AppStorage("hasCompletedOnboarding")`
3. Shows `SplashScreenView` (NO NavigationStack = no back button)
4. After 4 seconds, splash completes and sets `hasCompletedOnboarding = true`
5. Transitions to `MainScreen` with NavigationStack
6. User can never go back to splash screen

### Returning User Flow:
1. User opens app again
2. `ContentView` checks `@AppStorage("hasCompletedOnboarding")` = true
3. Directly shows `MainScreen` with NavigationStack
4. No splash screen shown

### Main Screen Navigation:
- **Record Story** button → navigates to `RecordStoryView`
- **My Memories** button → (to be implemented)
- **Pills Monitoring** button → (to be implemented)

## RecordStoryView Features

✨ **Modern Liquid Glass Design** - Uses SwiftUI's glass effects
🎙️ **Recording Interface** - Interactive recording button with pulsing animation
⏱️ **Timer Display** - Shows recording duration in MM:SS format
💾 **Save Functionality** - Save button appears after recording
↩️ **Back Navigation** - Returns to MainScreen after saving

## Key Features

✅ **Splash screen only shown once** - Uses `@AppStorage` to persist state
✅ **No back button to splash** - Splash screen shown outside NavigationStack
✅ **Organized code** - Each view in its own file
✅ **Modern Swift** - Uses `Task.sleep` instead of `DispatchQueue`
✅ **Easy to test** - Separate previews for each view
✅ **Liquid Glass UI** - Modern design with glass effects throughout

## Testing

To **reset and see splash again** during development:
```swift
// In your preview or during testing:
UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
```

Or delete and reinstall the app.
