# reason

A dash cam for a spare Android phone. Mount the phone, open the app, tap record, put the screen out.

Recording runs in a foreground service, so it keeps going with the screen off and the app in the
background. Footage is written in short MP4 segments, and the oldest one is deleted once the storage
budget is reached, so the phone keeps the last hours of the drive and nothing else.

- Loop recording from 480p to 1440p, one file per segment, grouped by year, month and day.
- Crash lock: a hard jolt marks the clip being written as protected, so the loop skips it until you
  clear the protection in the library.
- Storage: a budget in GB, plus "destroy after", from one hour to 365 days. Recording stops with a
  warning when the phone drops below 500 MB free.
- Car start: recording begins on its own when a Bluetooth car device connects, when the phone
  charges and moves, or when Google reports a vehicle. Each signal can be switched off.
- Clips can live in a folder you pick, not only in app storage.
- Library: play, share, delete, clear protection.
- English, Italiano, Français, Español, Deutsch.

## Install

Download the APK from the Releases page and open it. Android 7 or newer.

Allow the camera and notifications. Allowing the battery exemption is what keeps the recorder alive
with the screen off on phones that kill background services.

The app asks for no microphone and no location permission. It records video only.

## Build

Flutter 3.50.1 and JDK 21.

```bash
flutter pub get
flutter test
flutter build apk --release
```

Signed releases are built by GitHub Actions when a `v*` tag is pushed. The steps, and how the
signing key is kept, are in [docs/RELEASE.md](docs/RELEASE.md).

## Limits

There is no audio. No GPS, speed or timestamp is burned into the frame. iOS is not supported: keeping
the camera alive with the screen off needs an Android foreground service. Some phones run hot after
an hour of 1080p recording.

## License

MIT, see [LICENSE](LICENSE).
