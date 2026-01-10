# VLC Remote

A minimal, fast, ad-free VLC Remote mobile app that controls VLC Media Player using only VLC's built-in Web Interface.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logo=dart&logoColor=white)
![Material 3](https://img.shields.io/badge/Material%203-6750A4?style=flat)

---

## 🎯 Purpose

This app is designed for a specific use case:

- **Watching VLC on a laptop connected to a TV**
- **Sitting on a sofa**  
- **Wanting big, reliable media controls**

It's a **TV remote experience**, not a PC control panel.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| ▶️ Play/Pause | Large, centered button with haptic feedback |
| 🔍 Deep Search | **Recursive file search** across your entire C: drive to find media |
| 📂 File Browser | Browse your PC's folders and play files directly |
| 🎵 Playlist Editor | Create, edit, reorder, and save custom playlists |
| 📍 Seek Bar | Drag to seek or tap to jump to specific timestamp |
| ⏪⏩ Seek ±10s | Quick skip forward/backward buttons |
| 🎧 Audio Tracks | Select audio languages/tracks with persistence |
| 📝 Subtitles | Enable/disable and switch subtitle tracks |
| ⚡ Playback Speed | Adjust speed from 0.25x to 2x |
| 📺 Fullscreen | One-tap toggle for cinema mode |
| 📡 Auto-connect | Remembers last connection details |
| 🌙 Dark Mode | Optimized OLED-friendly dark UI |
| 📱 Optimistic UI | Instant feedback on all controls |

---

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart                       # App entry point, theme setup, routing
│
├── models/
│   ├── vlc_status.dart             # Data model for VLC playback state
│   ├── file_item.dart              # File/folder model for browsing
│   └── playlist.dart               # Playlist and PlaylistItem models
│
├── services/
│   ├── vlc_api_service.dart        # HTTP layer, XML parsing, Recursive Search Algo
│   └── playlist_service.dart       # JSON storage for custom playlists
│
├── providers/
│   └── vlc_provider.dart           # State management & Optimistic updates
│
├── screens/
│   ├── setup_screen.dart           # Connection configuration
│   ├── remote_screen.dart          # Main controls (Seek, Volume, Playback)
│   ├── file_browser_screen.dart    # Deep search & file navigation
│   ├── playlists_screen.dart       # Saved playlists management
│   └── playlist_editor_screen.dart # "Play from index" & playlist modification
│
├── widgets/
│   ├── big_control_button.dart     # Play/pause button
│   ├── volume_slider.dart          # Debounced volume control
│   └── media_settings_sheet.dart   # Audio/Sub/Speed controls
│
└── utils/
    ├── app_theme.dart              # Manrope font & Color scheme
    └── basic_auth.dart             # Auth helper
```

---

## 🔄 Search & Algorithms

### Recursive Deep Search
The app implements a custom **BFS (Breadth-First Search)** algorithm to scan your PC directly via the VLC interface.
- **Real-time Streaming:** Results appear as they are found.
- **Smart Prioritization:** Searches common folders (Users, Movies, Downloads) first.
- **Cancellation:** Instantly stops when you navigate away or select a file.
- **Optimized:** Skips system folders (Windows, Program Files) to save time.

---

## 🚫 What This App Does NOT Do

- ❌ Keyboard / mouse simulation
- ❌ YouTube / Netflix / streaming control
- ❌ PC power controls (Shutdown/Sleep)
- ❌ Require laptop-side software (Only VLC required)
- ❌ Display ads or collect analytics

---

## 📄 Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| State | Provider (ChangeNotifier) |
| HTTP | http package |
| XML | xml package |
| Storage | shared_preferences |
| Fonts | google_fonts (Manrope) |
| Design | Material 3 |

---

## 🤝 Philosophy

> "This app should feel like a TV remote, not a control panel."

- **Minimal:** Only essential controls
- **Fast:** No startup delays
- **Reliable:** Works consistently
- **Beautiful:** Premium, clean design
- **Focused:** One thing, done well

---

## 📄 License

MIT License

---

Made with ❤️ for couch potatoes everywhere.
