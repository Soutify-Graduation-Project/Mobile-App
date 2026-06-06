# Soutify — Mobile Application

**Soutify** is a Flutter-based mobile application that provides an accessible, personalized Arabic speech recognition interface. It is designed primarily for users with speech or communication impairments, enabling them to have their voice recognized accurately after a guided voice-enrollment session. The application communicates with a dedicated backend server for all speech processing tasks.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Application Features](#2-application-features)
3. [Architecture Overview](#3-architecture-overview)
4. [Logic Flow](#4-logic-flow)
   - 4.1 [Application Startup & Authentication](#41-application-startup--authentication)
   - 4.2 [Voice Enrollment (Personalization)](#42-voice-enrollment-personalization)
   - 4.3 [Free Speech (Live ASR)](#43-free-speech-live-asr)
5. [Backend API Reference](#5-backend-api-reference)
6. [Project Structure](#6-project-structure)
7. [Dependencies](#7-dependencies)
8. [Running the Application](#8-running-the-application)

---

## 1. Project Overview

Soutify addresses the challenge of automatic speech recognition (ASR) systems performing poorly on atypical or impaired speech patterns. The application implements a **speaker-adaptive enrollment pipeline**: the user records a set of Arabic words across multiple semantic categories, those recordings are uploaded to the backend server, and a personalization process adapts the ASR and audio models to the user's unique vocal characteristics. Once personalization is complete, the user gains access to the **Free Speech** interface, which transcribes unrestricted spoken Arabic in real time and optionally plays back a text-to-speech (TTS) response.

---

## 2. Application Features

### 2.1 User Authentication

The application supports user account management through a standard email and password scheme. New users may register via a sign-up form; returning users authenticate via login. Upon successful authentication, a JWT access token is persisted locally using `SharedPreferences` and attached as a Bearer token to all subsequent API requests. The session persists across application restarts; logout clears all stored credentials.

### 2.2 Voice Enrollment (Personalization)

Voice enrollment is the prerequisite step before free-speech recognition is available. The user is presented with a scrollable carousel of **94 Arabic words** spanning eight semantic categories:

| Category (Arabic) | Domain |
|---|---|
| حيوانات | Animals |
| أكل | Food |
| بيت | Home objects |
| لبس | Clothing |
| جسم | Body parts |
| طبيعة | Nature |
| ألوان | Colors |
| أفعال | Actions |
| أماكن | Places |

Each word is displayed alongside a corresponding illustrative image. For every word, the user:

1. Presses the **Record** button to begin capturing audio.
2. Speaks the displayed Arabic word into the device microphone.
3. Presses **Stop** to finalize the recording.
4. Optionally plays the recording back for verification before it is uploaded.

Each recorded clip is stored locally as a 16 kHz, 256 kbps WAV file and immediately uploaded to the server. A progress indicator reflects the upload status of each individual clip. Once the minimum required number of clips (default: 5) has been uploaded successfully, a **Start Personalization** button becomes available. Pressing it invokes the server-side model adaptation process. Upon completion, the Free Speech tab is unlocked.

Re-enrollment is supported at any time: recording additional phrases after initial personalization presents an **Update Personalization** button, which triggers a new round of model adaptation incorporating the new recordings.

### 2.3 Free Speech (Live ASR)

The Free Speech interface provides unrestricted, real-time Arabic speech recognition using the personalized model. The interaction follows four phases:

| Phase | Description |
|---|---|
| **Idle** | The user taps the microphone button to begin. |
| **Recording** | Audio is captured and stored to a temporary WAV file; the button pulses red to signal active recording. |
| **Processing** | The user taps the button again to stop recording; the audio file is sent to the server for transcription. A loading indicator is displayed. |
| **Revealing** | The transcription result is rendered using a character-by-character typewriter animation. If the server response includes a TTS audio payload, it is played back automatically. After a short delay, the interface returns to the idle state. |

### 2.4 Accessibility

The application has been designed with accessibility as a first-class concern:

- All interactive controls carry semantic labels for screen-reader compatibility.
- Minimum tap-target sizes of 48×48 dp are enforced throughout.
- Color choices adhere to WCAG contrast guidelines (`WcagTheme`).
- Workflow state (idle / recording / processing) is communicated through both color and live-region semantics.

---

## 3. Architecture Overview

The application follows a layered architecture separating concerns across three tiers:

```
┌─────────────────────────────────────────────────────────┐
│                     Features Layer                      │
│  auth/  │  personalization/  │  live_asr/  │  shell/   │
├─────────────────────────────────────────────────────────┤
│                     Modules Layer                       │
│  network_sync/  │  speech_recording/  │  sound_playback/│
├─────────────────────────────────────────────────────────┤
│                      Core Layer                         │
│  constants/  │  routing/  │  user/  │  accessibility/  │
└─────────────────────────────────────────────────────────┘
```

- **Core** — App-wide constants (API URLs, endpoints, audio config), route definitions, local session/user storage, and WCAG theme/semantics utilities. This layer has no dependency on any feature.
- **Modules** — Platform capability abstractions (microphone recording via `record`, audio playback via `just_audio`, HTTP communication via `Dio`). Modules are stateless services injected into features.
- **Features** — User-facing screens with their own controllers, views, and models. Each feature depends only on modules and core, never on other features directly.

---

## 4. Logic Flow

### 4.1 Application Startup & Authentication

```
App launch
    │
    ▼
AuthGate.initState()
    │
    ├─ No saved token ──────────────────► AuthScreen (login / sign-up)
    │                                          │
    └─ Saved token                             │ on success
         │                                     │
         ▼                                     ▼
   GET /auth/me  ──── error ──────────► Clear session → AuthScreen
         │
         ▼
   GET /personalization/status
         │
         ▼
   AuthenticatedShell(initialStatus)
         │
         ├─ personalized=true
         │  asr_adapter_ready=true   ──► Free Speech tab active (index 0)
         │  aud_adapter_ready=true
         │
         └─ any flag false ────────────► Personalization tab active (index 1)
                                         Free Speech tab locked
```

The `AuthGate` widget validates the stored session on every cold start by calling `GET /auth/me`. A failure (expired token, network error) clears stored credentials and redirects the user to the authentication screen. On success, `GET /personalization/status` is called immediately to pre-load the user's personalization state before the shell is mounted, avoiding a loading flash on the main screen.

### 4.2 Voice Enrollment (Personalization)

```
PersonalizationController._init()
    │
    ├─ Load personalization_words.json (94 words)
    ├─ GET /personalization/status  →  update _status
    └─ Seek last locally-recorded phrase index → jump PageController

User records phrase N
    │
    ▼
SpeechRecordingService.start(path)          ← 16 kHz WAV, 256 kbps
    │  (user speaks)
SpeechRecordingService.stop()
    │
    ▼
File saved at:  <docs>/soutify_enrollment/<userId>__<phrase>.<idx>.wav
    │
    ▼
POST /personalization/enroll  (multipart)
    │  phrase_id, transcript, intent, category, file
    ▼
GET /personalization/status   →  update enrollment_count
    │
    ▼  (enrollment_count >= required_count)
"Start Personalization" button becomes visible
    │
    ▼
POST /personalization/finalize
    │
    ▼
GET /personalization/status in response body
    │
    ├─ personalized=true  ──────────────► Unlock Free Speech tab
    └─ personalized=false  ─────────────► Show error snackbar
```

Local WAV files serve as a persistent cache so that the user does not need to re-record if the application is closed mid-session. The controller restores progress by scanning the file system for previously recorded clips on initialization.

### 4.3 Free Speech (Live ASR)

```
User taps microphone button (idle → recording)
    │
    ▼
SpeechRecordingService.start(path: /tmp/soutify_live_<ts>.wav)
    │  (user speaks)
User taps microphone button again (recording → processing)
    │
    ▼
SpeechRecordingService.stop()
    │
    ▼
POST /inference/transcribe  (multipart WAV, include_tts=true)
    │
    ├─ response.text          ← corrected/personalized transcription
    ├─ response.raw_asr_text  ← raw ASR output (fallback)
    └─ response.tts.audio_base64  ← optional TTS audio (base64 WAV)
         │
         ▼
    ┌─ Display result via typewriter animation (processing → revealing)
    └─ Play TTS audio if present (SoundPlaybackService.playBase64)
         │
         ▼  (after 3-second display pause)
    Return to idle state
```

---

## 5. Backend API Reference

All requests are sent to the base URL resolved at build time. The default values are:

| Target | URL |
|---|---|
| Android Emulator | `http://10.0.2.2:8000` |
| Physical device / desktop | `http://127.0.0.1:8000` |
| Custom (build-time override) | `--dart-define=SOUTIFY_API_BASE_URL=http://<host>:8000` |

All endpoints except `signup` and `login` require an `Authorization: Bearer <token>` header.

---

### `POST /auth/signup`

Registers a new user account.

**Request body (JSON)**

| Field | Type | Description |
|---|---|---|
| `name` | `string` | Display name |
| `email` | `string` | User email address |
| `password` | `string` | Account password |

**Response**

| Field | Type | Description |
|---|---|---|
| `access_token` | `string` | JWT for subsequent requests |
| `user.id` | `string` | Unique user identifier |
| `user.name` | `string` | Display name |
| `user.email` | `string` | Email address |

---

### `POST /auth/login`

Authenticates an existing user.

**Request body (JSON)** — `email`, `password`

**Response** — same structure as `/auth/signup`.

---

### `GET /auth/me`

Validates the current token and returns the authenticated user's profile.

**Response** — same `user` object as above.

---

### `GET /personalization/status`

Returns the current personalization state for the authenticated user.

**Response (JSON)**

| Field | Type | Description |
|---|---|---|
| `personalized` | `bool` | Whether model adaptation has been completed |
| `asr_adapter_ready` | `bool` | Whether the ASR adapter is loaded and ready |
| `aud_adapter_ready` | `bool` | Whether the audio adapter is loaded and ready |
| `enrollment_count` | `int` | Number of clips uploaded so far |
| `required_count` | `int` | Minimum clips required to trigger personalization |
| `ready_for_personalization` | `bool` | Whether `enrollment_count >= required_count` |

> The Free Speech tab is unlocked only when `personalized`, `asr_adapter_ready`, and `aud_adapter_ready` are all `true`.

---

### `POST /personalization/enroll`

Uploads a single enrollment audio clip.

**Request** — `multipart/form-data`

| Field | Type | Description |
|---|---|---|
| `phrase_id` | `string` | Numeric ID of the enrollment word |
| `transcript` | `string` | Arabic text of the spoken word |
| `intent` | `string` | Semantic intent label (e.g. `animals`, `food`) |
| `category` | `string` | Arabic category name |
| `file` | `file` | 16 kHz WAV audio clip |

---

### `POST /personalization/finalize`

Triggers server-side model adaptation using all uploaded enrollment clips.

**Response (JSON)**

| Field | Type | Description |
|---|---|---|
| `status` | `object` | Updated personalization status (same schema as `GET /personalization/status`) |

---

### `POST /inference/transcribe`

Transcribes a WAV audio recording using the personalized model.

**Request** — `multipart/form-data`

| Field | Type | Description |
|---|---|---|
| `file` | `file` | WAV audio recording |
| `include_tts` | `string` | Set to `"true"` to request a TTS audio response |

**Response (JSON)**

| Field | Type | Description |
|---|---|---|
| `text` | `string` | Corrected/personalized transcription |
| `raw_asr_text` | `string` | Raw ASR output before post-processing |
| `tts.audio_base64` | `string?` | Base64-encoded WAV audio of the TTS response (present when `include_tts=true`) |

---

## 6. Project Structure

```
lib/
├── main.dart                      # Entry point
├── app.dart                       # Root MaterialApp widget
├── core/
│   ├── accessibility/
│   │   ├── wcag_theme.dart        # Brand colors, workflow state colors, Material theme
│   │   └── app_semantics.dart     # Semantic label helpers and tap-target enforcement
│   ├── constants/
│   │   ├── api_base_url.dart      # Platform-aware base URL resolution
│   │   ├── api_endpoints.dart     # All REST path constants
│   │   ├── audio_config.dart      # Sample rate and minimum enrollment count
│   │   └── app_assets.dart        # Bundled asset path constants
│   ├── routing/
│   │   └── app_router.dart        # Named route definitions and route generation
│   └── user/
│       ├── session_store.dart     # JWT and user profile persistence
│       └── user_id_store.dart     # Anonymous local UUID (legacy helper)
├── features/
│   ├── auth/
│   │   ├── auth_gate.dart         # Session validation and initial routing on startup
│   │   └── auth_screen.dart       # Login / sign-up form
│   ├── live_asr/
│   │   └── live_asr_screen.dart   # Free Speech recording and transcription screen
│   ├── personalization/
│   │   ├── personalization_screen.dart      # Screen wrapper
│   │   ├── personalization_controller.dart  # Recording, upload, and finalize logic
│   │   ├── personalization_view.dart        # Phrase carousel UI and controls
│   │   ├── phrase_view.dart                 # Single phrase card widget
│   │   ├── personalization_words_model.dart # Word data model and JSON loader
│   │   ├── personalization_filename.dart    # Local WAV file path construction
│   │   └── upload_status.dart               # Upload state enum
│   └── shell/
│       ├── authenticated_shell.dart  # Post-auth bottom-navigation shell with gating
│       └── home.dart                 # Legacy ungated two-tab scaffold
└── modules/
    ├── network_sync/
    │   ├── api_client.dart           # Dio HTTP client with auth interceptor
    │   ├── network_sync_manager.dart # High-level API facade
    │   ├── enrollment_clip.dart      # Clip metadata data class
    │   └── api_error_message.dart    # User-readable error formatting
    ├── sound_playback/
    │   └── sound_playback_service.dart  # File and base64 audio playback
    └── speech_recording/
        └── speech_recording_service.dart # Microphone recording service

assets/
├── images/
│   └── Soutify.PNG                         # Application logo
└── personalization/
    ├── personalization_words.json          # 94-word enrollment vocabulary
    └── images/                             # Illustrative images for each word
```

---

## 7. Dependencies

| Package | Version | Purpose |
|---|---|---|
| `record` | ^6.0.0 | Microphone audio capture (WAV, 16 kHz) |
| `just_audio` | ^0.10.0 | Audio file and base64 TTS playback |
| `dio` | ^5.7.0 | HTTP client with interceptors |
| `permission_handler` | ^12.0.0 | Runtime microphone permission management |
| `path_provider` | ^2.1.5 | Access to device document and temporary directories |
| `shared_preferences` | ^2.5.3 | Persistent local key-value storage for session data |
| `uuid` | ^4.5.1 | UUID generation for local user identification |
| `path` | ^1.9.1 | Cross-platform file path manipulation |

---

## 8. Running the Application

### Prerequisites

- Flutter SDK `>=3.8.0`
- A running instance of the Soutify backend server on port `8000`

### Android Emulator (default)

```bash
flutter run
```

The application will connect to `http://10.0.2.2:8000`, which maps to `localhost` on the host machine.

### Physical Device or Custom Backend

```bash
flutter run --dart-define=SOUTIFY_API_BASE_URL=http://<your-lan-ip>:8000
```

Replace `<your-lan-ip>` with the local network IP address of the machine running the backend server. The device and the server must be on the same network.
