# SmartAttend — AI-Powered Attendance & Focus Detection

Mobile Computing (GN341) final project. A **Flutter** app with a **Firebase**
backend that uses **on-device computer vision** to:

1. **Detect faces** live in the classroom (Google ML Kit).
2. **Score focus / distraction** per student from head pose + eye-open
   probability.
3. **Recognise identity** (which enrolled student is which) using a
   **MobileFaceNet** TFLite model + cosine-similarity matching.

Two account types — **Teacher** and **Student** — with role-based navigation.

---

## Feature map

**Teacher**
- Sign up / sign in / reset password (Firebase Auth, role stored in Firestore)
- Create classes, enroll students (photo → face embedding stored in Firestore)
- **Take Attendance**: live camera, real-time detected/focused/distracted
  overlay, then capture → recognise students → save session
- Session summary + Reports (attendance rate & focus trend charts)

**Student**
- Dashboard, attendance history, weekly focus chart, profile

18 screens total (exceeds the 15-screen requirement), all connected with
named routes, back buttons, and sign in/out.

---

## How the AI works

| Task | Engine | Output |
|------|--------|--------|
| Face detection | `google_mlkit_face_detection` (on-device) | bounding boxes, head Euler angles, eye-open probabilities |
| Focus scoring | `FocusService` (our heuristic) | 0–1 score → Focused / Distracted |
| Identity recognition | MobileFaceNet `.tflite` via `tflite_flutter` | 192-d embedding → cosine match |

Focus score = 0.45·(facing-forward yaw) + 0.25·(pitch) + 0.30·(eyes open).
Recognition compares a face embedding to enrolled students; best match above
cosine 0.55 is marked present. If the model file is missing, the app
**degrades gracefully** to face-counting + focus only (still fully functional).

---

## Run it (Flutter + Firebase already installed)

```bash
# 1. Generate platform folders if you don't have them yet
flutter create .

# 2. Get packages
flutter pub get

# 3. Connect Firebase (creates the real firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Add the recognition model (see "Recognition model" below)

# 5. Run on a real device (camera + ML Kit need a physical phone)
flutter run
```

> Use a **physical device** — the camera, ML Kit and TFLite do not work on most
> emulators.

See **FIREBASE_SETUP.md** for Firebase, permissions, and the model file.

## Project structure

```
lib/
  models/      app_user, class, student, attendance
  services/    auth, firestore, storage, face_detection, face_recognition, focus
  providers/   auth_provider (Provider state)
  screens/     auth/ • teacher/ • student/ • shared/
  widgets/     reusable button, field, card, stat chip
  theme/       light brand theme (violet #6C5CE7)
```
