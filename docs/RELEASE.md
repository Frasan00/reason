# Releasing reason

Push a tag, and GitHub Actions builds the release APK and publishes it as a GitHub Release.

```bash
git tag -a v1.0.1 -m "reason 1.0.1"
git push origin v1.0.1
```

The workflow is `/home/fra/projects/reason/.github/workflows/release.yml`. It runs the analyzer and
the tests, builds one universal APK, renames it `reason-<version>.apk`, writes a `.sha256` next to
it, and attaches both to the release. A tag with a suffix, like `v1.2.0-rc1`, publishes a
pre-release. The version name comes from the tag; the Android version code is
`major * 10000 + minor * 100 + patch`, so every release sorts above the one before it.

## Why the signing key matters more than the build

Android only installs an update over an installed app when both share the same signing key and the
same application id. If either changes, the phone refuses the update and the only way forward is an
uninstall, which deletes every clip and every setting: the chosen folder, segment length, budget,
car signals, language.

So the release must always be signed with the same key, and the key must live in the repository
secrets, never in a commit. The application id is `com.example.reason` in
`/home/fra/projects/reason/android/app/build.gradle.kts`; keep it unless a fresh install is
acceptable.

Without the secrets the workflow still builds, but with the debug key, and it prints a warning.
That APK cannot update a release built with the real key.

## One-time setup

Create the key once. Keep the file and its passwords somewhere safe: lose them and every future
release needs an uninstall.

```bash
keytool -genkeypair -v \
  -keystore ~/reason-release.jks \
  -alias reason \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass '<store password>' -keypass '<key password>' \
  -dname "CN=reason, O=reason, C=IT"
```

Then add four repository secrets (Settings → Secrets and variables → Actions):

| secret | value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/reason-release.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | the store password |
| `ANDROID_KEY_ALIAS` | `reason` |
| `ANDROID_KEY_PASSWORD` | the key password |

The workflow decodes the keystore into the runner's temp folder and writes
`android/key.properties` for Gradle. Nothing secret is committed; both `android/key.properties`
and `*.jks` are ignored by git.

## Building a signed release locally

Create `/home/fra/projects/reason/android/key.properties`, which Gradle reads first:

```properties
storeFile=/home/fra/reason-release.jks
storePassword=<store password>
keyAlias=reason
keyPassword=<key password>
```

`flutter build apk --release` then signs with the release key. Without that file, or the matching
environment variables, the build falls back to the debug key so local release builds still work.

## Supply chain pins

Nothing in the pipeline should be able to change under the project between two releases.

- Every action in the workflow is pinned to a full commit SHA, with the release it came from in a
  comment: `actions/checkout@11d5960… # v4.4.0`, `actions/setup-java@cf277c6… # v4.9.1`,
  `actions/cache@0057852… # v4.3.0`, `subosito/flutter-action@1a44944… # v2.23.0`,
  `softprops/action-gh-release@3bb1273… # v2.6.2`. A tag can be moved to different code; a commit
  cannot.
- The Gradle wrapper verifies the distribution zip against
  `distributionSha256Sum` in `android/gradle/wrapper/gradle-wrapper.properties`, so a modified
  Gradle download is rejected.
- `pubspec.lock` is committed and carries a `sha256` for every Dart package.
- The Flutter version is exact (`3.50.1`), and the runner image is `ubuntu-24.04` rather than
  `ubuntu-latest`.
- The APK is signed with a fixed key, and the application id never changes.

To bump an action, resolve the tag to its commit rather than trusting the tag:

```bash
git ls-remote https://github.com/actions/checkout refs/tags/v4.4.0
```

Still open: Gradle does not yet verify the checksum of every Maven artifact. Enabling that writes a
large `android/gradle/verification-metadata.xml` and makes each dependency update fail until the
file is regenerated:

```bash
cd android && ./gradlew --write-verification-metadata sha256 help
```

## Caches

`subosito/flutter-action` caches the Flutter SDK and the pub packages keyed by `pubspec.lock`.
A separate `actions/cache` step keeps `~/.gradle/caches` and `~/.gradle/wrapper` keyed by the Gradle
scripts. A release with no dependency change reuses both, so only the app sources are recompiled.
