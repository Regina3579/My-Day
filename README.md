# My Day – To-Do & Journal 📔📝

<img src="MyDay/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="160" alt="My Day app icon" align="right">

A colourful, cosy iPhone app for planning the day, choosing what matters most,
and keeping a private journal. It is built with **SwiftUI** and **SwiftData**.

## Screenshots

Captured automatically in the iPhone 17 Pro simulator by CI. The to-dos, priorities and
journal pages in them are demo data added only for these screenshot runs (the pages' photos
are pieces of the app's own pictures); the app itself starts empty.

| Home | Today's To-Dos | All Done ✨ | Add a Task | Voice Add |
| --- | --- | --- | --- | --- |
| <img src="docs/screenshots/iphone-17-pro-01-home.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-04-todos.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-19-todos-confetti.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-05-todos-add.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-07-todos-voice.jpg" width="170"> |

| Templates | Quick Add menu | Today's Priority | My Journal | A Journal Page |
| --- | --- | --- | --- | --- |
| <img src="docs/screenshots/iphone-17-pro-08-todos-templates.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-02-quickadd.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-09-priority.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-10-journal.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-11-journal-page.jpg" width="170"> |

| Priority (empty) | Write a Page | Calendar | Insights | Settings |
| --- | --- | --- | --- | --- |
| <img src="docs/screenshots/iphone-17-pro-22-priority-empty.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-30-journal-new.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-12-calendar.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-13-insights.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-14-settings.jpg" width="170"> |

| Journal Pages | Page Templates | My Feelings | Filter | Trash |
| --- | --- | --- | --- | --- |
| <img src="docs/screenshots/iphone-17-pro-24-journal-pages.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-25-journal-templates.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-26-journal-feelings.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-29-journal-filter.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-28-journal-trash.jpg" width="170"> |

| Pattern Lock | Passcode Lock | Lock Settings | Choose a Lock | Voice Tip (first time) | Quote Tip (first time) |
| --- | --- | --- | --- | --- | --- |
| <img src="docs/screenshots/iphone-17-pro-38-journal-lock-pattern.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-39-journal-lock-passcode.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-40-settings-lock.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-41-settings-lock-choose.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-43-todos-voice-tip.jpg" width="170"> | <img src="docs/screenshots/iphone-17-pro-44-home-quote-tip.jpg" width="170"> |

## Features

| Screen | What you can do |
| --- | --- |
| **My Day** (home) | The illustrated home screen from the design. The girl, pets and garden are an image; everything else is native SwiftUI: the ☰ menu, the "My Day" title, today's real date, the 🔔 reminders button, **Daily Motivation** (a short hand-written quote from 112 built-in quotes about happiness, productivity, gratitude, self-belief, consistency, peaceful living and progress; it stays the same all day, changes after midnight and works offline); the first time the app opens, a one-time tip lights up the quote, a cute pink arrow bounces up at it and a bubble says “A new quote for you, every day! 💖”, the three feature cards with live badges, the pink **+** Quick Add menu and the floating tab bar. |
| **Today's To-Dos** | The illustrated header, today's date with a daily quote, category chips (All, Personal, Work, Health, Learning, Shopping, then your own) with a ＋ chip to add a category of your own (a name, an emoji and a colour; press and hold it to delete it, and its to-dos move to Personal), and soft pastel rows; chips and rows are in their category's colour (Personal pink, Work blue, Health green, Learning yellow, Shopping purple; categories you add are pink unless you pick another colour), rows such as "Health · 5:00 PM 🔔". The box on the left ticks a to-do off; the ☆ next to the ✏️ marks it important, and important to-dos (★) are always listed first; the little ✏️ on the right opens a menu: Edit, Change date/time, Add reminder, Repeat, Move to Priority and Delete. Swipe a to-do to the left to delete it, tap it for its details, or press and hold to drag it to a new place. Finished to-dos slide under a colourful **› Completed** button (with their count) below the list; it starts closed, and a tap shows or hides them. **Daily Progress** sits at the top of the list: "Today ✨ 3 of 5 completed ● ● ● ○ ○"; ticking a to-do pops two little pink hearts out of its box, one a bit bigger and one very small, which float up and fade, and when every to-do is done it says "✨ All done for today!" while a big shower of pink, purple, yellow and blue stars, hearts and confetti bursts across the screen (both skipped with Reduce Motion). **Today's Progress** (the counts, a heart for every to-do and the kitten's cheer) is pinned at the bottom, under the add buttons. Finishing a repeating to-do creates the next one. |
| **Four ways to add** | The two fastest are bright and glowing: a long pink ＋ **Add Task** button and, beside it, a round yellow 🎙 microphone labelled "Speak a Task". 📷 **Photo** and ▦ **Template** are smaller and softer, underneath. All four, with Today's Progress under them, stay pinned at the bottom of the screen, just above the tab bar, on a frosted panel; only the list scrolls, sliding behind them. ＋ **Add Task**: a pastel sheet where only the title is needed; category, date & time, reminder, repeat, photo and note are optional. 🎙 **Speak a Task**: Apple's Speech framework (on the device when supported) turns what you say into text; My Day spots words like *today*, *tomorrow*, *at 5 PM* and *every day*; the to-do goes to the category chip you have chosen above (Health, Shopping or your own), or to a category you name ("… in my shopping list"), and with **All** chosen it is guessed from words like *doctor* or *milk* (Personal otherwise). It then shows your new to-do ready to change right there: the task (type over it), the category chips, and Date & Time, Reminder and Repeat rows that open in place, with **Add Task** (and "Add a photo or a note" for the full sheet). Nothing is saved without your tap, and guesses are pointed out. The first time the To-Dos page opens, a one-time tip dims the page around the 🎙, a cute pink arrow bounces toward it and a bubble says “Add your task with your voice! 🎤” with **Got it** and **Try it now**; it never shows again. 📷 **Photo**: take or choose a photo, add the title and details, and save; view it full size, replace it or remove it later. ▦ **Templates**: Morning Routine, Grocery Shopping, Travel Checklist, Workout Routine, Home Cleaning and Study Session; untick what you don't need and tap "Add to My Day". "Save as Template" keeps your own lists on the device. Every template, the starters included, has a **⋯** button (and the same choices at the top of its list) to **Edit** it (name, emoji, category, and each to-do: rewrite, remove or add) or **Delete** it; deleted starters can be brought back with "Bring back the starter templates". **Press and hold** a template card to pick it up and move it around: the other cards make room as it passes over them, and the new order is kept (new templates go at the end; with VoiceOver, use the Move earlier and Move later actions). |
| **Today's Priority** | A full-screen page (the status bar and the tab bar hide here): the illustrated "Today's Priority — Focus on what matters most" scene (the girl in her yellow frock with the puppy and the kitten) fills the top of the screen, right up to the top edge, and a soft pink panel below it holds a glowing **＋ Add today's priority…** field with a 🎙: tap it and say your priority, and your words are typed into the field as you speak (fix any word, then tap ＋). The Edit Priority sheet has the same 🎙. Until the day has a priority, a little star hugging a heart says "Set your today's priority". Priorities are numbered golden cards with a "1 of 3 done" count: tick (two little pink hearts pop out of the tick), edit, swipe to delete and press and hold to reorder them. A ticked priority moves down to **› Completed**, as on To-Dos (tap it to show or hide the finished ones, each with a gold star). When every priority is done, the design's **"All of today's priorities are done! Well done!"** card appears (the girl, the puppy and the kitten cheering among balloons and stars), the Completed list opens and confetti of stars and hearts flies, as on To-Dos. The ⋮ button picks a priority from the day's open to-dos or removes the finished ones. |
| **My Journal** | Opens full screen on **My Journal Pages**, as in the design, with bigger, clearer text: the illustrated "My Journal Pages — Every thought and beautiful moment belongs here…" scene (the girl, her puppy, the books and "A Happier Me Everyday"); the **My Pages 💗** card with the notebook and how many pages you have; the waving star beside a big pink **✏️ Write a new page ›**; **My week in moods** (the last seven days, each with its page's star; tap one to open that page) with **View Calendar**; and ten tabs: **All Pages**, **Favorites**, **Little Wins** (with a count), **Templates** (Gratitude Page, Daily Reflection, Dream Journal, Self-Care Check-in, Letter to Myself, Happy Memory, Goals & Wishes and Let It Go: each starts a new page with its heading, gentle prompts and tags), **Photos** (every photo, three across; tap one to open its page), **Voice Notes**, **My Feelings** (the mood you felt most, and a bar for each mood; tap one to see only those pages), **My Growth** (pages written, days in a row, little wins and words written), **Dreams** (pages with "Tomorrow I look forward to…" or the Dreams tag) and **Trash**. Pages are listed by month ("September 2026 💗") with a **This Month ⌄** menu (All Time, Last 7 Days, This Month, Last Month, Last 3 Months, This Year). Each page card has its date under a pink, purple or blue ribbon bow, its star and heading, its first lines, the time, its mood, a heart to favourite it, its photo (with "+2" for more) and ⋮ (Edit Page, Favorite, Move to Trash). A floating **Search your journal… 💗** bar and **Filter** (favourites, photos, voice notes, little wins, dates, order and any of the 30 moods) stay at the bottom while the pages scroll behind them. **Write a new page** opens the writing page: the day (tap to change it) and its weather; **How are you feeling today?** with six little stars (Amazing, Happy, Calm, Sad, Stressed, Tired) and a pink **＋** that opens **Choose your mood**: all 30 stars from the design (Loved, Excited, Grumpy, Anxious, Motivated, Proud, Playful and more) on pastel tiles, with **Done** (a mood picked there shows under the six as "Feeling Proud"); **Write about your day…** with **Get a Prompt**: a one-line heading on top (like "A wonderful day"; left empty, the page is named after its mood), a pink line with a heart under it, then your writing with a 1000-character count; **Add some extras**: photos (up to 6), stickers, **voice notes** (as many as you like, each recording up to 5 minutes; tap **Continue** on one to record more onto its end, say in the morning and again in the afternoon), the place (typed, or **Use My Location**), the weather (picked by hand, with an optional temperature) and mood tags such as "Good Vibes" (what you add shows right under your writing); **Today I'm grateful for…**, **A highlight of my day…**, **Tomorrow I look forward to…** and **Today's Little Win 🏆**; and a big **Save Journal Entry** button. Every part is optional. Once saved, the written page is shown ("Saved to your journal 💖"): its mood at the top (the little star and "Feeling Bored"), its heading, the heart line and your writing, then everything else on it, voice notes included. **Move to Trash** keeps a page in Trash for 30 days (Restore or Delete Forever, and **Empty Trash**), then deletes it. Optional **journal lock**, opened your way: **Face ID** (or Touch ID, with the iPhone passcode as a fallback), a **Pattern** (join at least 4 of 9 dots) or a **Number Passcode** (4 or 6 digits). A wrong pattern or passcode shakes and says how many tries are left; after 5 wrong tries each one more means a wait (30 seconds, growing to 5 minutes). **Forgot?** opens it with Face ID or the iPhone passcode instead. |
| **Calendar** | The illustrated header from the design ("Calendar — Every day is a new page" with the girl, the puppy and the kitten) and a white **Today** button. The month card has pink ‹ › buttons, "♥ September 2026 ♥", pink weekday pills, the days around the month in grey, a pink ring for today and a pink circle for the selected day; small markers show to-dos (a dot, green when all are done), priorities (a star) and journal pages (a heart). Swipe the card to change month. The selected day's card shows its date, a chip such as "☀️ Today" or "Tomorrow", and three tinted rows: **Priorities** (pink), **To-Dos** (lilac) and **Journal** (pink), each with a picture and a round ＋. The day's items are listed under their row; tick them there. |
| **Insights** | Done today, day streak, a weekly bar chart and a 30-day mood chart (Swift Charts). |
| **Settings** | Your name, morning and evening reminders, carrying unfinished items over to today, showing finished to-dos (the Completed list open or closed), **Sounds & Haptics** (Task Completion Sound and gentle haptics), the journal lock (**Lock My Journal**, then choose Face ID, Pattern or Number Passcode; a new pattern or passcode is asked for twice, and changing the method or turning the lock off first asks for the current one), and data clean-up. |
| **Ticking things off** | Ticking a to-do or a priority (on its page or in the Calendar) plays a soft crystal "ting" (0.4 s) with a very light haptic tap, together with the tick and its two little hearts. Ticking the day's last one plays a slightly more magical 1-second chime instead, with the confetti (and, for priorities, the "All of today's priorities are done!" card). Unticking plays nothing. The sounds are bundled (`MyDay/Resources/Sounds`, made by `scripts/make_sounds.py`), loaded at launch so they play at once, mix with other audio, stay quiet on Silent and pause while you record; turn them off in Settings → Sounds & Haptics → Task Completion Sound. |

Everything is stored on the device with SwiftData, so data stays between launches.
The app makes no network calls of its own; only **Use My Location** on a journal
page asks Apple's location service for the name of the place. Permissions are
asked for only when a feature needs them: notifications when you first switch on
a reminder, the microphone and speech recognition when you first use Voice Add,
the microphone when you first record a voice note, the camera when you first take
a photo, and your location only when you tap Use My Location. If one is turned off, My Day explains how to turn
it on in Settings and offers another way (for example, typing instead of speaking).

## Data model

| Model | Fields |
| --- | --- |
| `TaskItem` (the spec's *Task*; `Task` is Swift's concurrency type) | id, title, category (Personal, Work, Health, Learning, Shopping), date, time, reminderEnabled, reminderDate, repeatOption, isCompleted, createdAt (+ notes, completedAt, seriesID, sortOrder, isImportant, customCategory, photoData stored outside the database, photoThumbnail) |
| `CustomCategory` | id, name, emoji, colorIndex, createdAt — the categories you add with ＋ (deleting one moves its to-dos to Personal) |
| `TaskTemplate` | id, name, emoji, category, items, createdAt, starterID — every template: the six starters (copied in once, so they can be edited and deleted) and the ones you save yourself |
| `Priority` | id, title, date, order, isCompleted (+ completedAt, createdAt) |
| `JournalEntry` | id, date, title, body, mood, photos (`[JournalPhoto]`), voiceNotes (`[JournalVoiceNote]`), createdAt, updatedAt, deletedAt (set while the page is in Trash) (+ isFavorite, littleWin, gratitude, highlight, lookingForward, stickers, tags, place, weather, temperature; the older single voiceNote moves into voiceNotes when the page is next saved) |
| `JournalPhoto` | id, imageData (stored outside the database), thumbnailData, order |
| `JournalVoiceNote` | id, audio (AAC, stored outside the database), duration, order, createdAt, updatedAt |

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
├── Models/         SwiftData models: TaskItem, CustomCategory, TaskTemplate, Priority,
│                   JournalEntry, JournalPhoto, JournalVoiceNote, JournalPageTemplate;
│                   TaskDraft (an unsaved to-do)
├── Services/       Reminders, speech (SpeechTranscriber, VoiceTaskParser),
│                   journal lock (Face ID, pattern, passcode; Keychain), haptics,
│                   day rollover, helpers
├── Theme/          Colours from the artwork, fonts, shared components
├── Features/
│   ├── Root/       RootView, BottomTabBar, side menu
│   ├── Home/       HomeView, HomeHeader, DailyQuoteView, HomeFeatureCard,
│   │               QuickAddButton / QuickAddMenu, card illustrations
│   ├── Todos/      TodayToDosView, TodoComponents (rows, ✏️ menu, progress),
│   │               NewTaskSheet, NewCategorySheet, VoiceTaskSheet,
│   │               TemplatePickerSheet, TaskPhotoViews, Celebration (confetti, tick pop)
│   ├── Priority/   TodaysPriorityView, NewPrioritySheet
│   ├── Journal/    JournalView (My Journal Pages), JournalPagesParts (its cards, tabs,
│   │               page cards and search bar), JournalShelves (tabs, Templates, Photos,
│   │               My Feelings, My Growth, Trash, Filter), JournalComposer (writing a page),
│   │               JournalExtras (stickers, voice notes, place, weather, tags),
│   │               MoodChooserSheet, JournalDetailView, NewJournalEntrySheet, lock screen
│   ├── Calendar/   CalendarView, CalendarComponents
│   ├── Insights/   InsightsView
│   └── Settings/   SettingsView, RemindersView, JournalLockSettings
└── Assets.xcassets App icon, home, to-dos, priority and calendar illustrations, kitten, colours
```

## How the home screen is built

Only the scenery is an image: `HomeScene` is the sky, castle and garden with
the girl, the puppy and the kitten. The old title, message and cards were
painted out of it. Everything on top is native SwiftUI: `HomeHeader`,
`DailyQuoteView`, three `HomeFeatureCard`s drawn with vector shapes, and
`QuickAddButton` + `QuickAddMenu`, with `BottomTabBar` from the root view.
Sizes follow the screen width, so the layout keeps the design's proportions
on every iPhone, and the screen scrolls when it does not fit (for example on
iPhone SE).

The To-Dos screen works the same way: only `TodosScene` (the sign, the girl and
her puppy) and `ProgressKitten` are images. The date card, chips, rows, buttons,
hearts and the "You're Doing Great!" badge are SwiftUI views.

The Calendar's `CalendarHeader` picture (the design's title, icon and Today button painted
out), its calendar icon, the flowers and the three row pictures are images; the text, the
buttons, the month grid and the rows are SwiftUI.

Today's Priority too: `PriorityScene` (the title, the girl, the puppy and the kitten,
with the design's buttons painted out) and `PriorityEmptyStar` are images; the add
field, the panel, the cards and the ⋮ menu are SwiftUI. The scene's top rows are soft
curtains at the top edge (behind the Dynamic Island), and the design's back and ⋮
buttons line up with the navigation bar's own.

The tab bar floats over the screens, so `RootView` publishes the height it
covers (`tabBarClearance`) and every screen keeps its content clear of it with
`tabBarSafeArea()`. Full-screen pages (Today's Priority) hide it instead, with
`Router.setFullScreen(_:in:)`.

## Continuous integration

`.github/workflows/ios-build.yml` builds the app for the iOS Simulator on every
push and pull request. It then runs `scripts/screenshots.sh`, which opens every
main screen in the iPhone simulators and uploads the screenshots as a build
artifact. Running the workflow by hand with *publish_screenshots* also commits small
JPEG copies to `docs/screenshots/`. You can run the script on a Mac too:
`./scripts/screenshots.sh`.
