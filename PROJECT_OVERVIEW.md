# Jovial Music Player - Project Overview

Welcome to the **Jovial Music Player** project! This document provides a high-level overview of the project structure, architectural patterns, and file responsibilities to help you understand and navigate the codebase.

## 🏗️ Architectural Overview

The project follows a **Clean Architecture** pattern, which separates the application into layers to ensure independence, testability, and scalability.

-   **Presentation Layer**: UI components and state management.
-   **Domain Layer**: Business logic, entities, and repository interfaces.
-   **Data Layer**: Data sources, models, and repository implementations.
-   **Core Layer**: Global configurations, themes, and shared use cases.

---

## 📂 Project Skeleton (Detailed)

```text
lib/
├── common/
│   └── helper/
│       └── navigation/
├── core/
│   ├── configs/
│   │   ├── assets/
│   │   │   ├── app_images.dart        # Image asset constants
│   │   │   └── app_vectors.dart       # SVG/Vector asset constants
│   │   ├── theme/
│   │   │   ├── app_colors.dart        # Global color palette
│   │   │   └── app_theme.dart         # Material theme definitions
│   │   └── usecase/
│   │       ├── auth/
│   │       │   ├── signin.dart          # Sign-in business logic
│   │       │   ├── signup.dart          # Sign-up business logic
│   │       │   └── usecase.dart        # Base UseCase interface
│   │       └── admin_config.dart      # Admin-level configurations
│   └── service_locator.dart           # Dependency Injection (GetIt)
├── data/
│   └── models/
│       └── auth/
│           ├── create_user_req.dart   # Sign-up request model
│           ├── signin_user_req.dart   # Sign-in request model
│           ├── song_list.dart         # List of songs model
│           └── song_model.dart        # Core Song data model
├── domain/
│   ├── entities/
│   │   └── auth/
│   │       └── user.dart              # User business entity
│   ├── repository/
│   │   └── auth/
│   │       └── auth.dart              # Auth repository interface
│   └── sources/
│       └── auth/
│           ├── auth_firebase_service.dart # Firebase Auth calls
│           └── auth_repository_impl.dart  # Auth repo implementation
├── helpers/                            # Utility helper functions
├── presentation/
│   ├── pages/
│   │   ├── admin/
│   │   │   └── admin_dashboard.dart   # Admin controls
│   │   ├── auth/
│   │   │   ├── register_page.dart     # Registration UI
│   │   │   ├── signin_page.dart       # Login UI
│   │   │   └── signup_or_signin.dart  # Auth selection UI
│   │   ├── favorite/
│   │   │   └── favorite_page.dart     # User favorites UI
│   │   ├── home/
│   │   │   └── home_page.dart         # Main landing page
│   │   ├── intro/
│   │   │   └── get_started_page.dart  # Onboarding page
│   │   ├── music_player/
│   │   │   └── music_player_page.dart # Full-screen audio player
│   │   ├── offline/
│   │   │   └── offline_page.dart      # Downloaded music UI
│   │   ├── profile/
│   │   │   ├── profile_page.dart      # User profile UI
│   │   │   ├── settings_page.dart     # App settings
│   │   │   └── whats_new_page.dart    # Release notes
│   │   ├── search/
│   │   │   └── search_page.dart       # Music search UI
│   │   └── splash/
│   │       └── splash_page.dart       # Loading/branding screen
│   └── widgets/
│       └── mini_player.dart           # Global audio mini-player
├── services/
│   ├── audio_player_service.dart      # Main playback engine
│   ├── background_music_check.dart    # Android service checker
│   ├── cloudinary_music_service.dart  # Cloud storage connection
│   ├── favorites_service.dart         # Persistent favorites sync
│   ├── notification_service.dart      # Media control notifications
│   └── song_preferences_service.dart  # Local storage handling
├── firebase_options.dart              # Firebase configuration
└── main.dart                          # App entry point & initialization
```

---

## 📂 Detailed Layer Breakdown

### 1. `lib/core/`
This folder contains the foundation of the app.
-   `configs/`: Global configurations like assets, themes, and common use cases.
-   `theme/`: App-wide styles and colors.
-   `service_locator.dart`: Dependency injection setup (using `GetIt`) to manage object creation.

### 2. `lib/domain/`
The "brain" of the app. It defines *what* the app does, but not *how* it gets data.
-   `entities/`: Plain Dart objects representing core data (e.g., a `User` or `Song`).
-   `repository/`: Interfaces (abstract classes) that define how data should be fetched.
-   `usecase/`: Specific business actions (e.g., `SigninUseCase`, `GetSongsUseCase`).

### 3. `lib/data/`
Responsible for *how* data is retrieved.
-   `models/`: Data Transfer Objects (DTOs) that include JSON serialization logic (e.g., `UserModel`).
-   `repository/`: Concrete implementations of the interfaces defined in the Domain layer.
-   `sources/`: Direct calls to APIs, Firebase, or local databases.

### 4. `lib/presentation/`
Everything you see on the screen.
-   `pages/`: Full-screen widgets (e.g., `LoginPage`, `HomePage`, `NowPlayingPage`).
-   `widgets/`: Reusable UI components used across multiple pages.
-   **State Management**: Uses the **BLoC (Business Logic Component)** pattern to handle UI state transitions.

### 5. `lib/services/`
External service integrations.
-   Audio player services (JustAudio, AudioPlayers).
-   Firebase service integrations (Auth, Firestore).
-   Local storage and background tasks.

### 6. `lib/helpers/`
Utility functions and common helpers that are used throughout the project.

---

## 🛠️ Tech Stack & Key Packages

-   **Framework**: [Flutter](https://flutter.dev/)
-   **State Management**: `flutter_bloc`, `provider`
-   **Audio Playback**: `just_audio`, `audioplayers`
-   **Backend**: `firebase_core`, `firebase_auth`, `cloud_firestore`
-   **Dependency Injection**: `get_it`
-   **Functional Programming**: `dartz` (used for handling errors/successes using `Either`)
-   **UI Utils**: `flutter_svg`, `lottie`, `audio_video_progress_bar`

---

## 🚀 Common Workflows

-   **Want to change the UI?** Look into `lib/presentation/pages/`.
-   **Want to modify how a song is fetched?** Look into `lib/data/sources/` or `lib/data/repository/`.
-   **Want to add a new feature?** Define an entity in `domain/entities/`, a repository interface in `domain/repository/`, and then implement it in the `data/` layer.

---

## 📁 Root Directory Files
-   `pubspec.yaml`: Project dependencies and asset definitions.
-   `firebase_options.dart`: Firebase configuration for different platforms.
-   `main.dart`: The entry point of the Flutter application.
