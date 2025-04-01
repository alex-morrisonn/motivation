# Moti - Daily Motivation App

## Overview

Moti is an iOS application designed to deliver daily motivation and inspiration through carefully curated quotes. The app helps users stay positive, focused, and motivated through life's journey with an elegant dark-themed user interface.

## Features

### 📝 Daily Quotes
- A new inspirational quote each day
- Ability to refresh and get random quotes
- Share quotes with friends and family

### 🗂️ Organized Categories
- Browse quotes by categories including:
  - Success & Achievement
  - Life & Perspective
  - Dreams & Goals
  - Courage & Confidence
  - Perseverance & Resilience
  - Growth & Change
  - Action & Determination
  - Mindset & Attitude
  - Focus & Discipline

### ❤️ Favorites Collection
- Save quotes that resonate with you
- Build your personal collection of inspiration
- Easy access to your favorite quotes

### 📅 Event Tracking
- Add important dates and events
- Calendar view for tracking upcoming events
- Visual indicators for days with events

### 🔥 Streak System
- Track daily app usage with a streak counter
- Celebrate milestone streaks (3, 7, 50, 100 days)
- Provides motivation for consistent usage

### 🖼️ Widgets
- Home screen widgets in small, medium, and large sizes
- Lock screen widgets (circular, rectangular, and inline)
- Daily quote updates directly on your home screen

## Technology Stack

- **SwiftUI**: Modern declarative UI framework
- **WidgetKit**: For home screen and lock screen widgets
- **Firebase**: Analytics, Crashlytics, and Firestore
- **GoogleMobileAds**: For ad integration
- **App Groups**: For sharing data between app and widgets

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+


## Project Structure

```
Moti/
├── MotiApp/                 # Main app code
│   ├── ContentView.swift    # Main view container
│   ├── HomeQuoteView.swift  # Home tab view
│   ├── CategoriesView.swift # Categories tab
│   ├── FavoritesView.swift  # Favorites tab
│   ├── StreakManager.swift  # Streak tracking
│   └── ...
├── MotiWidget/              # Widget extension
│   ├── MotiWidget.swift     # Widget implementation
│   └── ...
├── SharedQuotes.swift       # Shared quotes database
└── ...
```

## Usage

### Adding Widgets

1. **Home Screen Widgets**:
   - Long press on an empty area of your Home Screen
   - Tap the + button in the top-left corner
   - Search for "Moti" or scroll to find it
   - Choose a widget size by swiping left or right
   - Tap "Add Widget" and position it where you want

2. **Lock Screen Widgets**:
   - Long press on your Lock Screen to enter edit mode
   - Tap "Customize"
   - Select the area where you want to add a widget
   - Tap the + button
   - Find "Moti" and select a widget style

### Event Management

1. Navigate to the Home tab
2. Use the calendar interface to select a date
3. Tap "Add Event" to create a new event
4. Fill in event details and save

### Building a Streak

Simply open the app daily to build your streak. The app will track your consecutive days and celebrate when you reach milestones!

## Privacy

Moti respects user privacy:
- Most data is stored locally on your device
- Analytics helps improve the app but can be disabled
- Optional device information may be included with feedback
- No personally identifiable information is collected without consent

See our [Privacy Policy](index.md) for more details.

## Future Features

- Premium tier with additional features (in development)
- Custom themes and appearance options
- Enhanced widget customization
- Quote export in beautiful designs

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or feedback, please reach out to us at motii.team@gmail.com

---

<p align="center">
  Made with ❤️ by Moti Team
</p>
