# Octo family app — agreed implementation plan

Agreed by Apollo and Atlas after five review rounds (v5, 2026-10-04). Source brief: https://claude.ai/artifact/LpMU5bSmeLoX8RiUSwzs12


---

## 1. Approach

Greenfield Flutter app (`octo-family/` holds only `.codex/` and `.gitignore`). One Flutter package, built in brief §13 order. Every stage ends runnable end-to-end against `SimulatorLink` + fakes. The core is pure Dart and UI-free: wire parsing, the session reducer, reconciliation, the thread projection and the outbox state machine, all unit-tested. Widgets only render state.

- **Precondition:** Flutter is not installed on this machine; install Flutter stable and the Android SDK. iOS builds run only in CI (macOS runner).
- **Read-only references:**
  - `october-desktop/mobile/src/october/{pairing,relay,client,vault,hosts,supabase,relayClosePolicy,requestSlots,push,secrets}.ts` and their tests, which are the full phone client;
  - `october-desktop/src/shared/remote*.ts` and `remoteChannel.vectors.ts`;
  - `october-lantern/engine/src/mobile/*` (the responder).
- **No repo implements the family protocol.** `SimulatorLink` is an executable interpretation of the brief, not protocol authority. Server guarantees the brief doesn't state are listed as contract questions (§6) and resolved at the real-integration boundary. None of them blocks stages 1–3.
- **Mascot:** the only art is a 120×101 PNG from the artifact, used as a placeholder until the hi-res PNG/SVG arrives.

## 2. Files / components

```
pubspec.yaml, analysis_options.yaml (flutter_lints), config/example.json, .github/workflows/ci.yml
lib/app/        main.dart, config.dart, router.dart, providers.dart
lib/protocol/   models/*.dart, host_message.dart, app_message.dart, pending.dart
lib/transport/  octo_link.dart, simulator/{simulated_computer,simulator_link,debug_panel}.dart, relay/** (stage 5)
lib/data/       db/*.dart, session/{reducer,reconcile,computer_session,sessions_controller}.dart,
                thread/projection.dart, outbox.dart, screenshot_store.dart,
                enrollment/{enrollment_repository,fake_enrollment,http_enrollment}.dart,
                backend/{octo_backend,fake_backend,http_backend}.dart, auth/*.dart, push/*.dart, account_scope.dart
lib/features/   welcome/, octos_list/, add_octo/, thread/, details/, settings/
lib/ui/         theme.dart, tokens.dart, bubble.dart, octo_avatar.dart, octo_looks.dart, states/*.dart
ios/            Runner (+ 6-line method channel: exclude-from-backup), NotificationService extension (stage 4)
android/        allowBackup=false, data-extraction rules
test/, integration_test/, test/goldens/
```

Packages:
- **State and navigation:** `flutter_riverpod` 3 (plain Notifiers, no generator), `go_router`.
- **Models and storage:** `freezed`/`json_serializable`, `drift`, `path_provider`, `uuid`, `http`.
- **Sign-in and devices:** `supabase_flutter`, `mobile_scanner`, `flutter_secure_storage`, `local_auth`.
- **Notifications:** `firebase_messaging`, `flutter_local_notifications`.
- **UI:** `flutter_slidable`, `share_plus`.
- **Crypto (stage 5):** `cryptography` and `cryptography_flutter`.
- **Dev:** `build_runner`, `drift_dev`, `fake_async`, `integration_test`.

## 3. Specific changes

### 3.1 Protocol (`lib/protocol`)
- **Models:** freezed + json_serializable for Task, Step, Todo, Reply, TodoContext, Entry, Policy, Status (with jobs, family, help, agent), Job and FamilyMember. Task, Todo, Entry, Status and Policy also keep `raw`.
- **Open-ended values stay strings.** `Task.status`, `Task.may`, `Policy.never` and `blockedSites` keep their original wire strings and round-trip byte-for-byte on edit.
  - Derived getters map them to known values: a `TaskPhase` getter covers the known statuses plus `unknown`.
  - An unknown `may` or `never` value shows as "Something else".
  - An unknown status shows as "Octo sent an update this app can't show yet. Update the app." It never reads as done or failed.
- **Parsing.** `parseHostMessage(Map raw)` switches on `type` and calls the generated `fromJson` for that type.
  - An unknown type, or a malformed message of a known type, becomes `UnknownHostMessage(raw)`. It is ignored and logged without content, and the stream never dies.
- **Screenshots on the wire.** Every screenshot-bearing field decodes to `WireScreenshot.data(bytes)` (a `data:image/*;base64,` string) or `WireScreenshot.hostPath(s)`.
  - A host path is shown as "Screenshot on her computer" and never opened as a phone file.
  - Limits: 8 MB of base64 and 4096 px per side.
- **Outgoing messages:** `AppMessage` with a typed `toJson` per brief type.
- **Request matching (`pending.dart`).** The matcher expects a typed reply per request kind: `result`, `status`, `todos` or `log`, keyed by `requestId`.
  - There is one matcher per connection, which is the epoch.
  - The timeout starts when the request is actually sent: 20 s normally, and longer for pairing.
  - On disconnect, every outstanding request fails as `disconnected`.
  - A late `result` (after its timeout or disconnect) is not dropped. It is passed on as a reconciliation event.

### 3.2 Transport (`lib/transport`)
- **`OctoLink`** is the brief's interface, verbatim.
- **`PairingProgress`** is a sealed type:
  - `scanned(computerName)`;
  - `compareCode(code, Future<void> Function(bool match) confirm)`: `confirm(true)` sends `pair.confirm`, and `confirm(false)` aborts the pairing;
  - `waitingForHer`;
  - `paired(computer)`;
  - `failed(reason, isFinal)`.
  Cancelling the stream subscription cancels the handshake.
- **`SimulatedComputer`** plays Mom's computer, driven by an injectable clock:
  - pairing, a queue of up to 10 tasks, waitingOk → running with timed steps → each end status;
  - refusals by policy, and hard limits ("password" → blocked);
  - to-dos, help, and screen shares with a sample image;
  - looser rules waiting for her approval, and `removed`.
- **`DebugPanel`** has the controls: Mom says OK, Mom says no, sends a to-do, asks for help, approves the rules, and computer offline/online.
- **Simulator gating:** `SimulatorLink` and the debug panel exist only in fake mode (§3.9), behind a developer toggle.

### 3.3 Session and reconciliation (`lib/data/session`)
- **`SessionsController`** is app-level and created once.
  - On `resumed` it connects every paired computer; on `paused` it disconnects them.
  - It disposes a session when its computer is removed or the account changes.
  - It runs independently of mounted widgets, so list previews stay live.
  - Provider `build` methods only read state and never cause side effects.
- **Connect sequence:** subscribe to `messages` → send `status`, `todos` and `log` and await the replies → drain the outbox. This runs once per connection, so repeated `connected` emissions don't overlap.
- **Reducer:** `SessionState reduce(SessionState, Event)` is pure. Events are host messages, request outcomes and local actions.
- **Reconciliation:**
  - **Live events** (`task`, `todo`, `help`, `policy`, `screen`) apply in received order. A `task` message fully replaces the stored version of that task.
  - **Snapshots** (the `status` reply, the `todos` reply) are applied differently. A refresh records `refreshSeq` when it is sent. An entity changed by a live event after `refreshSeq` is not overwritten by that snapshot.
  - For tasks only, a snapshot never turns a finished status back into an unfinished one. This is an extra guard and doesn't claim to fix every stale snapshot.
  - The same source-aware rule covers todos (`todos` reply vs `todo` events), help (`status.help` vs `help` events) and policy (`status.policy` vs `policy` events).
- **Screenshots never reorder the reducer.** A message applies at once with a pending screenshot reference, and the file write completes later.

### 3.4 Local persistence (`lib/data/db`)
- **One drift database file per account,** at `ApplicationSupport/<userId>/octo.sqlite`.
  - On iOS the whole `ApplicationSupport/<userId>/` directory is excluded from backup with `NSURLIsExcludedFromBackupKey`, set through a 6-line method channel before the database opens. That covers the SQLite WAL, journal and SHM sidecar files too. Android sets `allowBackup=false`.
  - Rationale: the outbox is operational state. If a backup brought back a "pending" task that has since been sent, restoring would send it twice. Thread history rebuilds from her computer, so excluding the whole file is the simplest correct choice.
- **Tables:**
  - `computers`: the backend list, look, pinned, muted, order, `lastReadAt`, role, the `hostId`/`bind` mapping and `myHelperId`;
  - `records`: the projection's inputs as raw JSON with screenshot bytes stripped, plus a stable id, kind, `at` and an insert sequence;
  - `outbox`;
  - `screenshots`: id, `expiresAt`, state;
  - `sync`: the log cursor and the "possibly incomplete" flag.
- **Stable ids:**
  - tasks and todos use the host id;
  - entries, help and screens use `sha256` of the canonical JSON array `[computerId, kind, at, by, text, taskId]`, an unambiguous encoding;
  - my sent messages use a local UUID.
  Upserts are idempotent and history is never deleted by a bounded `status.recent`.
- **Order** is `(at, insertSeq)`.
- **Log paging:**
  - `since` is the largest stored `at`. Whether `since` is inclusive is a host contract question.
  - Results are deduplicated by stable id, and the next page is requested only while `entries.length == limit`.
  - **No-progress guard:** if a full page brings no new ids, paging stops and Activity says "Older activity may be missing". The cursor never moves past entries that weren't received.
  - The cursor is written in the same transaction as the rows.
- **Read state:** `lastReadAt` is set to the time of the first sync, so a fresh install doesn't show history as unread.

### 3.5 Outbox (`lib/data/outbox.dart`)
- **States:** `pending → attempting → accepted | rejected | uncertain`.
  - `attempting` is written, together with the `requestId`, the exact payload, the local bubble id and the `bind`, in one transaction **before** `link.send`.
  - Draining after reconnect sends only `pending` rows.
  - At startup, any `attempting` row becomes `uncertain`.
- **Uncertain copy:** "Couldn't confirm it reached Mom's computer. Check the activity before trying again." Try again creates a new task, with a note that it may run twice.
- **Late results** set the `taskId` or the error at any time.
- **Fire-and-forget messages** (`message`, `todo.reply`, `todo.done`, `leave`) become `sent` once `send()` completes, or `uncertain` otherwise. The app never claims "delivered".
- **`profile.set`** is never stored as a value to replay. Each computer persists two counters:
  - `profileGen`, incremented and persisted **before** each `PATCH`, so a crash right after the `PATCH` succeeds still leaves the sync owed;
  - `profileSyncedGen`, the newest generation confirmed on her computer.
  A single-flight sync loop per computer serialises PATCH, fetch and send:
  1. Wait for any in-flight `PATCH` to settle, then capture `g = profileGen`.
  2. Re-read the backend's current profile (`GET /computers`).
  3. Send `profile.set` (it carries a `requestId`) built from that canonical value.
  4. Set `profileSyncedGen = g` only on a correlated `result ok:true`.
  - A timeout, disconnect or rejection leaves the sync owed, retried on the next connect.
  - If `profileGen > g` when the loop finishes (an edit landed during the sync), the loop runs again.
  - So a stale local value never overwrites another helper's newer write, and an older sync can never clear a newer edit. Ordering between helpers who write at once is contract question 10.
- **Re-pairing:** outbox rows are bound to (account, computerId, bind). When a computer is re-paired with a new bind, older rows are dropped, never drained.

### 3.6 Screenshot store
- **Location:** `getApplicationCacheDirectory()/<userId>/screenshots/`, which the OS excludes from backup.
- **Writes:** async and ordered per computer, written atomically (temp file, then rename).
- **Expiry:** `expiresAt` is the event's `at` (or the first receipt) plus 7 days, and stays stable across duplicate delivery.
  - A screenshot from history that has already expired is never written.
  - Expiry gates showing and sharing, deletes the file and any temporary share copy, and evicts the decoded image from memory.
  - Files are purged at startup and on resume.
- **Stated guarantee:** never shown after expiry, and deleted the first time the app runs after expiry.
- **Placeholders:** "Screenshot no longer available" when the file is expired or missing.
- **Display:** `Image.file` with `ResizeImage`.

### 3.7 Thread projection (`lib/data/thread/projection.dart`)
- **Input and output:** `projectThread(SessionData, MeIdentity)` returns `List<ThreadItem>` and is pure.
- **Keys**:
  - `task:<id>:request` for the request bubble. While an optimistic outbox row exists, the request bubble keeps the outbox's local id as its key even after the `taskId` is known, so no duplicate row appears and the bubble doesn't remount.
  - `task:<id>:octo` for the live bubble, which becomes the result and keeps the same key.
  - `todo:<id>`, `screen:<hash>`, `help:<hash>`, `msg:<uuid>`, and `sys:<hash>` for system lines.
- **What appears in the thread:**
  - tasks;
  - to-dos, with the "Reply" and "Octo, do it" actions;
  - help, from direct events and `status.help`;
  - screens, from direct events;
  - my messages;
  - system lines from log entries of kind `pairing` and `policy`;
  - messages from other helpers.
  Log entries of kind `task`, `step`, `consent`, `limit`, `todo`, `help` and `screen` appear only in Activity, never as thread items, which avoids duplicates. A log `message` entry from me is skipped when it matches a local message record by text, with `at` within 2 minutes.
- **Screens:**
  - A request shows as the grey line "Asked Mom to show her screen".
  - Each incoming `screen` is its own item: an image, or "Mom said no to showing her screen".
  - A screen is never presented as the definite answer to a particular request; the correlation is a contract question.
- **"Me":**
  - The preferred source is an explicit helper id from the pairing or status contract (contract question).
  - The fallback learns it from `result.taskId` → `task.from` and persists it.
  - When ownership is unknown, the bubble is rendered conservatively on the left with its name ("Harsh → Octo: …").
- **Grouping, tails and timestamp separators** are computed here.

### 3.8 Features
- **Octos list:**
  - a large title, pull-to-search, and Edit (reorder, pin, remove);
  - `flutter_slidable` swipes: left for Mute and Remove, right for read/unread;
  - live preview lines ("Working… step 2", waiting, offline) and the pulse on the avatar;
  - ordering: pinned first, then help requests, then latest activity;
  - empty, loading and offline states;
  - a row "Pair again on this phone" for backend computers with no local keys (after a restore or a new phone).
- **Thread:**
  - a header with status that opens Details;
  - bubbles with tails and grouping, and spring slide-in (off under reduced motion);
  - the live bubble updates in place, with Stop;
  - long-press for Copy, Try again, Stop and Details (the timeline);
  - an image viewer with pinch-to-zoom and share;
  - the composer:
    - the Ask Octo / Tell Mom toggle, which sets the placeholder and the bubble colour;
    - the + tray of seven jobs (send now or prefill);
    - the one-line `may` hint;
    - the 2,000-character limit;
    - the offline line, the clock on pending bubbles, and the uncertain state;
  - Reply on one of Mom's bubbles → Tell Mom + `todo.reply`.
- **Add an Octo:**
  - The scanner and "Type the code instead" (8 characters).
  - Universal links are validated: `https`, `www.october.dev` or `october.dev`, `/octo/add`, and a `<enrollId>.<secret>` fragment.
  - The secret is held only in memory: never logged or persisted, carried through sign-in in router state.
  - `EnrollmentRepository.resolve` → `Enrollment{mode: owner|helper, computerId, relay: RelayBootstrap}`. The fake returns an explicit mode, and the real one waits for the documented response. No invented error codes, and the enrollment secret is not reused as the relay token.
  - Then the `pair()` sheets: scanned (haptic) → compare code → waiting (bobbing Octo) → outcomes (said no / expired / too many tries / offline, each with one button) → name and language chips, plus the computer name → pick one of six looks → the thread with the welcome message.
  - Setup persists through `PATCH` + `profile.set` (§3.8 Details) and the local database.
  - The app never retries a claim automatically.
  - **Binding phases:** each secure-storage binding records a phase:
    - `started`: keys created, no credential yet;
    - `finalizing`: persisted when `pairCredential` arrives, **before** `pairAck` is sent;
    - `complete`: once paired.
    - At startup, only `started` bindings that aren't part of an active pairing, and attempts confirmed cancelled or rejected, are deleted.
    - `finalizing` bindings are kept and reconciled like `complete` ones: connect with the credential, and check the backend list.
    - A missing database row is not proof of an orphan. A `complete` binding with no row is reconciled against the authenticated backend list. If the computer is still listed, its row is recreated with no re-pairing needed (this covers sign-out, a lost database, or a crash between saving the credential and the database commit). It is deleted only when the authenticated backend list succeeds and doesn't include it.
  - The notification permission is asked the first time an Octo is added.
- **Details:**
  - **The Octo:** Change Octo (`PATCH {octo}`) and Rename.
  - **Profile ownership:** the backend owns the person's name, the computer name, the language and the look. `PATCH` runs first; if it fails, the app shows `message` and changes nothing. On success, her computer is synced through the `profileDirty` flow (§3.5), and the line reads "Mom's computer will update when it's back" while pending.
  - **Rules:**
    - The switches show only `active`, the policy the host last reported.
    - An edit sends the full proposed policy in one `policy.set`. Each changed item's state comes from the diff:
      - tightened items (a boolean turned on, a `never` value or site added) read "Applying change" until a host `policy`/`status.policy` reports them, and only then read "On";
      - loosened items (a boolean turned off, a value removed) read "Waiting for Mom to approve" until the host reports them.
    - An `ok` result means only that the request was accepted. The label changes only when the policy itself arrives.
    - Nothing is applied optimistically, and only one edit is in flight per computer.
    - An error or timeout reverts to `active` and shows `message`. `policy{declined:true}` shows the line "Mom kept the old rule".
  - **Activity:** the paged log, grouped by day, with a filter by kind.
  - **Helpers:** from `status.family`.
  - **This month:** from `usage`.
  - **Mute.**
  - **Remove** depends on role:
    - ** Owner, "Remove for everyone"** (it explains the other helpers lose it too):
      1. `DELETE` first. On failure, the app shows `message` and nothing changes; the Octo stays fully usable.
      2. On success, the computer becomes a hidden tombstone.
      3. `leave` is sent best-effort, then unpair and purge.
    - ** Helper, "Remove from my phone":** the computer becomes a hidden tombstone at once, then `leave` → unpair → purge.
    - **Tombstone:** hidden from the list, with the session, the credentials and the pending `leave` kept until `unpair` (the relay revocation) **completes successfully**. A `leave` that is merely `sent` or `uncertain` is not proof of removal. A small cleanup job retries on each connect.
    - Only after `unpair` succeeds are the keys deleted and the data and screenshots purged.
    - Signing out with tombstones still pending warns, just like a non-empty outbox.
    - An incoming `removed` takes the computer off the list, deletes its data, and shows a one-time banner: "Mom's computer removed you".
- **Settings:** account, appearance, app lock (`local_auth` on resume, after 1 minute in the background), notifications per kind, about, and the developer toggle (fake mode only).
- **Looks:** exactly six presets: `orange`, `ocean-glasses`, `lavender-sunhat`, `mint-headphones`, `rose-bow` and `sunshine-scarf`.
  - Rendering: the base PNG, hue-rotated with `ColorFilter.matrix`, plus an accessory drawn with `CustomPainter`; readable at 40 dp.
  - Animations: a bob, a wiggle, and sleepy (desaturated, with closed eyelids).

### 3.9 Modes, config and accounts
- **Mode:** `--dart-define=OCTO_MODE=fake|real`, with config from `--dart-define-from-file`. `config/example.json` is committed and real config files are gitignored.
- **fake:** `FakeAuth`, `FakeBackend`, `FakeEnrollment` and `SimulatorLink`; Firebase is never initialised.
  - Allowed in debug and profile builds. Profile is an intentional, test-only deviation from the brief's literal "debug builds only", so performance can be measured; profile builds never ship.
  - ** Release protection:**
    - **Build time:** a preflight script and a CI step fail any release build whose `OCTO_MODE` isn't `real`.
    - **Runtime:** a `kReleaseMode` guard shows the "This build isn't configured" screen if fake mode is ever reached in a release build.
- **real:** the config is validated at startup. If it's missing or invalid, the app shows a clear "This build isn't configured" screen. It never falls back to fake silently.
- **Account isolation:**
  - each account has its own database, screenshot folder and secure-storage namespace (keys per user and bind, as in the reference vault, set to `first_unlock_this_device`);
  - sign-out runs in this order: unregister push while the credentials are still valid → stop sessions → delete that account's database, outbox and screenshots, warning first if the outbox or tombstones aren't empty. `complete` and `finalizing` relay bindings stay, namespaced to the user. Signing back in recreates the rows from the backend list (§3.8 binding phases);
  - switching accounts disposes every session first.
- **Restored phone or new phone:** the database isn't in backups and the keys don't move to a new device, so the app starts empty. Computers come from the backend and show "Pair again on this phone" unless a `complete` binding for them still exists on this device.

### 3.10 Sign-in, backend, push (stage 4)
- **Supabase sign-in:** magic link, Apple and Google, with the deep-link callback.
- **`HttpBackend`:** Bearer token. `{error:{code,message}}` becomes a `BackendException`, and `plan_required` and `credit_exhausted` link to the plan page on october.dev.
- **`HttpEnrollment`** is built once its contract is documented.
- **Push registration:** register on sign-in and token refresh, and unregister before sign-out.
- **iOS:**
  - The backend sends an alert with generic, content-free copy ("Mom needs a hand", "Mom sent you something"), `mutable-content:1` and the data `{computerId, kind, taskId?}`.
  - A Notification Service Extension adds the communication style and the Octo avatar from an App Group cache (computerId → name and look image). It never fetches content.
  - In the foreground, the app sets `setForegroundNotificationPresentationOptions(alert:false)` and shows an in-app banner instead.
- **Android:**
  - A data-only, high-priority message, shown by the background handler as a `flutter_local_notifications` MessagingStyle conversation notification, on one channel per kind.
  - In the foreground, an in-app banner. This avoids the duplicate display FCM plus a local notification would cause.
- **Taps:** `getInitialMessage`, `onMessageOpenedApp` and taps on local notifications all go through one handler: auth check → app lock → `/octo/:id`, or the list if the computer is unknown or removed.
- **Mute:**
  - A local mute covers Android display and the in-app banners.
  - iOS muting needs a server-side flag (contract question).
- **Native setup:** the Firebase config files, the NSE target and the App Group are added in this stage.

### 3.11 RelayLink (stage 5)
- **Pairing,** ported from the mobile client:
  1. the QR → `mobile-pair-consume` (safe to retry; the server replays it for this device's keys);
  2. verify `hostId` and `hostStatic`;
  3. store the X25519 static key and the separate Ed25519 signing key, per user and bind;
  4. connect to the relay at `/v1/device/{hostId}/{bind}`;
  5. the Noise handshake, with the 6-digit code derived locally from the handshake hash (the host's `pair.code` is only cross-checked);
  6. `pairOffer` → `pairCredential` → `pairAck` → `pairActive`.
- **Reconnect:** backoff while the app is in the foreground, and close codes per `relayClosePolicy.ts` (4403 alone never purges a pairing).
- **Family JSON over the relay:** it rides inner frames only once the host documents that bridge.
- **Noise module (`relay/noise/`):** Noise_XX_25519_ChaChaPoly_BLAKE2b, implemented to the spec over `cryptography`. No Dart package fits: `sodium` 4.1.1 has only the original ChaCha20-Poly1305 construction, not the IETF one, and `noise_protocol_framework` has no BLAKE2b.
  - Cipher: IETF ChaCha20-Poly1305, with the nonce = 4 zero bytes followed by LE64(n).
  - **AAD:** `h` during the handshake; empty for transport messages.
  - Hash: BLAKE2b-512, and HKDF over HMAC-BLAKE2b with a 128-byte block.
- **Acceptance gate before `RelayLink` is enabled:**
  - the committed reference vector, using the reference's seed → key semantics;
  - bidirectional multi-message exchanges;
  - tamper, reorder, truncation, invalid key, wrong prologue and wrong pin;
  - the 2^31 message cap;
  - fresh ephemerals on every reconnect, and fail-closed decryption;
  - the exact Ed25519 signed-body bytes and timestamps;
  - frame size limits, the chunk timeout, backpressure, and reconnect credentials.
  These mirror `remoteChannel.test.ts` and `relay.test.ts`.
- **Then** a full end-to-end test with a real Octo computer.

## 4. Must remain unchanged
- The sibling repos are reference only and are never modified.
- The `OctoLink` signature, verbatim.
- The §7.2 field names, message types and status labels.
- The §12 out-of-scope items: live screen viewing, sending a to-do to the helper's own agent ("Coming soon"), web or desktop, and in-app payments.
- No analytics or crash SDK in v1, and push payloads carry no content.

## 5. Tests and checks
- **Unit tests:**
  - every §7.2 example, plus unknown types, fields and enum strings (round-trip), and a malformed known message;
  - the matcher: typed replies, timeout from dispatch, late results surfaced, disconnect;
  - the reducer and reconciliation:
    - a live event after `refreshSeq` beats the snapshot;
    - a terminal event B (with the result) after a terminal event A replaces it;
    - the snapshot terminal guard;
    - todos, help and policy follow the same source-aware rules;
  - the projection: keys, dedup, me and unknown ownership, screens not tied to a request, grouping;
  - the outbox: a crash in `attempting` becomes `uncertain`; a late result; re-pair drops old rows;
  - log paging with the no-progress guard;
  - the screenshot store: expiry, expired history, limits, and a host path never opened;
  - a policy edit that tightens and loosens at once ("Applying change" until reported);
  - profile sync: a crash after the `PATCH`; another helper's newer value on the backend wins; a lost or timed-out `profile.set` result keeps the sync owed; an edit made during a sync triggers a re-run and isn't cleared by the older sync;
  - binding reconciliation: `started` deleted; a crash after `pairCredential` is persisted, and after `pairAck` or `pairActive`, leaves a `finalizing` binding that is kept and reconciled; `complete` is kept and its row recreated from the backend;
  - removal: owner `DELETE` failure leaves the Octo usable; a helper tombstone survives offline and restart until `unpair` succeeds;
  - account-switch isolation;
  - backend error mapping;
  - the fake enrollment;
  - the Noise gate (stage 5).
- **Widget tests:**
  - every screen in each state: empty, loading, offline, running, waitingOk, and each end status;
  - the unknown status;
  - text scale 3.0;
  - the accessibility guidelines (tap target, labelled tap target, text contrast).
- **Golden tests:**
  - the Octos list, a thread with every bubble kind, and the add-an-Octo sheets, in light and dark;
  - tagged `golden`, with the Flutter version, fonts (Roboto bundled), locale and viewport pinned;
  - baselines are reviewed and committed; CI compares them on Linux and never regenerates them.
- **Integration test** (`integration_test/`): pair → task → her OK → steps → result, against `SimulatorLink`, in CI on an Android emulator.
- **CI:** the Flutter version pinned; the release-mode preflight; analyze, test, goldens, `build apk --debug`, `build ios --no-codesign` (compile-only), and the emulator integration job.
- **Device checks once credentials arrive:** APNs and the NSE, universal links, biometrics, and signed builds.
- **Performance:** a profile build in fake mode, with `traceAction`. Two measurements: cold start to the list (target under 2 s on a mid-range Android phone), and frame times while 50 steps stream in. Reported in each stage report rather than gated in CI.
- **Copy lint:** a test that checks authored UI strings (the ARB file) for "user", "device", "endpoint" and error codes. It doesn't cover names, host text or logs.

## 6. Edge cases, risks and contract questions
- **Edge cases covered above:** an ambiguous send, a late result, a stale snapshot, re-pairing, a restore, an account switch, screenshot expiry, a mixed policy edit, two helpers acting at once, an unknown status, a malformed message, a full queue (`busy` shows its `message`), the app dying mid-pairing (scan again; orphaned keys are cleaned up).
- **Host and backend contract questions** (flagged in stage reports; none block stages 1–3):
  1. The enrollment response: owner or helper mode, the relay bootstrap data, whether claim is idempotent, and the computerId ↔ hostId/bind mapping.
  2. The QR format: the brief's `www.october.dev/octo/add#<enrollId>.<secret>` vs the existing `october.dev/pair#<base64url JSON>`.
  3. How family JSON maps onto inner relay frames, and whether the host honours `requestId` idempotency.
  4. The screenshot wire encoding.
  5. Whether a `screen` message correlates with a request, and whether screens are broadcast to every helper.
  6. An explicit helper id, so the app knows which tasks are mine.
  7. `log` paging: whether `since` is inclusive, the ordering, and tie-breaking, or a cursor.
  8. The push payload (an iOS alert with mutable-content, Android data-only) and a server-side per-computer mute.
  9. The hi-res mascot art and the six looks, and the Supabase, OAuth and Firebase config.
  10. Ordering when several helpers write the profile or policy at once: the backend's versioning or last-write semantics.

## 7. Why this is minimal, safe and maintainable
- **Minimal:**
  - It's one package with the brief's layers.
  - Libraries replace custom work wherever one fits:
    - `drift` for the database;
    - `flutter_slidable` for swipe actions;
    - `flutter_local_notifications` for notification display;
    - `cryptography` for the crypto primitives.
  - Custom code is limited to three things:
    - the chat UI, which the brief requires;
    - the small screenshot store, because screenshots are bytes, not URLs;
    - the Noise state machine, because no compatible package exists. It is gated behind vectors and adversarial tests.
- **Safe:**
  - Honest delivery states.
  - Source-aware reconciliation, without inventing wire revisions.
  - Screenshots normalised to local references before anything is stored.
  - Backup-excluded operational state.
  - Per-account isolation.
  - The pairing code derived locally.
  - A release build can never run fake.
- **Maintainable:**
  - A pure core: reducer, projection and outbox.
  - The transport behind the brief's `OctoLink`.
  - Every unresolved server guarantee isolated behind a repository or contract question, so the real integration replaces the fakes without UI changes.
