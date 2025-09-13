# 🏋️ IronTimer

**IronTimer** is a simple, clean gym tracker for iOS. Log your daily workouts with just a few taps, track your progress in a clear journal view, and analyze your performance with intuitive charts. Export your training history as CSV whenever you need.

---

## ✨ Features

### Today
- Log your workout of the day directly on the first page.
- Add new exercises via a floating **+** button (bottom-left).
- Choose from:
  - **Top 5 common lifts** (Squat, Bench Press, Deadlift, Overhead Press, Barbell Row)
  - **Search catalog** of existing exercises
  - **Create new exercise** (automatically added to your catalog).
- Add sets (reps × weight) quickly.
- Haptic feedback makes logging feel responsive.

### Journal
- View a chronological list of past workouts.
- Each day shows the exercises you did and total reps per exercise.
- Simple, scrollable journal format.

### Analysis
- Visualize your training progress with charts powered by [Swift Charts](https://developer.apple.com/documentation/charts):
  - **Training Volume over Time** (kg)
  - **Total Reps per Day**
  - **Top 5 Exercises by Volume**
- Export all your workout history to **CSV** (via Share Sheet) for use in Excel, Numbers, or Google Sheets.

---

## 🛠️ Tech Stack

- **SwiftUI** – declarative, modern iOS UI
- **SwiftData** – local persistence of workouts, exercises, and sets
- **Swift Charts** – built-in data visualization
- **ShareLink / Transferable** – CSV export
- **Haptics** – subtle feedback on interactions

---

## 🚀 Getting Started

1. Clone the repo or copy the files into a new Xcode project.
2. Make sure you’re on **Xcode 15+** (iOS 17 SDK).
3. Build & run on device or simulator.
4. Start logging your first workout!

---

## 📈 Roadmap

- [ ] Weekly consistency streaks
- [ ] Estimated 1RM trends per exercise
- [ ] Exercise filtering in Analysis
- [ ] iCloud sync across devices
- [ ] Widgets / Live Activities (quick log, rest timer)

---

## 📜 License

This project is for personal use.  
Feel free to adapt or extend it for your own gym tracking needs.

