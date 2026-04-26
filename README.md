# 💪 Fitness Tracker

A modern, beautiful, and fully functional fitness tracking mobile app built with **Flutter** & **Firebase**.

Track your workouts, monitor your progress, maintain streaks, unlock achievements, and stay motivated every day!
---

## ✨ Features

### 🔹 Core Features

* **Add & Edit Workouts** with name, type, duration, preferred time, and notes
* **Real-time Dashboard** with live statistics
* **Weekly Activity Chart** (using Syncfusion Charts)
* **Workout Distribution** (Doughnut Chart)
* **Calendar View** with workout markers
* **Streak Tracking** (Current workout streak)

### 📊 Progress Statistics

* Total workouts
* Completed workouts
* Total minutes trained
* Current streak

---

### 🎮 Gamification & Motivation

* **Achievements System** with confetti celebrations:

  * 🥇 First Steps
  * 🔥 Consistent Trainee (3-day streak)
  * 🛡 Week Warrior (7-day streak)
  * 💪 Dedicated (10 workouts)
  * 👑 Master (25 workouts)
  * ⏱ Endurance King (500 minutes)
  * 🎯 Variety Expert
  * 🌅 Early Bird

* Daily motivational quotes

* Points & progress tracking

---

### 🔐 Authentication

* Email & Password Authentication using Firebase Auth
* Secure user registration & login
* Persistent user sessions

---

### ⚙️ Additional Features

* Mark workouts as **completed / pending**
* Delete workouts
* Responsive UI (phones & tablets)
* Beautiful gradient cards & modern UI
* Pull-to-refresh support

---

## 🛠️ Tech Stack

* **Framework**: Flutter (Dart)

* **Backend**: Firebase

  * Firebase Authentication
  * Cloud Firestore (Real-time database)

* **Charts**: Syncfusion Flutter Charts

* **UI Components**:

  * Table Calendar
  * Confetti (for achievements)
  * Intl (date formatting)


---

## 🚀 Getting Started

### 📋 Prerequisites

* Flutter SDK (latest stable)
* Firebase Project setup
* Android Studio / VS Code

---

## ⚡ Setup Instructions

### 1️⃣ Clone the repository

```bash
git clone https://github.com/yourusername/fitness-tracker.git
cd fitness-tracker
```

---

### 2️⃣ Install dependencies

```bash
flutter pub get
```

---

### 3️⃣ Setup Firebase

1. Create a new Firebase project

2. Enable **Authentication (Email/Password)**

3. Enable **Firestore Database**

4. Download:

   * `google-services.json` (Android)
   * `GoogleService-Info.plist` (iOS)

5. Place them in the correct directories

---

### 4️⃣ Run the app

```bash
flutter run
```

---

## 📂 Project Structure

```text
fitness-tracker/
├── lib/
│   ├── main.dart
│   ├── Dashboard.dart
│   ├── AddWorkout.dart
│   ├── ViewWorkout.dart
│   ├── Achievements.dart
│   ├── WorkoutLogin.dart
│   ├── Workout_register.dart
│   └── ...
├── assets/
│   └── images/          # App images & icons
└── pubspec.yaml
```

---

## 🎯 Future Enhancements (Planned)

* 🌙 Dark Mode support
* 🏋️ Workout templates & presets
* 🌍 Social features (share achievements)
* 🎥 Exercise library with animations
* 🎯 Goal setting & reminders
* 📄 Export workout data (PDF/CSV)
* 🔗 Integration with Google Fit / Apple Health

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the project
2. Create your feature branch

   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit your changes

   ```bash
   git commit -m 'Add amazing feature'
   ```
4. Push to the branch

   ```bash
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License**.

---

## 👨‍💻 Author

**nipul**
Built with ❤️ for fitness enthusiasts 💪


---
