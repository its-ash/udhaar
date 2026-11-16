# Udhaar

Keep track of who owes you and whom you owe. Send a polite UPI reminder in one tap.

**[Website](https://udhaar.itsash.in)** · **[Download APK](https://github.com/its-ash/udhaar/releases/latest/download/udhaar.apk)** · Get it in **[Ash Store](https://store.itsash.in)**

## Features

- **People and balances**: each person's net balance (you'll get / you owe, in ₹) and the totals on the home screen.
- **Entries**: note what you gave or got with an amount, a note and a date. Edit or delete any entry.
- **Settle up**: one tap records the entry that brings a balance to zero.
- **Due-date reminders**: pick a due date and get a notification at 9:00 that day.
- **Polite reminder message**: share it through WhatsApp or any app. It includes a `upi://pay` link with your own UPI ID, name and the amount (set them in Settings).
- **Pay**: when you owe someone whose UPI ID you saved, open your UPI app with the amount filled in.
- **Export CSV** of all entries.
- **Private**: no account, everything stays on your phone. The only network call is the update check in Settings.

## Install

- **Ash Store**: install [Ash Store](https://store.itsash.in) once, then install and update Udhaar from it.
- **APK**: download the [latest APK](https://github.com/its-ash/udhaar/releases/latest/download/udhaar.apk) on your phone and open it. Allow your browser to install unknown apps if Android asks.

Requires Android 8.0 (API 26) or later. Allow notifications when Android asks to get due-date reminders.

## Develop

Needs Flutter ≥ 3.44 and the shared theme package at `../theme`.

```bash
make run      # run on a connected device
make test     # flutter analyze + flutter test
make build    # release APK
make deploy   # bump version, build, tag, push, GitHub release (see store.mk)
```

## Release

`make deploy` follows the Ash Store kit (`store.mk`, `store.json`): it bumps the
version in `pubspec.yaml`, builds, commits, tags `vX.Y.Z`, pushes, and publishes
a GitHub release with `udhaar.apk`. Ash Store and the website pick up the new
version from that release.

## Project layout

```
lib/
├── main.dart                   # UiApp, notification setup
├── src/
│   ├── models.dart             # Person, Txn, balance math, money parse/format
│   ├── upi.dart                # upi:// link and reminder message
│   ├── csv.dart                # CSV export
│   ├── store.dart              # LedgerStore (SharedPreferences JSON)
│   ├── reminders.dart          # due-date local notifications
│   └── format.dart             # dates
└── screens/
    ├── home_screen.dart        # totals, people list, export, Settings icon
    ├── person_screen.dart      # balance, entries, remind, pay, settle up
    ├── person_sheet.dart       # add / edit person
    ├── txn_sheet.dart          # add / edit entry
    └── settings_screen.dart    # your name + UPI ID, appearance, updates, developer
test/udhaar_test.dart           # balance math, UPI link, CSV
```

See `CLAUDE.md` for details.

## License

No license file is included yet.

Built by [itsash.in](https://itsash.in).
