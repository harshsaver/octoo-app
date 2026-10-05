# Test Octo

A stand-in for the Octo desktop app, for trying the family app for real:
real October sign-in, real pairing, October's real relay, end-to-end
encryption. Only "Mom" is simulated (the app's `SimulatedComputer`), and you
play her from the terminal.

## Needs

- An October account with a **password** (the test Octo signs in with
  email + password) on a plan that includes phone access.
- The phone signed in to **the same account** (the app's "Use a password"
  option works).
- `config/real.json` (gitignored), with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

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
| `ok` / `no` | Mom answers the question on her screen |
| `todo` | Mom saves a to-do for you (with a screenshot) |
| `sos` or `help <text>` | Mom asks for help |
| `offline` / `online` | the computer goes away / comes back |
| `remove` | Mom removes every phone |
| `auto` | autopilot: Mom answers by herself after a moment |
| `status`, `quit` | |

Start with `--autopilot` to have Mom answer everything by herself, and
`--name "Dad's PC" --person Dad` for another computer (give it its own
`--state` file).

## Notes

- The relay ends the computer's socket about every five minutes ("lease
  renewal"); it reconnects at once and the phone reconnects after it.
- `quit` and start again: the phone shows the computer offline, then back.
- Protocol details: [docs/relay-protocol.md](../../docs/relay-protocol.md).
