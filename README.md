# My Day – To-Do & Journal 📔📝

<img src="MyDay/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="160" alt="My Day app icon" align="right">

A colourful, cosy iPhone app for planning the day, choosing what matters most,
and keeping a private journal. It is built with **SwiftUI** and **SwiftData**.

## Features

| Screen | What you can do |
| --- | --- |
| **My Day** (home) | The illustrated home screen from the design. Tap a card to open it. Badges show what is left for today. The ☰ menu, a live date badge, the 🔔 reminders button, the *Add Task / Add Priority / Add Journal* chips and the pink **+** quick-add button all work. |
| **Today's To-Dos** | Add to-dos inline, tick them off, reorder by dragging, swipe to star or delete, and see a progress ring. Each to-do can have a note, a day and a reminder. |
| **Today's Priority** | Your starred to-dos as numbered golden cards. Add priorities directly or pick them from today's to-dos. A gentle tip appears when you go over three. |
| **My Journal** | Pages with a mood, title, text, writing prompts and an optional photo. Search, favourites, a "week in moods" strip, and an optional **Face ID lock**. |
| **Calendar** | Month grid with markers for to-dos, priorities and journal pages, plus the selected day's agenda. |
| **Insights** | Done today, day streak, a weekly bar chart and a 30-day mood chart (Swift Charts). |
| **Settings** | Your name, a morning and an evening reminder, carrying unfinished to-dos over to today, haptics, the journal lock, and data clean-up. |

Everything is stored on the device. The app makes no network calls.

## Requirements

- Xcode 16 or newer
- iOS 17.0 or newer, iPhone (portrait)

## Run it

1. Open `MyDay.xcodeproj` in Xcode.
2. Select the **MyDay** target → *Signing & Capabilities*. Choose your Team and,
   if needed, change the bundle identifier (`com.regina3579.myday`).
3. Pick an iPhone simulator or your iPhone, then press **Run** (⌘R).

## Project structure

```
MyDay/
├── App/            App entry, navigation (Router), UIKit appearance
├── Models/         SwiftData models: TaskItem, JournalEntry (+ Mood)
├── Services/       Reminders, Face ID lock, haptics, day rollover, helpers
├── Theme/          Colours from the artwork, fonts, shared components
├── Features/
│   ├── Root/       Tab container, floating tab bar, side menu
│   ├── Home/       Illustrated home screen and its overlays
│   ├── Todos/      To-do list and editor
│   ├── Priority/   Today's Priority
│   ├── Journal/    Journal list, page, editor, lock screen
│   ├── Calendar/   Month grid and day agenda
│   ├── Insights/   Stats and charts
│   ├── Settings/   Settings and reminders
│   └── QuickAdd/   The + button's quick capture sheet
└── Assets.xcassets App icon, home artwork, colours
```

## How the home screen matches the design

The home artwork (`HomeArt`) is the original design. The status bar, bell, date
badge and tab bar were painted out so real controls can take their place.
`ArtSpace` maps the artwork's 853 × 1844 pixel grid onto the screen, and every
native control (buttons, badges, chips, **+**) is placed with those coordinates.
Because of this, the controls line up on every iPhone size. On shorter screens,
such as iPhone SE, the home screen scrolls.

## Continuous integration

`.github/workflows/ios-build.yml` builds the app for the iOS Simulator on every
push and pull request. It then runs `scripts/screenshots.sh`, which opens every
main screen in the iPhone simulators and uploads the screenshots as a build
artifact. You can also run the script on a Mac: `./scripts/screenshots.sh`.
