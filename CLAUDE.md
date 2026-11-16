# Udhaar (package: udhaar / com.itsash.udhaar)

Offline personal lending ledger: who owes you, whom you owe. Pure Flutter, no native code.

## Data

- `lib/src/store.dart` `LedgerStore` (ChangeNotifier) keeps everything as one JSON string in
  SharedPreferences key `udhaar_ledger_v1`: `people`, `txns`, `myName`, `myVpa`, `nextId`.
- Amounts are integer **paise**. A `Txn` has `gave` (true: they owe you more) and a positive amount.
  Balance = sum(gave) - sum(got): positive = you'll get, negative = you owe (`balanceOf` in `models.dart`).
- Settle up adds the opposite entry ("Settled up") and clears due dates / reminders for that person.
- Ids (people, txns) come from one counter. The txn id is the notification id.

## Features and where they live

- Due-date reminders: `lib/src/reminders.dart` (`flutter_local_notifications`, inexact alarms, 9:00 on the
  due day, no exact-alarm permission). Rescheduled on every app start. Boot receivers are in the manifest.
- Reminder message + UPI link: `lib/src/upi.dart` (`buildUpiLink`, `reminderMessage`). The message uses the
  user's own VPA/name (Settings). The Pay button builds a link with the *person's* VPA.
- CSV export: `lib/src/csv.dart`, shared as a file with `share_plus`.
- WhatsApp: share sheet, plus a `wa.me` link when the person has a phone number (10 digits get `91`).

## Code layout

- `lib/screens/`: `home_screen.dart`, `person_screen.dart`, `person_sheet.dart`, `txn_sheet.dart`,
  `settings_screen.dart` (your name + UPI ID, then `UiAppearanceSection`, `UiUpdateSection(storeId: 'udhaar')`,
  `UiDeveloperSection`).
- Tests: `test/udhaar_test.dart` (balance math, money parsing, UPI link, CSV).

## Commands

- `make run`, `make build`, `make test` (analyze + tests), `make clean`.
- Icon: `assets/icon/*.svg` → `*-1024.png`, then `dart run flutter_launcher_icons`.

## Conventions

- minSdk 26 (core library desugaring is on for the notification plugin). UI only from `../theme`.
- Permissions: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `INTERNET` (update check only).
- No analytics. Nothing leaves the phone except what the user shares.

## Release (Ash Store)

- `store.json` (id `udhaar`, repo its-ash/udhaar), `store.mk`, `index.html` + `CNAME` (`udhaar.itsash.in`).
  See `../ash-store/store-kit/STORE.md`.
- `make deploy` = bump version → build → commit, tag, push → GitHub release with `udhaar.apk`.
- Do not edit `store.mk` here. Edit `../ash-store/store-kit/store.mk`, then run `make store-sync` at the workspace root.
