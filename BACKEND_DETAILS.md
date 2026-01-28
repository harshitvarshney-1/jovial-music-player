# Jovial Music Player - Backend Documentation

This document explains the backend technologies used in this project, their purposes, and how they interact with the Flutter application.

## 🛠️ Current Backend Technologies

The project currently uses **Backend-as-a-Service (BaaS)** providers to handle data, authentication, and media storage.

### 1. Firebase (Google)
Firebase is the primary backend provider for this application.

*   **Firebase Authentication**: 
    *   **Purpose**: Handles user registration and login.
    *   **Implementation**: Found in `lib/domain/sources/auth/auth_firebase_service.dart`.
    *   **Features**: Supports Email/Password authentication.
*   **Cloud Firestore**:
    *   **Purpose**: A NoSQL database used to store:
        *   User profiles.
        *   Favorite songs list.
        *   Song metadata (titles, artists, URLs).
    *   **Implementation**: Used in `FavoritesService`, `HomePage`, and `SearchPage`.

### 2. Cloudinary
Cloudinary is used as the specialized media backend.

*   **Purpose**: Storing, managing, and delivering high-quality audio files.
*   **Implementation**: Found in `lib/services/cloudinary_music_service.dart`.
*   **Why Cloudinary?**:
    *   Faster streaming speeds via CDN.
    *   Easy management of audio assets.
    *   Automatic metadata extraction (duration, format).

---

## 📂 Proposed Backend Skeleton (Custom Node.js)

If you decide to move away from BaaS and build your own custom backend (e.g., using Node.js and Express), here is the recommended folder structure and its purpose:

```text
backend/
├── src/
│   ├── controllers/      # Logic for handling requests (e.g., userController, songController)
│   ├── models/           # Database schemas (e.g., User model, Song model)
│   ├── routes/           # API terminal routes (e.g., /api/auth, /api/songs)
│   ├── middlewares/      # Functions that run before controllers (e.g., auth check, error handling)
│   ├── services/         # Reusable business logic (e.g., music streaming service, email service)
│   ├── utils/            # Helper functions (e.g., validators, logger)
│   ├── config/           # Database connection and environment configs
│   └── index.js          # Entry point of the server
├── tests/                # Automated tests
├── .env                  # Environment variables (API keys, DB URLs)
├── package.json          # Node.js dependencies
└── vercel.json           # Deployment configuration (for Vercel)
```

### Purpose of each folder:
*   **Controllers**: Decides what to do with the incoming data from the app.
*   **Models**: Defines how a "User" or "Song" looks in your database.
*   **Routes**: Maps URLs to specific logic (e.g., `GET /songs` calls `songController.getSongs`).
*   **Middlewares**: Protects your routes (e.g., "only logged-in users can like a song").
*   **Services**: Handles heavy lifting like talking to Cloudinary or sending notifications.

---

## 🔄 Data Flow Summary

1.  **Auth Flow**: Flutter App → Firebase Auth → Successful Login.
2.  **Music Flow**: Flutter App → Cloudinary API (via `CloudinaryMusicService`) → Audio Stream URL → `JustAudio` (Player).
3.  **Favorites Flow**: Flutter App → Cloudinary/Firestore → Get/Update User Data.
