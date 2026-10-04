# Octo family app

The family member's side of Octo: a Flutter app (iOS and Android) that feels
like Messages, with one Octo per family computer. Brief:
<https://claude.ai/artifact/LpMU5bSmeLoX8RiUSwzs12>. Implementation plan:
[PLAN.md](PLAN.md).

## Run

```sh
flutter pub get
flutter run --dart-define-from-file=config/fake.json   # the simulator
```

Without a config the app shows "This build isn't configured"; it never falls
back to fake mode on its own, and release builds refuse fake mode.

In fake mode the bug button opens the debug panel, which plays Mom: say OK or
no, send a to-do, ask for help, approve rules, take the computer offline,
remove you, or have another helper (Priya) ask Octo something. "Mom answers OK
by herself" is on by default.

## Develop

```sh
dart run build_runner build   # after changing freezed / json models
flutter analyze
flutter test
```

Generated code (`*.freezed.dart`, `*.g.dart`, `lib/l10n/app_localizations*.dart`)
is committed; CI checks it is current.

## Release

Real config lives in an untracked file shaped like `config/example.json`.

```sh
tool/build_release.sh appbundle config/release.json
```

The script runs `tool/check_release_config.dart` first, which fails unless the
file sets `OCTO_MODE=real` with valid settings.

## Layout

| Folder | What's there |
|---|---|
| `lib/protocol` | §7.2 messages: models, parsing, request/reply matching |
| `lib/transport` | `OctoLink`, the simulator and its debug panel (`RelayLink` in stage 5) |
| `lib/data` | sessions (reducer, reconciliation), outbox, thread projection, drift database, screenshot store, fake backend and enrollment |
| `lib/app` | config, providers, router |
| `lib/features` | Octos list, thread, add an Octo |
| `lib/ui` | theme, tokens, bubbles, Octo looks |

## Emulator

```sh
flutter emulators --launch octo_pixel
flutter run --dart-define-from-file=config/fake.json
flutter test integration_test --dart-define-from-file=config/fake.json   # on the emulator
```
