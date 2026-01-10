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
| ⏪⏩ Seek ±10s | Quick skip forward/backward |
| ⏮️⏭️ Next/Previous | Switch between tracks in playlist |
| 📂 File Browser | Browse and play any video from your laptop |
| 🎵 Custom Playlists | Create, save, and load your own video queues |
| 🔊 Volume | Smooth slider with 300ms debounce |
| 🎧 Audio Tracks | Select different audio tracks |
| 📝 Subtitles | Enable/disable and switch subtitle tracks |
| ⚡ Playback Speed | Adjust speed from 0.25x to 2x |
| 📺 Fullscreen | One-tap toggle |
| 📡 Auto-connect | Remembers last connection |
| 🌙 Dark Mode | Default dark theme for TV viewing |
| 💨 Fast Polling | Status updates every 1.5 seconds |
| 📱 Optimistic UI | Instant feedback before server response |

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
│   ├── vlc_api_service.dart        # HTTP communication layer
│   └── playlist_service.dart       # Save/load playlists to storage
│
├── providers/
│   └── vlc_provider.dart           # State management (ChangeNotifier)
│
├── screens/
│   ├── setup_screen.dart           # Connection configuration
│   ├── remote_screen.dart          # Main remote control UI
│   ├── file_browser_screen.dart    # Browse files on VLC host
│   ├── playlists_screen.dart       # View/manage saved playlists
│   └── playlist_editor_screen.dart # Edit playlist items
│
├── widgets/
│   ├── big_control_button.dart     # Play/pause button
│   ├── volume_slider.dart          # Debounced volume control
│   └── seek_buttons.dart           # ±10s seek controls
│
└── utils/
    ├── app_theme.dart              # Theme configuration (Manrope font)
    └── basic_auth.dart             # HTTP Basic Auth helper
```

---

## 🔄 Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        VLC Media Player                         │
│                   (Laptop with Web Interface)                   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ HTTP (Port 8080)
                           │ Basic Auth
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     VlcApiService                               │
│  • GET /requests/status.xml (polling)                          │
│  • GET /requests/status.xml?command=... (controls)             │
│  • XML parsing → VlcStatus model                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      VlcProvider                                │
│  • Connection state management                                  │
│  • 1.5s polling timer                                          │
│  • Optimistic UI updates                                       │
│  • SharedPreferences persistence                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ notifyListeners()
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                         UI Layer                                │
│  • SetupScreen (config)                                        │
│  • RemoteScreen (controls)                                     │
│  • Reusable widgets                                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 Core Components

### 1. VlcStatus (Model)

Represents the current state of VLC Media Player.

```dart
class VlcStatus {
  final String state;      // 'playing', 'paused', 'stopped'
  final int volume;        // 0-512 (256 = 100%)
  final int time;          // Current position in seconds
  final int length;        // Total duration in seconds
  final String title;      // Media title
  final bool fullscreen;   // Fullscreen state
  
  // Computed properties
  bool get isPlaying;
  bool get hasMedia;
  double get progress;     // 0.0 to 1.0
  int get volumePercent;   // 0 to 200
  String get timeDisplay;  // "MM:SS / MM:SS"
}
```

### 2. VlcApiService (Service)

Handles all HTTP communication with VLC's Web Interface.

**Endpoints used:**
| Action | Endpoint |
|--------|----------|
| Get Status | `GET /requests/status.xml` |
| Play/Pause | `?command=pl_pause` |
| Volume | `?command=volume&val=<0-512>` |
| Seek | `?command=seek&val=±10s` |
| Fullscreen | `?command=fullscreen` |
| Next Track | `?command=pl_next` |
| Previous Track | `?command=pl_previous` |
| Browse Files | `GET /requests/browse.xml?uri=<path>` |
| Play File | `?command=in_play&input=<file_uri>` |

**Features:**
- Basic Auth header generation
- XML response parsing
- Human-readable error messages
- 5-second timeout
- Connection testing
- File browsing and playback

### 3. VlcProvider (State Management)

Central state manager using ChangeNotifier pattern.

**Responsibilities:**
- Store connection settings (IP, port, password)
- Manage connection lifecycle
- Poll VLC status every 1.5 seconds
- Pause polling when app is backgrounded
- Provide optimistic UI updates
- Persist settings with SharedPreferences

**Connection States:**
```
disconnected → connecting → connected
                    ↓
                  error
```

### 4. UI Screens

**SetupScreen:**
- IP address, port, password inputs
- Input validation
- "Test Connection" functionality
- Setup instructions

**RemoteScreen:**
- Media title and progress
- Play/pause button (center)
- ±10s seek buttons
- Volume slider (debounced)
- Fullscreen toggle
- Pull-to-refresh
- Connection status indicator

---

## 🎨 Design System

### Typography

**Font:** Manrope (Google Fonts)

| Style | Size | Weight |
|-------|------|--------|
| Title Large | 28px | Bold |
| Title Medium | 18px | SemiBold |
| Body | 15px | Regular |
| Label | 13px | Medium |

### Colors

| Role | Light | Dark |
|------|-------|------|
| Primary | #FF6B35 | #FF6B35 |
| Accent | #00D4AA | #00D4AA |
| Background | - | #0D0D0D |
| Surface | - | #1A1A1A |
| Surface Variant | - | #2A2A2A |

### Components

- **Buttons:** 16px border radius, 18px vertical padding
- **Inputs:** Filled, 16px border radius, no visible border
- **Cards:** 20px border radius, subtle background

---

## 🔒 Security

- ✅ Passwords never logged
- ✅ Credentials stored locally (SharedPreferences)
- ✅ Local network only (no internet communication)
- ✅ Basic Auth over HTTP (VLC limitation)
- ✅ No analytics or tracking

---

## ⚡ Performance Optimizations

| Optimization | Implementation |
|--------------|----------------|
| Debounced volume | 300ms delay before API call |
| Optimistic UI | Immediate visual feedback |
| Polling pause | Stop polling when backgrounded |
| Silent retry | Don't show errors for transient failures |
| Efficient rebuild | Consumer widgets for targeted updates |

---

## 🚀 Getting Started

### VLC Setup (Detailed Guide)

Follow these steps **exactly** to enable VLC's Web Interface:

#### Step 1: Open Preferences
- In VLC, go to **Tools** → **Preferences** (or press `Ctrl+P`)

#### Step 2: Show ALL Settings ⚠️ IMPORTANT
- Look at the **BOTTOM LEFT corner** of the Preferences window
- You'll see two radio buttons: **"Simple"** and **"All"**
- Click **"All"** to reveal advanced settings
- The left sidebar will now show many more options

#### Step 3: Enable Web Interface
- In the **left sidebar**, click **"Interface"**
- Then click **"Main interfaces"** (under Interface)
- In the **right panel**, you'll see checkboxes for different interfaces
- ✅ Check the **"Web"** checkbox

#### Step 4: Set Your Password ⚠️ IMPORTANT
- **Stay in the left sidebar** - look at "Main interfaces"
- Click the **arrow/triangle** next to "Main interfaces" to **expand** it
- You'll see sub-items appear, including **"Lua"**
- Click on **"Lua"**
- In the right panel, find the **"Lua HTTP"** section
- Enter a password in the **"Password"** field
- **Remember this password** - you'll need it in the app!

#### Step 5: Save & Restart VLC
- Click **"Save"** at the bottom of the Preferences window
- **Completely close VLC** (not just minimize)
- **Reopen VLC**
- The Web Interface is now running on port 8080

### Run the App

```bash
# Install dependencies
flutter pub get

# Run on device
flutter run

# Build APK
flutter build apk
```

### Find Your Laptop's IPv4 Address

**Windows:**
```cmd
ipconfig
```
- Look for **"Wireless LAN adapter Wi-Fi"** or **"Ethernet adapter"**
- Find the line that says **"IPv4 Address"** (NOT IPv6!)
- It will look like: `192.168.x.x` or `10.0.x.x`
- Use this **IPv4 address** in the app

**macOS:**
```bash
ipconfig getifaddr en0
```

**Linux:**
```bash
hostname -I | awk '{print $1}'
```

> ⚠️ **Important:** Use the **IPv4** address (4 numbers separated by dots), NOT the IPv6 address (long string with colons).

---

## 🧪 Testing

```bash
# Run tests
flutter test

# Analyze code
flutter analyze
```

---

## 📱 Platform Support

| Platform | Status |
|----------|--------|
| Android | ✅ Primary |
| iOS | ✅ Compatible |
| Web | ❌ Not supported |
| Desktop | ❌ Not supported |

---

## 🚫 What This App Does NOT Do

- ❌ File browser / playlist management
- ❌ Keyboard / mouse simulation
- ❌ YouTube / Netflix / streaming control
- ❌ PC power controls
- ❌ Require laptop-side software
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
