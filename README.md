# 🐦 Flutter Bird Game

একটি Flappy Bird style গেম — Sound Effects ও Multiple Levels সহ।

---

## 📁 Project Structure

```
flappy_bird_game/
├── lib/
│   ├── main.dart                  ← App entry point
│   ├── models/
│   │   ├── game_config.dart       ← Level config & constants
│   │   └── pipe.dart              ← Pipe data model
│   ├── screens/
│   │   └── game_screen.dart       ← Main game screen (সব logic এখানে)
│   ├── widgets/
│   │   ├── bird_widget.dart       ← পাখির UI
│   │   ├── pipe_widget.dart       ← Pipe UI
│   │   └── background_widget.dart ← Sky, clouds, ground
│   └── audio/
│       └── audio_manager.dart     ← Sound effects manager
├── assets/
│   ├── audio/                     ← Sound files (নিচে দেখুন)
│   └── images/                    ← (optional)
└── pubspec.yaml
```

---

## 🎮 Game Features

- ✅ **Flappy Bird mechanics** — tap করে পাখি উড়ান
- ✅ **3টি Level** — Easy → Medium → Hard (score বাড়লে auto unlock)
- ✅ **Sound Effects** — flap, score, die, level up
- ✅ **High Score save** — SharedPreferences দিয়ে
- ✅ **Smooth animations** — death shake, level up pop
- ✅ **Sound toggle** — মিউট করার অপশন
- ✅ **Play Store ready** — সব config সেট করা

---

## 🔊 Sound Files যোগ করুন

`assets/audio/` ফোল্ডারে এই ৪টি MP3 file রাখুন:

| File | কোথায় পাবেন |
|------|-------------|
| `flap.mp3` | freesound.org → "flap" |
| `score.mp3` | freesound.org → "ding" |
| `die.mp3` | freesound.org → "hit" |
| `levelup.mp3` | freesound.org → "level up" |

> 🆓 সব sound [freesound.org](https://freesound.org) থেকে free (CC0 license) download করুন।

---

## 🚀 প্রথমবার Run করুন

```bash
# ১. Dependencies install
flutter pub get

# ২. Debug run
flutter run

# ৩. Release APK বানান
flutter build apk --release
```

---

## 📱 Play Store এ Publish করার Steps

### Step 1 — Signing Key বানান
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### Step 2 — `android/key.properties` ফাইল বানান
```
storePassword=আপনার_password
keyPassword=আপনার_password
keyAlias=upload
storeFile=/home/আপনার_user/upload-keystore.jks
```

### Step 3 — `android/app/build.gradle` এ signing config যোগ করুন
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
keystoreProperties.load(new FileInputStream(keystorePropertiesFile))

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Step 4 — App Bundle বানান (Play Store পছন্দ করে)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Step 5 — Play Console এ Upload করুন
1. [play.google.com/console](https://play.google.com/console) এ যান
2. নতুন app create করুন
3. "Production" → "Create new release"
4. `app-release.aab` upload করুন
5. App description, screenshots, icon যোগ করুন
6. Submit করুন ✅

---

## 🎨 Customize করতে চাইলে

| কী বদলাবেন | কোথায় |
|-----------|-------|
| Level কঠিন/সহজ করুন | `lib/models/game_config.dart` → `LevelConfig` |
| পাখির রঙ বদলান | `lib/widgets/bird_widget.dart` |
| Background বদলান | `lib/widgets/background_widget.dart` |
| Pipe speed বাড়ান | `game_config.dart` → `pipeSpeed` |

---

## 📋 Play Store Checklist

- [ ] Sound files (`assets/audio/`) যোগ করুন
- [ ] App icon বানান (512x512 PNG)
- [ ] Screenshots নিন (অন্তত 2টি)
- [ ] Signing key বানান
- [ ] `version: 1.0.0+1` update করুন (`pubspec.yaml`)
- [ ] `applicationId` unique করুন (`android/app/build.gradle`)
- [ ] Privacy Policy URL দিন (Play Store-এ required)

---

## 💡 Tips

- **applicationId** অবশ্যই unique হতে হবে, যেমন: `com.yourname.flutterbirdgame`
- App icon-এর জন্য [appicon.co](https://appicon.co) ব্যবহার করুন
- Screenshot-এর জন্য emulator ব্যবহার করুন

---

Made with Flutter 💙
