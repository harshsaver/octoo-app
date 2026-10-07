# Test Octo

A stand-in for the Octo desktop app, for trying the family app for real:
real October sign-in, real pairing, October's real relay, end-to-end
encryption. "Mom" is you, at the terminal: you approve what Octo does.

Tasks are **done for real on this laptop** by October's agent, the same
backend the Octo engine uses (`POST /api/octo/agent/step` in saturday). The
model and its key live in the backend; the test Octo only signs in with your
October account, and usage is billed to that account like Octo's. For each
step it sends the task and a real screenshot, gets one step back (click,
type, keys, scroll, open a link or an app, check the Wi-Fi, done, give up),
and does it here: **each action (a click, typing, opening a link…) is shown
to you first and only
runs if you type `y`** (`--trust` skips that). "Show me the screen" sends
the real screen. `--no-agent` simulates tasks instead.

## Needs

- An October account with a **password** (the test Octo signs in with
  email + password) on a plan that includes phone access.
- The phone signed in to **the same account** (the app's "Use a password"
  option works).
- `config/real.json` (gitignored), with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- The Octo API switched on for your account (`octo_policy` in saturday;
  migration 054 in production). If it isn't, a task ends with the backend's
  own sentence (for example that Octo isn't available yet).
- Screenshots and control use the desktop portal (GNOME/KDE on Wayland):
  the first screenshot may ask "Allow screenshot?" and the first action
  asks to share the screen: **turn on "Allow remote interaction"** in that
  dialog, or the agent can't click or type (the test Octo then forgets the
  choice and asks again). Both are remembered after that. Needs `python3-gobject` and
  ImageMagick (`magick`), both standard on Fedora.

## Run

```sh
dart run tool/test_octo/main.dart --email you@example.com
```

It asks for the password (or reads `OCTO_TEST_PASSWORD`), signs in, and the
first time prints a QR code. In the app: **Add an Octo** → scan it. Both
screens show six digits; tap **They match** on the phone, then type `y` in
the terminal (that's Mom's OK). Then name her and pick a look.

Keys and paired phones are kept in `~/.config/octo-test-host/state.json`,
so restarting keeps the pairing. Delete that file to start over as a new
computer.

## Commands

| Type | What happens |
| --- | --- |
| `pair` | a new QR code (each works for 5 minutes, once) |
| `y` / `n` | answer a pairing request |
| `ok` / `no` | Mom answers the question on her screen (a task, showing the screen) |
| `y` / `n` | also: allow or refuse the next action the agent wants (click, typing, opening…) |
| `todo` | Mom saves a to-do for you (with a screenshot) |
| `sos` or `help <text>` | Mom asks for help |
| `offline` / `online` | the computer goes away / comes back |
| `remove` | Mom removes every phone |
| `auto` | autopilot: Mom answers by herself after a moment |
| `status`, `quit` | |

Start with `--autopilot` to have Mom answer task questions by herself,
`--trust` to let the agent click and type without asking, `--no-agent` to
simulate tasks, and
`--name "Dad's PC" --person Dad` for another computer (give it its own
`--state` file).

## Notes

- The relay ends the computer's socket about every five minutes ("lease
  renewal"); it reconnects at once and the phone reconnects after it.
- `quit` and start again: the phone shows the computer offline, then back.
- Protocol details: [docs/relay-protocol.md](../../docs/relay-protocol.md).
