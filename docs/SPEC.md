# reason: a phone that works as a dash cam

Status: spec for v1. Nothing is built yet; the repo holds the bare Flutter template.

## What it is

An Android app that turns a spare phone into a dash cam. You mount the phone, open the app, press
record, and put the screen out. It records continuously in short segments, keeps the most recent
footage within a storage budget, protects the clip around an impact, and lets you watch or share
any clip afterwards.

## Hard constraints

These are platform facts, not choices. They shape the feature list below.

- **Recording with the screen off needs an Android foreground service** with
  `foregroundServiceType="camera"`. iOS cannot do this at all, which is why iOS is out of v1.
- **A camera foreground service cannot be started from the background.** Android 14 blocks
  starting it from `BOOT_COMPLETED` or a charging broadcast. So there is no auto-start when the car
  powers on: the app has to be opened and recording started by hand. Anything that reads
  "auto-start on ignition" is out.
- **The camera owns the device.** While recording, nothing else in the app may open the camera or
  the recording ends.
- **Battery and heat.** Continuous 1080p recording on a phone runs hot. The device must stay
  charging during a drive and long recordings may throttle on warm days.
- **OEM services lie.** Some manufacturers kill foreground services under battery optimization. The
  app should offer a one-tap battery-optimization exemption when it detects a stopped service.

## v1 features

### F1: Loop recording

- One primary control starts and stops recording. No other screen is needed to record.
- Live preview while idle and while recording.
- Output is H.264 MP4, one file per segment, written to the app's own external files directory.
- Segments rotate at a configurable length. Consecutive segments must be contiguous: no more than
  one second of missing footage at each boundary.
- Each segment is named by its start time so the library sort needs no database.
- When total clip size would exceed the storage budget, the oldest **unprotected** segment is
  deleted. Protected segments are skipped.
- Recording stops with a visible warning when free device space drops under 500 MB, rather than
  filling the phone.
- Recording continues with the screen off and with the app backgrounded.
- While recording, the preview carries a small overlay: a recording dot, elapsed time, and storage
  used against the budget.

Acceptance: with the screen off and the phone charging, two hours of continuous recording produce
segments within 5% of the nominal length, no boundary gap over one second, and no crash.

### F2: Crash lock

- The accelerometer runs while recording. A single sample above the impact threshold marks the
  segment being written as protected.
- At most one lock per 60 second window, so a rumble strip does not protect the whole drive.
- Protection is a sibling marker file next to the segment, not a database row, so a crash that
  kills the app leaves the protection intact.
- Protected segments are never deleted by the loop and are badged in the library; the badge can be
  cleared from the library.
- Sensitivity ships as three presets in settings (low, normal, high). No free-form threshold.

Acceptance: a drop from 30 cm onto a desk while recording produces exactly one protected segment;
the same clip deleted by the loop never loses a protected segment.

### F3: Clip library and share

- Segments listed newest first: start time, duration, size, protected badge.
- Tap a row to play it in-app; a share action opens the OS share sheet; a delete action removes the
  file and its marker.
- The segment currently being recorded cannot be deleted or shared.
- Sharing exports through a FileProvider URI, never a raw file path.

Acceptance: a clip can go from library to the share sheet to another app and play there; deleting
the last unprotected clip under budget pressure keeps the list consistent.

### Settings

| setting | default | values |
| --- | --- | --- |
| resolution | 1080p | 720p, 1080p |
| segment length | 3 min | 1, 3, 5 min |
| storage budget | 2 GB | 1, 2, 5 GB |
| camera | rear | rear, front |
| crash sensitivity | normal | low, normal, high |

Resolution values above what the device reports are hidden rather than failing on start.

## Out of v1, deliberately

- **iOS.** The folder exists from `flutter create` but nothing is targeted or tested there.
- **Audio.** No microphone permission, no jurisdiction question. A toggle could come later.
- **GPS, speed and timestamp burn-in.** Needs location permission and a compositor over the
  preview; the first thing to add after v1.
- **Parking mode, motion detection while parked.**
- **Cloud upload, dual camera, photo mode, driver assistance.**

## Sketch of the pieces

- Camera and encoder through the `camera` plugin, preview into a Flutter widget.
- **The open engineering risk is screen-off recording.** The `camera` plugin keeps a session alive
  only while the Flutter engine is foregrounded. Try plugin + foreground service first; if the
  session dies when the screen turns off, the fallback is a small native Kotlin service running
  CameraX and `MediaRecorder`, driven from Dart over a platform channel. Settle this before the
  library UI exists, because it decides where the file writes happen.
- Accelerometer through `sensors_plus`; playback through `video_player`; sharing through
  `share_plus`; paths through `path_provider`.
- No database in v1. Filenames carry the start time, durations come from the media metadata, and
  protection is a marker file.

## Permissions

`CAMERA`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_CAMERA`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, and
the battery-optimization exemption prompt. Nothing else: no microphone, no location, no broad
storage access.

## Open questions

1. Does the `camera` plugin survive the screen going off on the target phone, or is the native
   CameraX service required from the start?
2. Is "open the app and press record each drive" acceptable, given that auto-start is blocked?
3. Where do clips live: the app-private external directory (gone on uninstall) or the shared
   Movies directory through MediaStore (visible to gallery, needs more care)?
4. Should the phone be mounted portrait or landscape, and does the app lock orientation or follow
   the sensor?
5. How long must a single drive be supported before a soak test counts as passing: two hours is the
   assumption above.

## Milestones

1. **Record.** Preview, start/stop, segments, budget-driven deletion, settings for resolution and
   segment length. Runs with the screen on.
2. **Survive.** Foreground service, screen off, battery-optimization prompt, the soak test.
3. **Protect and review.** Crash lock, library, playback, share, delete.
