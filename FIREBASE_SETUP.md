# Setup Guide — Firebase, Permissions & the AI Model

## 1. Firebase project
1. Go to https://console.firebase.google.com → **Add project**.
2. Enable these products:
   - **Authentication** → Sign-in method → enable **Email/Password**.
   - **Firestore Database** → Create database (start in test mode for the demo).
   - **Storage** → Get started.
3. From the project root run:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This overwrites `lib/firebase_options.dart` with your real keys and adds the
   Android `google-services.json` / iOS `GoogleService-Info.plist`.

### Firestore collections (created automatically on first write)
- `users/{uid}`      → fullName, email, role, registrationNumber
- `classes/{id}`     → teacherId, code, name, schedule, studentCount
- `students/{id}`    → classId, name, registrationNumber, photoUrl, embedding[192]
- `sessions/{id}`    → classId, date, totalStudents, presentCount, avgFocus, records[]

### Suggested Firestore rules (demo)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /{doc=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 2. Camera permissions

**Android** — `android/app/src/main/AndroidManifest.xml` (inside `<manifest>`):
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```
Set `minSdkVersion 21` in `android/app/build.gradle` (ML Kit + camera need 21+).
If you hit a 64K method limit, add `multiDexEnabled true` in `defaultConfig`.

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>SmartAttend uses the camera to take attendance and detect focus.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used to pick a student photo for enrollment.</string>
```

## 3. Recognition model (MobileFaceNet)

Face **detection + focus** work out of the box (ML Kit, no model needed).
Face **recognition** needs a TFLite embedding model:

1. Download a MobileFaceNet model (192-d output, 112×112 input). A widely used
   one is `mobile_face_net.tflite` from public face-recognition Flutter repos
   (e.g. search GitHub for "MobileFaceNet tflite flutter").
2. Place it at: **`assets/models/mobilefacenet.tflite`**
3. It's already declared in `pubspec.yaml` under `assets:` — just `flutter pub get`.

If the output dimension differs (e.g. 128), change `embeddingSize` in
`lib/services/face_recognition_service.dart`. If the file is absent the app
still runs — it counts faces and scores focus, and skips name matching.

## 4. Demo flow for your presentation
1. Sign up as a **Teacher** → create a class.
2. **Enroll** 2–3 students (use clear front-facing photos).
3. **Take Attendance** → point camera at those faces → watch the live
   Detected / Focused / Distracted overlay → **capture** → see the session
   summary with names + focus % → check **Reports**.
4. Sign out → sign in as a **Student** to show the student side.
