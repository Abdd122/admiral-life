# PROJECT MAP: Hybrid Social & Live Audio Rooms App

## 1. Project Overview
This project is a high-featured hybrid social application that combines a traditional social media feed (Instagram style) with real-time live audio chat rooms (Clubhouse/Bigo style). The app focuses on community engagement through content sharing, live voice interaction, and a robust gamified monetization system.

## 2. Tech Stack
*   **Frontend**: Flutter (Dart)
*   **Backend/Database**: Firebase (Authentication, Firestore, Cloud Functions, FCM)
*   **Real-Time Audio**: Agora RTC (Audio-only SDK)
*   **Storage/Media Backend**: Custom VPS running a Go File Server (for images, animations, and receipts).
*   **Language (Backend Logic)**: Node.js (Firebase Functions).

## 3. Current Infrastructure Status
*   **Custom File Server (Go)**: Operational at `http://188.40.225.17:3000`. Handles multipart uploads for profile pictures, post images, and payment receipts.
*   **Firebase Cloud Functions**: Token generation logic is ready in `functions/index.js`. 
    *   **Function**: `generateAgoraToken`
    *   **Status**: Awaiting `firebase deploy`.
*   **Agora RTC**: Integration complete in `AgoraService`.
    *   **App ID**: `49b0b00483ea4bd98e4e889bb8f67452`
    *   **App Certificate**: `955d775e2e344d0ca24e0192c455bd3f` (Configured in cloud functions).

## 4. Completed Features

### **Authentication**
*   Email/Password Registration and Login.
*   Phone Authentication using `Pinput` for OTP verification.
*   Persistent session management via `AuthWrapper`.

### **User Profiles**
*   **Numeric IDs**: Every user is assigned a unique 6-digit numeric ID upon creation.
*   **Level/XP System**: Users earn XP (Experience Points) through gifting and interaction, increasing their Level.
*   **Edit Profile**: Functionality to update Name, Bio, and Profile Image (uploaded to VPS).
*   **Profile Frames**: Logical structure ready to support animated profile frames.

### **Social Feed**
*   **Content Creation**: Users can create posts with text and images.
*   **Infinite Scrolling**: Efficient feed loading using pagination.
*   **Engagement**: Double-tap to like with heart animation, and a sub-collection based commenting system.

### **Live Audio Rooms**
*   **Lobby**: Visual list of active public rooms.
*   **Management**: Users can create one unique room, join/leave channels.
*   **Moderation**: Owner/Moderator tools (Ban, Unban, Mute logic).
*   **Hand Raise**: Real-time system for listeners to request speaking privileges.
*   **Active Speaker**: Visual indicator (glowing border) for the user currently talking.

### **Gifts & Stickers**
*   **Categorized Gifts**: Managed via categories (e.g., Popular, Luxury) fetched from Firestore.
*   **Quantity Selection**: Long-press on a gift allows sending multiples (e.g., x10, x100).
*   **Recipients**: Support for sending to a single user or "All Speakers".
*   **Formats**: Support for GIF, MP4 (Video), and SVG formats.
*   **Stickers**: Bottom sheet panel for sending free stickers in chats/rooms.

### **Communication & Monetization**
*   **Private Messaging**: 1-on-1 real-time chat with a dedicated Chat List screen.
*   **Coin Shop**: Interface to view coin packages.
*   **Payments**: Manual payment request system. Users upload receipts (to VPS) for admin approval.
*   **Admin Tools**: Screen to manage available Payment Methods (account numbers/instructions).

## 5. Pending / In-Progress Features
*   **Admin Dashboard Finalization**: Completing the `AdminPaymentMethodsScreen` and linking it to the user-side payment request form.
*   **Resource Management**: Implementing `AdminFramesScreen` (for profile frames) and `SeatSoundsScreen` (for entry sound effects).
*   **Token Integration**: Connecting the Flutter `AgoraService` to the deployed Firebase Cloud Function for dynamic token retrieval.
*   **UI/UX Refinement**: Adding more sound effects using `audioplayers` and polishing gift animations.

## 6. Directory Structure
*   `lib/models/`: Dart classes for data structures (`Room`, `User`, `Gift`, `Comment`, `PaymentMethod`).
*   `lib/services/`: Core logic and Firebase/API interfaces (`AuthService`, `PostService`, `AgoraService`, `GiftService`).
*   `lib/screens/`: All full-screen UI components (Feed, Profile, Chat, VoiceRoom, Admin panels).
*   `lib/widgets/`: Reusable UI components (`PostCard`, `ParticipantAvatar`, `AuthWrapper`).
*   `functions/`: Node.js code for Firebase Cloud Functions (Agora token generator).
*   `main.go`: Entry point for the Go-based file server (VPS side).

---
**Status**: Ready for final Admin UI completion and Cloud deployment.