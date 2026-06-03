<div align="center">

# 🎓 SmartAttend
### AI-Powered Attendance & Focus Detection System

[![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-10.22-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![ML Kit](https://img.shields.io/badge/ML%20Kit-Face%20Detection-4285F4?logo=google&logoColor=white)](https://developers.google.com/ml-kit)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey?logo=apple)](https://flutter.dev/multi-platform)

> **Mobile Computing GN341 — Final Project**  
> Real-time face recognition attendance system with live focus monitoring

</div>

---

## ✨ What is SmartAttend?

SmartAttend replaces paper registers and manual roll calls with an **AI camera system**. A teacher points their phone at the classroom — the app detects every face, matches them to enrolled students using on-device machine learning, marks attendance automatically, and tracks how focused each student is during the session.

Students log in with their registration number and see their **live attendance history**, **focus scores**, and **performance stats** — all synced in real time through Firebase.

---

## 🚀 Key Features

### 👩‍🏫 Teacher Side
| Feature | Description |
|--------|-------------|
| 📸 **Photo Attendance** | Capture a still photo → AI recognises all faces → instant results |
| 🎥 **Video Attendance** | Live stream scans the room every 3 seconds, builds a detected-student list in real time |
| 🧠 **Focus Monitoring** | ML Kit head-pose + eye-open detection scores each student's attention level |
| 👤 **Student Enrollment** | Enroll students with name, reg number, and a face selfie — embeddings stored in Firestore |
| 📊 **Session Reports** | Per-session breakdown: present / absent, focus %, class averages |
| 🗂 **Class Management** | Create, archive, or delete classes; view full attendance history per class |

### 🎒 Student Side
| Feature | Description |
|--------|-------------|
| 📋 **Live Attendance History** | See every session — present/absent status + focus score per class |
| 📈 **Focus Trend Chart** | Bar chart of focus scores over recent sessions |
| 🔗 **Auto-Linked via Reg Number** | Student account auto-connects to classes where their reg number was enrolled |
| 🏠 **Dashboard Stats** | Real attendance %, average focus, enrolled course count — all live from Firestore |

---

## 🤖 AI / ML Pipeline

```
Camera Frame
     │
     ▼
┌─────────────────────────────┐
│  Google ML Kit              │
│  Face Detection             │  ← On-device, no internet needed
│  • Bounding box             │
│  • Head pose (yaw/pitch)    │
│  • Eye-open probability     │
└─────────────┬───────────────┘
              │
     ┌────────▼────────┐
     │  Focus Scoring  │  ← FocusService: head angle + eye-open → 0..1 score
     └────────┬────────┘
              │
     ┌────────▼────────────────────────┐
     │  Face Recognition (NCC)         │
     │  • 48×48 grayscale face crop    │
     │  • Normalized Cross-Correlation │  ← Threshold 0.28
     │  + Cosine similarity fallback   │
     └────────┬────────────────────────┘
              │
     ┌────────▼────────┐
     │  Match against  │
     │  enrolled faces │  ← Stored pixel embeddings in Firestore
     └────────┬────────┘
              │
     ┌────────▼────────┐
     │  Mark Present / │
     │  Absent + Save  │  ← Firebase Firestore session
     └─────────────────┘
```

---

## 🏗 Architecture

```
lib/
├── main.dart                    # Firebase init + Provider setup
├── app.dart                     # Router
├── firebase_options.dart        # Firebase config
│
├── models/
│   ├── app_user.dart            # Authenticated user (teacher / student)
│   ├── class_model.dart         # Course: name, code, schedule
│   ├── student_model.dart       # Enrolled student + face embedding
│   └── attendance.dart          # AttendanceSession + AttendanceRecord
│
├── services/
│   ├── auth_service.dart        # Firebase Auth wrapper
│   ├── firestore_service.dart   # All Firestore reads/writes
│   ├── face_detection_service.dart    # ML Kit face detector
│   ├── face_recognition_service.dart  # NCC + cosine matching
│   └── focus_service.dart             # Head-pose focus scoring
│
├── screens/
│   ├── auth/                    # Login, signup, onboarding
│   ├── teacher/                 # Classes, enrollment, attendance, reports
│   └── student/                 # Dashboard, attendance history, focus chart
│
└── providers/
    └── auth_provider.dart       # App-wide auth state
```

---

## 🔥 Firebase Structure

```
Firestore
├── users/{uid}
│   ├── fullName, email, role
│   └── registrationNumber (students)
│
├── classes/{classId}
│   ├── name, code, schedule, teacherId
│   └── studentCount
│
├── students/{studentId}
│   ├── classId, name, registrationNumber
│   ├── photoUrl (base64 face thumbnail)
│   └── embedding [2304 floats — 48×48 NCC vector]
│
└── sessions/{sessionId}
    ├── classId, date, totalStudents, presentCount, avgFocus
    └── records: [ { studentId, studentName, present, focusScore, state } ]
```

---

## ⚙️ Setup & Run

### Prerequisites
- Flutter 3.44+
- Xcode 15+ (iOS) / Android Studio (Android)
- A Firebase project

### 1. Clone & Install
```bash
git clone https://github.com/Fubuexe/SmartAttend_Flutter_Project.git
cd SmartAttend_Flutter_Project
flutter pub get
```

### 2. Firebase Setup
1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password) and **Firestore**
3. Add an iOS app → download `GoogleService-Info.plist` → place in `ios/Runner/`
4. Add an Android app → download `google-services.json` → place in `android/app/`
5. Update `lib/firebase_options.dart` with your project credentials

### 3. Run
```bash
flutter run
```

### 4. Build APK
```bash
flutter clean
flutter pub get
flutter build apk --release
# APK → build/app/outputs/flutter-apk/app-release.apk
```

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter 3.44 / Dart 3.12 |
| Backend | Firebase Firestore + Firebase Auth |
| Face Detection | Google ML Kit Face Detection |
| Face Recognition | Custom NCC + Cosine similarity (on-device, no server) |
| State Management | Provider |
| Charts | fl_chart |
| Camera | camera plugin |
| Image Processing | image package |

---

## 🔐 Security Note

Firebase credentials (`GoogleService-Info.plist`, `google-services.json`, `firebase_options.dart`) are included for demo purposes as this is a university project submission.

---

<div align="center">
Made with ❤️ for GN341 Mobile Computing
</div>
