# KametiBook

KametiBook is a Flutter mobile app for managing local committee / VC / kameti systems. It helps organizers and members manage kameti groups, members, monthly payments, receiver allocation, bidding, lucky draws, ledger records, reports, and reminders.

Tagline: **Har kameti ka complete hisaab.**

## Features

- Splash screen and onboarding
- Signup, login, forgot password, and profile screens
- Home dashboard with kameti, payment, bidding, draw, receiver, ledger, and notification summaries
- Bottom navigation for Home, My Kametis, Notifications, and Profile
- Create kameti form with validation, PKR formatting, and total pool calculation
- Supported kameti types:
  - Owner First
  - Lucky Draw / Khulli Chhutti
  - Bidding / Auction
  - Fixed Order
  - Mutual Decision
- My Kametis list with member counts, current cycle status, payment progress, receiver status, and payout status
- Kameti details screen with members, payments, receiver allocation, ledger, reports, alerts, and settings sections
- Member management:
  - Add, edit, remove, search, and filter members
  - Organizer auto-added
  - Organizer, co-organizer, and member role support
  - Member account linking fields for cloud/multi-user flow
- Monthly payment tracking:
  - Payment cycles
  - Member payment records
  - Mark paid, pending, late, rejected, and pending approval
  - Member payment proof submission
  - Organizer proof approval flow
  - Payment methods and mock/local proof path support
- Lucky Draw / Khulli Chhutti:
  - Eligible/excluded member lists
  - Random winner selection
  - Locked draw result
  - Draw history and winner details
- Bidding / Auction:
  - Bidding sessions
  - Bid submission, update, and withdrawal
  - Lowest bid winner
  - Discount/saving calculation
  - Discount adjustment records
  - Bidding history
- Receiver allocation:
  - Common receiver allocation model
  - Owner First receiver confirmation
  - Fixed Order setup and confirmation
  - Mutual Decision/manual receiver selection
  - Lucky Draw and Bidding linked to receiver allocation
- Ledger and financial history:
  - Contribution entries
  - Payout entries
  - Discount and penalty entries
  - Manual ledger entries
  - Group ledger
  - Cycle and member financial summaries
  - Ledger sync for existing data
- Reports:
  - Reports dashboard
  - Monthly cycle report
  - Full kameti report
  - Member statement
  - Payment report
  - Payout / receiver report
  - Ledger report
  - Bidding report
  - Lucky draw report
  - PDF export
  - Share sheet support
  - Report history
- Notifications and reminders:
  - In-app notification center
  - Unread badge
  - Kameti alerts
  - Reminder settings
  - Notification preferences
  - Payment due and overdue alerts
  - Payout, receiver, lucky draw, bidding, report, and ledger notifications
- Cloud-ready multi-user foundation:
  - Firebase package integration
  - Guarded Firebase initialization
  - Repository abstractions for auth, users, kametis, members, payments, receiver allocation, bidding, draw, ledger, reports, notifications, and storage
  - Invite member flow with shareable invite code
  - Join kameti by invite code
  - Firebase Storage service for payment proof, payout proof, and profile photos
  - FCM token preparation
  - Firestore and Storage security rules

## Tech Stack

- Flutter
- Dart
- Material 3
- Riverpod
- Firebase-ready architecture:
  - Firebase Core
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Messaging
- PDF generation and sharing:
  - `pdf`
  - `printing`
  - `share_plus`
- Image selection:
  - `image_picker`

## Project Structure

```text
lib/
  main.dart
  app/
    app.dart
    routes.dart
    theme.dart
  core/
    constants/
    services/
    utils/
    widgets/
  features/
    auth/
    bidding/
    cloud/
    home/
    kameti/
    ledger/
    lucky_draw/
    member/
    notifications/
    onboarding/
    payment/
    profile/
    receiver/
    reports/
```

## Firebase Setup

The app includes Firebase packages and a Firebase-ready repository layer. A real Firebase project still needs to be connected before cloud sync, Firebase Auth, Firestore, Storage, and FCM can run against live services.

Required Firebase project files:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Security rules are included:

- `firestore.rules`
- `storage.rules`

Until Firebase config files are added, the guarded Firebase bootstrap allows the app to continue running in local/demo mode.

## Run

Install Flutter, then run:

```sh
flutter pub get
flutter run
```

If platform folders are missing in a fresh checkout, run:

```sh
flutter create .
flutter pub get
flutter run
```

## Verify

```sh
flutter analyze
flutter test
```

## Notes

- PKR is used as the default currency.
- CNIC is treated as sensitive information and should not be shown in reports or shared content by default.
- KametiBook is a record-keeping and coordination tool, not a bank, financial institution, or legal authority.
