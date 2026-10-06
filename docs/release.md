# Releasing Octo

## Identity

| | |
| --- | --- |
| Android package / iOS bundle id | `dev.october.octo` (reverse of `octo.october.dev`) |
| App name | Octo |
| Release key | `~/.config/octo-release/octo-release.jks`, alias `octo`, RSA 4096, valid to 2054 (outside the repo) |
| Key fingerprint (SHA-256) | `F6:8B:48:A7:90:A2:3E:8A:FE:E4:CB:12:F1:74:C3:06:BB:B6:DC:D1:A9:C0:CF:DD:D7:4E:13:19:DB:82:9B:7F` |

**Back up the key and its passwords** (`~/.config/octo-release/key.properties`) somewhere safe, such as a
password manager. Use it as the **upload key** with Google Play App Signing: Google then holds the
real signing key, and a lost upload key can be reset.

## Build

`android/key.properties` (gitignored; here a link to `~/.config/octo-release/key.properties`) or the
file named by `OCTO_KEY_PROPERTIES` gives Gradle the key. Without one, release builds use the debug
key and can't be published.

```sh
tool/build_release.sh appbundle config/real.json   # Play Store (.aab)
tool/build_release.sh apk config/real.json         # sideloading (.apk)
```

The script refuses anything but real mode first.

## Links on octo.october.dev

For `https://octo.october.dev/...` links to open the app:

- **Android:** serve `docs/well-known/assetlinks.json` at
  `https://octo.october.dev/.well-known/assetlinks.json`. With Play App Signing, add Google's
  app-signing fingerprint (Play Console → App integrity) next to this one.
- **iOS:** serve an `apple-app-site-association` file there once the Apple team id is known.

## Notifications (no Firebase)

`OCTO_PUSH=on` in the build config turns them on.

- **Android: UnifiedPush with ntfy.** The phone needs the free ntfy app (Google Play or F-Droid)
  as its distributor; the app explains this when someone allows notifications without it, and
  registers by itself once ntfy is installed. It registers `{endpoint, p256dh, auth}` with
  October (`platform: unifiedpush`), and the backend sends each push as Web Push encrypted for
  the phone, so ntfy only relays ciphertext. Backend: saturday migration 056 and
  `OCTO_UNIFIEDPUSH_HOSTS` (default `ntfy.sh`; add a self-hosted ntfy such as `ntfy.october.dev`).
- **iOS: APNs directly.** Needs, from the Apple Developer account: the App ID `dev.october.octo`
  with Push Notifications, and an APNs key (.p8) for the backend (`OCTO_APNS_KEY`,
  `OCTO_APNS_KEY_ID`, `OCTO_APNS_TEAM_ID`, `OCTO_APNS_TOPIC=dev.october.octo`). The app's
  entitlement (`ios/Runner/Runner.entitlements`) is in place.
