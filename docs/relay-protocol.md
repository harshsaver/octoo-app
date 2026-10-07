# Octo family messages over October's relay

How the family app (`lib/transport/relay/`) talks to a family computer. For
whoever builds the Octo side on the desktop. Everything below the "family"
layer is October Desktop's existing phone-access protocol, unchanged; this
app is a port of `october-desktop/mobile/src/october/{pairing,relay}.ts`,
checked against `src/shared/remoteChannel.vectors.ts` byte for byte.

## Layers

| Layer | What | Source of truth |
| --- | --- | --- |
| Control plane | `mobile-pair-consume`, `mobile-relay-ticket` (`ticket-device`), `mobile-device-revoke` (`device-self-revoke`), signed with the phone's Ed25519 key | `supabase/functions/mobile-*` |
| Socket | `wss://relay.afteroctober.xyz/v1/device/{hostId}/{bind}`, subprotocol `october-ticket.<ticket>`; ACK `[0x04][u32]` after every message | `infra/relay/src/relay-object.ts` |
| Noise | `Noise_XX_25519_ChaChaPoly_BLAKE2b`, prologue `october-remote/1 ‖ hostId ‖ bind ‖ connectionId`, host key pinned | `src/shared/remoteChannel.ts` |
| Frames | 16-byte header, chunks of ≤ 65,503 bytes | `src/shared/remoteFrames.ts` |
| Family | the brief's §7.2 JSON messages, below | this document |

## Pairing

The phone scans October Desktop's own pairing QR,
`https://october.dev/pair#<base64url({v:2, hostId, hostStatic, intentId, secret, exp})>`,
and runs October's flow: consume → relay → Noise → **both screens show the
same six digits** → the helper confirms they match (`pairOffer`) → she
approves on her computer → `pairCredential` → `pairAck` → `pairActive`.

The family protocol's `pair.request` / `pair.code` / `pair.confirm` /
`pair.done` are not used over the relay: October's pairing already does
that job, end to end encrypted. The phone keeps the credential and its keys
in the Keychain / encrypted storage.

The phone's computer id for such a pairing is `rly_<hostId without dashes>`
(there's no Octo backend record yet; see `RelayAwareBackend`).

## After pairing

Each connection: ticket → socket → Noise → the phone sends `auth` (the
credential, UTF-8), then an **`octo.hello`** request (below), then `sub`:

```json
{"cursor": null, "topics": ["octo.family"], "terminals": []}
```

### Phone → computer: `req`

Every family message is one `req` frame holding a `CoreRequestEnvelope`:

```json
{
  "apiVersion": 2,
  "requestId": "<uuid>",
  "deadlineAt": 1790000000000,
  "principal": {"kind": "remote", "id": "<bind>"},
  "method": "octo.message",
  "payload": {"type": "task.create", "requestId": "…", "text": "…"}
}
```

The computer answers each with a `res` frame (same message id),
`[status u16][serverTimeMs u64][JSON]`, the JSON being October's
`CoreResponseEnvelope`: `{"apiVersion": 2, "requestId", "ok": true, "result": {}}`
or `{"ok": false, "error": {"code", "message"}}`. **Success is a 2xx status
and `"ok": true`** (October's core answers most errors with status 200 and
`"ok": false`). Success only means "received"; the family reply (`result`,
`status`, …) comes separately as an event.

### `octo.hello`

The first request on every connection, sent before `sub`:

```json
{"method": "octo.hello", "payload": {"app": "octo-family", "protocol": 1}}
```

An Octo computer answers `{"ok": true, "result": {"octo": 1, "computer": "Mom's laptop", "person": "Mom", "helperId": "<id>"}}`.
`helperId` is what `task.from` will say for tasks this phone sends (the test Octo uses the binding
id); the app uses it to know which tasks are its own instead of guessing.
Anything else means the computer is October Desktop without Octo (its core
answers `"ok": false`, and ends the session when the phone subscribes to
`octo.family`). The phone then says "Not running Octo" and stops retrying.
The phone also checks this right after pairing, so October Desktop's own
pairing code can't be used to add an Octo by mistake. The phone treats no `res` within 20 s as "maybe sent" (the outbox's
*uncertain*), and a send while disconnected as "not sent".

`principal.id` is overwritten by the host with the binding id, as October
does; the computer can use the binding id as the helper's id.

### Computer → phone: `ev`

Every family message is one line in an `ev` frame, a `CoreEventEnvelope`
on topic `octo.family`:

```json
{"apiVersion": 2, "cursor": 17, "topic": "octo.family", "entityId": "<bind>",
 "generation": 1, "createdAt": "2026-10-05T10:00:00Z",
 "payload": {"type": "status", "requestId": "…", "status": {…}}}
```

Several lines may share one frame (newline-separated). The phone ignores
other topics.

### Sizes and pacing

A screenshot rides inside one family message, so `req` and `ev` may be up
to **9 MiB** here (October's core caps them at 1 MiB; the assembler buffer
is 16 MiB to match). Frames above 65,503 bytes are chunked as usual.

The relay drops a phone that has more than **1 MiB unacknowledged**
(close 4429), and the host can't see the phone's ACKs. The computer must
pace large sends: the test Octo uses a token bucket of 256 KiB burst at
1 MiB/s, which stays under the limit for round trips up to ~700 ms.

### Leaving and removal

- The helper removes the computer: the phone sends `{"type": "leave"}`,
  then revokes its own binding (`device-self-revoke`) and forgets its keys.
- She removes the helper: the computer sends `{"type": "removed"}`, then
  closes the session with **4403** and revokes the binding
  (`device-revoke`). The phone stops reconnecting on 4403, 4401 and 4409.

## What's still open for the Octo team

1. Whether Octo uses October Desktop's pairing (as here) or its own QR with
   an Octo backend claim (`/octo/add#en_…`). The app supports both: the
   claim path still expects `pair.*` messages from a computer that speaks
   them.
2. Whether `octo.message` / `octo.family` should be core methods/topics
   inside October Desktop, or a separate Octo host process with its own
   `hostId`.
3. A larger ceiling for `req`/`ev` in October's core, or screenshots sent in
   pieces.
