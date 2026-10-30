# Publishing My Day on the App Store

A step-by-step guide for App Store Connect, followed by every piece of text to paste in.
The limits (characters) are Apple's; each text below fits within them.

**App facts used in this guide** (from the project):

| | |
|---|---|
| Bundle ID | `com.regina3579.myday` |
| Version / build | 1.0 / 1 |
| Devices | iPhone only, portrait, iOS 17 or later |
| iCloud container | `iCloud.com.regina3579.myday` (CloudKit) |
| Capabilities | iCloud (CloudKit), HealthKit (steps, read only), Push Notifications (for iCloud sync) |
| In-app purchases | `com.regina3579.myday.pro.monthly`, `com.regina3579.myday.pro.yearly` (auto-renewable), `com.regina3579.myday.pro.lifetime` (non-consumable) |
| Encryption | `ITSAppUsesNonExemptEncryption = NO` is already set, so no export question at upload |
| Privacy manifest | `MyDay/PrivacyInfo.xcprivacy`: no tracking, no data collected, UserDefaults reason CA92.1 |

---

## Part 1 — Before you start

### Step 1. Apple Developer Program
Join at [developer.apple.com/programs](https://developer.apple.com/programs/) (US$99 a year;
Apple shows the price in your currency). Use the same Apple Account in Xcode
(*Xcode → Settings → Accounts*).

### Step 2. Agreements, tax and banking (needed for Pro)
App Store Connect → **Business** (*Agreements, Tax, and Banking*):
1. Accept the **Free Apps Agreement** (already there) and request the **Paid Apps Agreement**.
2. Add your **bank account**, then fill in the **tax forms** (for India: the U.S. tax form W-8BEN, and the Indian tax details Apple asks for).
3. Wait until the Paid Apps Agreement shows **Active**. Subscriptions cannot be sold, or
   even tested in the sandbox, before that.

### Step 3. Websites you must have (Apple rejects the app without them)
Apple requires a **Privacy Policy URL** (required for every app, and especially for apps that use HealthKit)
and a **Support URL**. Free ways to host them: Google Sites, Notion (public page), or GitHub
Pages (ready-made pages are in the `website/` folder: see Step 3 in the chat guide).
1. Publish the **Privacy Policy** in Part 3 of this guide on a public page.
2. Publish a simple **Support** page: the app name, a support e-mail, and a line such as
   "Questions or ideas? Write to us at …".
3. **Send me the two links and your support e-mail.** I will put them in the app
   (`MyDayPrivacyURL`, `MyDaySupportEmail` in `Info.plist`); the **Unlock My Day Pro** page's
   *Privacy* link uses it, and App Review checks that link works. The *Terms of Use* link already
   opens Apple's standard licence agreement.

### Step 4. Deploy the iCloud database to Production (very important)
Without this, iCloud sync and Shared Lists work while you test from Xcode, but **not** for
people who download the app from the App Store.
1. Run the app from Xcode on your iPhone, signed in to iCloud. Add a to-do, a priority,
   a journal page (with a photo and a voice note), a template, a custom category,
   and a Shared List with one item, and share it once. This creates every record type in the
   **Development** database.
2. Open [CloudKit Console](https://icloud.developer.apple.com) → **CloudKit Database** →
   container `iCloud.com.regina3579.myday`.
3. Click **Deploy Schema Changes…** (bottom left), check the list, and **Deploy** to
   Production.

---

## Part 2 — App Store Connect, step by step

### Step 5. Create the app record
[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → **＋** → **New App**:

| Field | Enter |
|---|---|
| Platforms | iOS |
| Name | `My Day: To-Do & Journal` (if taken, try `My Day – Planner & Journal`) |
| Primary Language | English (U.S.) |
| Bundle ID | `com.regina3579.myday` (it appears after Xcode has signed the app once; otherwise add it in *Certificates, Identifiers & Profiles → Identifiers* with iCloud, HealthKit and Push Notifications) |
| SKU | `MYDAY-IOS-001` (any unique code; only you see it) |
| User Access | Full Access |

### Step 6. App Information (left menu)
- **Subtitle**: see Part 3.
- **Category**: Primary **Productivity**, Secondary **Lifestyle**.
- **Content Rights**: *"No, it does not contain, show, or access third-party content"* (if
  all pictures and art are yours).
- **Age Rating** → *Edit* and answer the questionnaire. Choose **None / No** for every
  type of content (violence, mature themes, gambling, medical advice and so on), **No** for unrestricted web
  access, and for messaging or user-generated content describe it honestly: lists are shared only
  with people the user invites; there is no public chat or public posting. The expected
  result is **4+**.
- **Privacy Policy URL**: your link from Step 3.
- **License Agreement**: leave Apple's standard one.

### Step 7. Pricing and Availability
- **Price**: Free (USD 0).
- **Availability**: all countries, or the ones you choose.

### Step 8. App Privacy
**App Privacy** → **Get Started** → *"Do you or your third-party partners collect data from
this app?"* → **No, we do not collect data from this app.** → Publish.

Why this is correct: My Day has no servers, no analytics and no ads. Data stays on the iPhone
and in the person's **own private iCloud**, which the developer cannot open. Purchases go
through Apple. Apple's definition of *collect* is data sent off the device in a way that you or
a partner can access, and none of My Day's data is.
The App Store will show **"Data Not Collected"**.

### Step 9. Subscriptions and the Lifetime purchase
**Monetization → Subscriptions**:
1. **Create** a subscription group, Reference Name `My Day Pro`. Under *App Store
   Localization*, add the group display name `My Day Pro`.
2. In the group, **create** two subscriptions, using the texts in Part 3:

   | Reference Name | Product ID | Duration |
   |---|---|---|
   | My Day Pro Yearly | `com.regina3579.myday.pro.yearly` | 1 Year |
   | My Day Pro Monthly | `com.regina3579.myday.pro.monthly` | 1 Month |

   For each subscription:
   - **Availability**: all countries.
   - **Price**: choose India as the base country if most of your customers are there, and
     Apple fills in every other currency. The app's debug fallback prices are **₹899 a year**
     and **₹99 a month**.
   - **App Store Localization**: Display Name and Description from Part 3.
   - **Review Information**: a screenshot of the **Unlock My Day Pro** page (the screenshots in
     `docs/screenshots` named `…pro-paywall…` are fine), plus the review note from Part 3.
   - Put both subscriptions in the **same level** of the group: they unlock the same features
     and differ only in how often they renew.

   Do not add a free trial unless we first update the Pro page to show it.

**Monetization → In-App Purchases** → **＋**:
- Type **Non-Consumable**, Reference Name `My Day Pro Lifetime`, Product ID
  `com.regina3579.myday.pro.lifetime`.
- **Price**: ₹2,999.
- Localization and Review Information from Part 3, plus the same screenshot.

A first subscription or in-app purchase must be **submitted together with an app version**
(Step 13).

### Step 10. Upload the app from Xcode (on your Mac)
1. Pull the latest code from the branch and open `MyDay.xcodeproj`.
2. **Signing & Capabilities** for the *MyDay* target: choose your **Team**; keep *Automatically
   manage signing*. Check that iCloud (CloudKit, container `iCloud.com.regina3579.myday`),
   HealthKit and Push Notifications are listed. Xcode switches push to Production by itself when
   you upload.
3. At the top, choose the device **Any iOS Device (arm64)**.
4. **Product → Archive**. When it finishes, the **Organizer** opens.
5. **Distribute App** → **App Store Connect** → **Distribute** (or *Upload*). Keep the default
   options.
6. After about 10–30 minutes Apple e-mails you that the build has finished processing. For every
   later upload, raise the **Build** number (1 → 2 → 3…) in *General → Identity*.

### Step 11. Test with TestFlight first (recommended)
App Store Connect → **TestFlight** → add yourself as an *Internal Tester* → install the
**TestFlight** app on your iPhone and open My Day from there. Check:
- Buying Pro (TestFlight purchases are free sandbox purchases).
- **Restore Purchases**.
- iCloud sync on a second device.
- Sharing a list with a second Apple Account.
- The Health privacy note, then the steps on a journal page.

### Step 12. Fill in the version page (iOS App → 1.0 Prepare for Submission)
- **Screenshots**: **iPhone 6.9" Display** is required: 1320 × 2868 pixels (portrait), 3 to 10
  images. Apple scales them down for smaller iPhones. Take them on the
  **iPhone 17 Pro Max** simulator (*File → Save Screen* or ⌘S) or on a Pro Max iPhone. A good
  order:
  1. Home
  2. Today's To-Dos
  3. Today's Priority
  4. My Journal Pages
  5. Writing a page with moods
  6. Calendar
  7. Achievements
  8. Shared Lists
  9. Journal themes
  10. Unlock My Day Pro
- **Promotional Text, Description, Keywords**: from Part 3.
- **Support URL**: your support page. **Marketing URL**: optional.
- **Version**: 1.0. **Copyright**: `2026 <your name or company>`.
- **Build**: click **＋** and choose build 1.0 (1).
- **In-App Purchases and Subscriptions**: click **＋** and select all three products, so they are
  reviewed with this version.
- **App Review Information**:
  - **Sign-in required**: off (My Day has no login).
  - **Contact**: your name, phone and e-mail.
  - **Notes**: from Part 3.
- **Version Release**: *Manually release this version* (you choose the day) or
  *Automatically release*.

### Step 13. Submit
Click **Add for Review**, then **Submit to App Review**. Most apps are reviewed within 24–48
hours. If Apple asks a question or rejects something, the message appears in **App Review**
(Resolution Center). Send it to me and I will help with the fix or the reply.

### Step 14. After approval
- Release the app, if you chose manual release.
- Send me the **Apple ID** of the app (the number in *App Information → General Information*).
  I will add it as `MyDayAppStoreID`, so the **Rate My Day** button opens your App Store page.
- Add your Instagram, Facebook and X links too, if you want them in Settings.

---

## Part 3 — Text to paste

### App Name (max 30)
```
My Day: To-Do & Journal
```

### Subtitle (max 30)
```
Cute planner, diary & habits
```

### Promotional Text (max 170, can be changed any time without review)
```
Plan your day, focus on what matters and write your story, in a cute and cozy app that keeps everything private on your iPhone and in your own iCloud. 💖
```

### Keywords (max 100, commas, no spaces)
```
planner,diary,tasks,mood tracker,habit,gratitude,reminder,checklist,self care,daily,cute,goals,notes
```

### Description (max 4000)
```
My Day is your cute, cozy place to plan your day, focus on what matters and write your story. Your to-dos, top priorities and journal pages live together in one beautiful app, drawn with a sweet girl, her puppy and her kitten.

TODAY'S TO-DOS
• Add a task in seconds: type it, or tap the microphone and just say it
• Categories for Personal, Work, Health, Learning and Shopping, plus your own
• Steps inside a task, reminders, repeats and due dates
• Ready-made templates and checklists, or make your own
• A soft "ting" and a happy tick each time you finish something

TODAY'S PRIORITY
• Choose the few things that matter most today and give them your full focus
• A little celebration when everything is done

MY JOURNAL
• Write a page for every day, with a heading, your story and a word count
• Pick your mood from cute stars, and see your week in moods
• Note what you did, the goals you met, what you are grateful for, your highlight and your little win
• Add photos, stickers, voice notes, the place and the weather
• Journal templates: Gratitude, Daily Reflection, Dream Journal, Self-Care and more
• See your daily steps from Apple Health on your pages (optional, read only)
• Search and filter every page, and keep favorites

AND MUCH MORE
• Calendar: every day's to-dos, priorities and journal page at a glance
• Insights: done today, your streak, and charts of your week and your moods
• Achievements: 40 cute badges to collect as you go
• Goal Reports for your week, month and year
• Daily motivation quotes
• Gentle reminders to plan your day and write in your journal, up to five times a day
• iCloud sync, so your days follow you on every iPhone you own

MY DAY PRO
Unlock everything with My Day Pro:
• Unlimited writing on every journal page
• All 30 moods, writing prompts and daily reflections
• Photos in your journal and on your tasks
• Voice notes and the full sticker collection
• Six beautiful Pro journal themes
• Journal Lock with Face ID, a pattern or a passcode
• Shared Lists and shared to-do categories with family and friends
• Important Days: birthdays and anniversaries with reminders
• Export journal pages as beautiful PDFs, and "On This Day" memories
• Lovely reminder sounds

YOUR PRIVACY
We don't send your data to our servers, and we don't have access to your entries. Everything stays on your iPhone and, if you turn on Sync, in your own private iCloud. A list you share is seen only by the people you invite. No ads, no tracking.

SUBSCRIPTION INFORMATION
My Day is free to download. My Day Pro is available as a monthly or yearly auto-renewable subscription, or as a one-time Lifetime purchase. Payment is charged to your Apple Account when you confirm the purchase. A subscription renews automatically unless it is cancelled at least 24 hours before the end of the current period, and your account is charged for renewal within 24 hours before the end of the period. You can manage or cancel your subscription in your Apple Account settings at any time after purchase.

Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: [YOUR PRIVACY POLICY LINK]
```
Replace `[YOUR PRIVACY POLICY LINK]` with your link from Step 3.

### Subscription group display name
```
My Day Pro
```

### In-app purchase texts (Display Name max 35, Description max 55)
| Product | Display Name | Description |
|---|---|---|
| Yearly | `My Day Pro Yearly` | `Every Pro feature, best value, renews yearly` |
| Monthly | `My Day Pro Monthly` | `Every Pro feature, renews every month` |
| Lifetime | `My Day Pro Lifetime` | `Every Pro feature forever with one payment` |

### Review note for each purchase
```
Unlocks all My Day Pro features: unlimited journal writing, all 30 moods, prompts, photos, voice notes, stickers, Pro journal themes, Journal Lock, Shared Lists, Important Days, PDF export and reminder sounds. Offered on the "Unlock My Day Pro" page (Settings > My Day Pro, or any Pro feature marked with a crown).
```

### App Review notes (version page)
```
Thank you for reviewing My Day.

- No account or sign-in is needed.
- My Day Pro (monthly, yearly or lifetime) is offered on the "Unlock My Day Pro" page: Settings > My Day Pro, or tap any feature with a crown. Restore Purchases is on the same page.
- HealthKit: My Day reads only the daily step count, to show it on journal pages (Settings > Journal > Show my steps). Before the system permission sheet, the app shows its own privacy note explaining this. Nothing is written to Health, and health data is not stored in iCloud or sent anywhere.
- iCloud: to-dos and journal pages sync through the user's private CloudKit database. Shared Lists use CloudKit sharing between people the user invites. Testing sharing needs two Apple Accounts.
- The app has no servers, analytics, ads or tracking.
```

### Privacy Policy (publish this on your website)
```
Privacy Policy for My Day: To-Do & Journal
Last updated: [DATE]

My Day is made by [YOUR NAME OR COMPANY]. Your privacy matters to us, and My Day is designed so that we never see your data.

What we collect
Nothing. My Day has no servers, accounts, analytics, advertising or tracking. We do not collect, store, sell or share any personal information.

Where your data is kept
Your to-dos, priorities, journal pages, photos, voice notes and settings are stored on your iPhone. If you turn on Sync with iCloud, they are also stored in your own private iCloud account through Apple's CloudKit. Only you can access it; we cannot.

Shared Lists
When you share a list, it is stored in your iCloud and is visible only to the people you invite. You can stop sharing at any time.

Apple Health
If you allow it, My Day reads only your daily step count from Apple Health to show it on your journal pages. It reads no other health data, never writes or changes anything in Health, and never stores health data in iCloud or sends it anywhere. You can turn this off in Settings > Show my steps, or in the Health app.

Camera, microphone, photos, location, speech and Face ID
My Day uses these only when you choose a feature that needs them: taking a photo for a task or a page, recording a voice note, speaking a task, adding your place to a journal page, or unlocking your journal. They are used on your device and are not sent to us. Speech recognition may be processed by Apple according to Apple's privacy policy.

Purchases
Subscriptions and purchases are handled by Apple. We do not receive your payment details.

Children
My Day does not knowingly collect information from anyone, including children.

Changes
If this policy changes, we will update this page and the date above.

Contact
Questions? Write to [YOUR SUPPORT E-MAIL].
```

### Support page (simple)
```
My Day: To-Do & Journal — Support

Need help, found a problem, or have an idea? Write to us at [YOUR SUPPORT E-MAIL] and we will reply as soon as we can.

Restoring My Day Pro: open Settings > My Day Pro > Restore Purchases, signed in with the same Apple Account you bought it with.
Managing your subscription: iPhone Settings > [your name] > Subscriptions.
Sync: Settings > iCloud > Sync with iCloud (you must be signed in to iCloud on your iPhone).
```
