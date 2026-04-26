# Project Plan & Status: Hybrid Social App (Feed + Audio Rooms)

This document outlines the implementation plan for our hybrid social application. We will merge the existing "GoSocial" features (posts, feed, profiles) with the new "Live Audio Rooms" features (rooms, gifts, coins).

---

### **Phase 1: Core Integration & Foundations**

*   [x] **Dependencies:** Add the Agora SDK (`agora_uikit`) and `lottie` to `pubspec.yaml`.
*   [x] **Navigation:** Redesign `main_layout.dart`'s `BottomNavigationBar` to include: "Feed", "Rooms", "Create" (+), "Chats", "Profile".
*   [x] **User Model:** Update the `User` model and Firestore `users` collection to add `coins`, `avatarIndex`, `role`, and `profileFrameUrl`.
*   [x] **Firestore Models:** Create new Dart model classes for `Room`, `Gift`, `GiftCategory`, `CoinPackage`, and `PaymentRequest`.
*   [x] **Custom Server API Design:** Define and document the required API endpoints for the custom server (e.g., `/upload/profile`, `/upload/gift`).

---

### **Phase 2: Profile & Authentication Enhancements**

*   [ ] **Phone Auth:** Integrate Firebase Phone Authentication into the login/signup flow.
*   [ ] **Profile UI Update:** Enhance `profile_screen.dart` to display the user's `coins`, a button for "My Room", and the selected avatar/profile frame.
*   [ ] **Profile Picture Upload:** Modify the profile picture logic to upload to the custom server instead of Firebase Storage.
*   [ ] **Avatar Selection:** Create a UI for users to select a local avatar from the app's assets.

---

### **Phase 3: Audio Room Management**

*   [ ] **Rooms List UI:** Create `rooms_screen.dart` to list active public audio rooms. This will be the view for the "Rooms" tab.
*   [ ] **Create/Delete Room:** Implement logic for a user to create/delete their single room in Firestore.
*   [ ] **Create Menu:** Update the central `Create` button to show a menu: "Create Post" (existing) and "Start My Room".

---

### **Phase 4: Core Agora Integration**

*   [ ] **Agora Service:** Create `agora_service.dart` to manage Agora App ID and token generation.
*   [ ] **Room Screen:** Create the main `room_screen.dart` UI.
*   [ ] **Join/Leave Channel:** Integrate Agora SDK in `room_screen.dart` to join/leave the audio channel.
*   [ ] **Seat UI:** Design the 10-seat UI grid within `room_screen.dart`.
*   [ ] **Basic Controls:** Implement mute/unmute self functionality.

---

### **Phase 5: In-Room Moderation & Interaction**

*   [ ] **Admin Controls:** Implement UI and Firestore logic for owners/mods to mute or kick users from seats.
*   [ ] **Seat Management:** Implement "request to speak" (raise hand) and "lock seat" features.
*   [ ] **Ban System:** Implement banning users from a room via Firestore.
*   [ ] **In-Room Chat:** Add a real-time text chat feature to `room_screen.dart`.

---

### **Phase 6: Gifts & Coins System**

*   [ ] **Gift Panel UI:** Create a bottom sheet in `room_screen.dart` to display gifts from Firestore.
*   [ ] **Send Gift Logic:** Deduct coins from the user's balance and trigger a gift-sent event.
*   [ ] **Gift Animation:** Use FCM to notify clients to display the gift animation (Lottie/GIF) and play its sound.
*   [ ] **Firestore Structure:** Implement the `gifts` and `giftCategories` collections.

---

### **Phase 7: Manual Payment System**

*   [x] **Coin Packages UI:** Create a screen to display available coin packages.
*   [x] **Payment Request Form:** Build a form for users to submit a manual payment request, including receipt image upload to the custom server.
*   [x] **Firestore Structure:** Implement the `paymentRequests` collection.

---

### **Phase 8: Private Chat (1-on-1)**

*   [x] **Chat List UI:** Create a screen that lists recent private conversations.
*   [x] **Chat Screen:** Build the 1-on-1 chat screen UI.
*   [x] **Messaging Logic:** Implement sending and receiving real-time messages using Firestore.

---

### **Phase 9: Admin Dashboard**

*   [ ] **Admin Role:** Implement role-based access control based on the `user.role` field.
*   [ ] **Dashboard UI:** Create a new set of screens accessible only to admins.
*   [ ] **Feature Management:** Build the UI and logic for admins to:
    *   Manage gifts and their categories.
    *   Manage coin packages.
    *   Approve/reject payment requests.
    *   Ban/unban users globally.
    *   Manage app settings (like Agora App ID) in a Firestore `config` document.