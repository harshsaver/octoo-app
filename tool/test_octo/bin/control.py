#!/usr/bin/env python3
"""Mouse and keyboard for the test Octo, through the desktop portal's
RemoteDesktop with a ScreenCast of the screen (GNOME/KDE on Wayland).

The desktop asks once ("Allow remote interaction?"); the restore token is
kept in the file given as argv[1], so later runs don't ask again.

Reads one JSON command per line on stdin and answers one JSON line each:
  {"op": "start"}                                  -> {"ok": true, "width": W, "height": H}
  {"op": "click", "fx": 0.5, "fy": 0.5, "double": false}   (fractions of the screen)
  {"op": "type", "text": "hello"}
  {"op": "keys", "keys": ["Ctrl+L", "Enter"]}
  {"op": "scroll", "dx": 0, "dy": 3}               (wheel notches; positive = down/right)
Errors: {"ok": false, "error": "..."}.
"""
import json
import os
import secrets
import sys
import time

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

PORTAL = "org.freedesktop.portal.Desktop"
PATH = "/org/freedesktop/portal/desktop"
RD = "org.freedesktop.portal.RemoteDesktop"
SC = "org.freedesktop.portal.ScreenCast"
BTN_LEFT = 0x110

KEYSYMS = {
    "enter": 0xFF0D, "return": 0xFF0D, "tab": 0xFF09, "escape": 0xFF1B, "esc": 0xFF1B,
    "space": 0x20, "backspace": 0xFF08, "delete": 0xFFFF, "del": 0xFFFF,
    "up": 0xFF52, "down": 0xFF54, "left": 0xFF51, "right": 0xFF53,
    "home": 0xFF50, "end": 0xFF57, "pageup": 0xFF55, "pagedown": 0xFF56,
    "ctrl": 0xFFE3, "control": 0xFFE3, "shift": 0xFFE1, "alt": 0xFFE9, "option": 0xFFE9,
    "cmd": 0xFFEB, "command": 0xFFEB, "super": 0xFFEB, "meta": 0xFFEB, "win": 0xFFEB,
}
for n in range(1, 13):
    KEYSYMS[f"f{n}"] = 0xFFBE + n - 1


def keysym_for_char(c):
    if c == "\n":
        return 0xFF0D
    if c == "\t":
        return 0xFF09
    code = ord(c)
    return code if 0x20 <= code <= 0xFF else 0x01000000 | code


def keysym_for_name(name):
    lower = name.strip().lower()
    if lower in KEYSYMS:
        return KEYSYMS[lower]
    if len(name.strip()) == 1:
        return keysym_for_char(name.strip().lower())
    raise ValueError(f"unknown key {name!r}")


class Portal:
    def __init__(self, token_file):
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        self.sender = self.bus.get_unique_name()[1:].replace(".", "_")
        self.token_file = token_file
        self.session = None
        self.stream = None
        self.size = None

    def request(self, iface, method, build):
        """Calls a portal method that answers through a Request object."""
        token = "octo" + secrets.token_hex(6)
        handle = f"/org/freedesktop/portal/desktop/request/{self.sender}/{token}"
        loop = GLib.MainLoop()
        result = {}

        def on_response(_c, _s, _p, _i, _sig, params):
            code, results = params.unpack()
            result["code"], result["results"] = code, results
            loop.quit()

        sub = self.bus.signal_subscribe(PORTAL, "org.freedesktop.portal.Request", "Response", handle,
                                        None, Gio.DBusSignalFlags.NO_MATCH_RULE, on_response)
        try:
            self.bus.call_sync(PORTAL, PATH, iface, method, build(GLib.Variant("s", token)),
                               None, Gio.DBusCallFlags.NONE, -1, None)
            GLib.timeout_add_seconds(180, loop.quit)
            loop.run()
        finally:
            self.bus.signal_unsubscribe(sub)
        if result.get("code") != 0:
            raise RuntimeError({1: "not allowed", 2: "failed"}.get(result.get("code"), "no answer"))
        return result["results"]

    def start(self):
        if self.session:
            return
        session_token = "octo" + secrets.token_hex(6)
        res = self.request(RD, "CreateSession", lambda t: GLib.Variant("(a{sv})", ({
            "handle_token": t, "session_handle_token": GLib.Variant("s", session_token)},)))
        self.session = res["session_handle"]
        restore = None
        if os.path.exists(self.token_file):
            with open(self.token_file) as f:
                restore = f.read().strip() or None
        options = lambda t: {"handle_token": t, "types": GLib.Variant("u", 3),  # noqa: E731
                             "persist_mode": GLib.Variant("u", 2)}

        def select_devices(t):
            o = options(t)
            if restore:
                o["restore_token"] = GLib.Variant("s", restore)
            return GLib.Variant("(oa{sv})", (self.session, o))

        self.request(RD, "SelectDevices", select_devices)
        self.request(SC, "SelectSources", lambda t: GLib.Variant("(oa{sv})", (self.session, {
            "handle_token": t, "types": GLib.Variant("u", 1), "multiple": GLib.Variant("b", False)})))
        res = self.request(RD, "Start", lambda t: GLib.Variant("(osa{sv})", (self.session, "", {"handle_token": t})))
        token = res.get("restore_token")
        if token:
            os.makedirs(os.path.dirname(self.token_file), exist_ok=True)
            with open(self.token_file, "w") as f:
                f.write(token)
            os.chmod(self.token_file, 0o600)
        streams = res.get("streams") or []
        if not streams:
            raise RuntimeError("no screen was shared")
        node, props = streams[0]
        self.stream = node
        self.size = props.get("size") or (0, 0)

    def notify(self, method, signature, *args):
        self.bus.call_sync(PORTAL, PATH, RD, method,
                           GLib.Variant(signature, (self.session, {}) + args),
                           None, Gio.DBusCallFlags.NONE, -1, None)

    def move(self, fx, fy):
        w, h = self.size
        x = max(0.0, min(w - 1.0, fx * w))
        y = max(0.0, min(h - 1.0, fy * h))
        self.notify("NotifyPointerMotionAbsolute", "(oa{sv}udd)", self.stream, x, y)

    def click(self, fx, fy, double=False):
        self.move(fx, fy)
        time.sleep(0.05)
        for _ in range(2 if double else 1):
            self.notify("NotifyPointerButton", "(oa{sv}iu)", BTN_LEFT, 1)
            time.sleep(0.04)
            self.notify("NotifyPointerButton", "(oa{sv}iu)", BTN_LEFT, 0)
            time.sleep(0.08)

    def key(self, keysym, pressed):
        self.notify("NotifyKeyboardKeysym", "(oa{sv}iu)", keysym, 1 if pressed else 0)

    def type(self, text):
        for c in text:
            ks = keysym_for_char(c)
            self.key(ks, True)
            self.key(ks, False)
            time.sleep(0.01)

    def chord(self, chord):
        syms = [keysym_for_name(part) for part in chord.split("+") if part.strip()]
        for s in syms:
            self.key(s, True)
        for s in reversed(syms):
            self.key(s, False)
        time.sleep(0.05)

    def scroll(self, dx, dy):
        if dy:
            self.notify("NotifyPointerAxisDiscrete", "(oa{sv}ui)", 0, int(dy))
        if dx:
            self.notify("NotifyPointerAxisDiscrete", "(oa{sv}ui)", 1, int(dx))


def main():
    portal = Portal(sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.config/octo-test-host/remote-desktop.token"))
    for line in sys.stdin:
        try:
            cmd = json.loads(line)
            op = cmd.get("op")
            portal.start()
            if op == "start":
                out = {"ok": True, "width": portal.size[0], "height": portal.size[1]}
            elif op == "click":
                portal.click(float(cmd["fx"]), float(cmd["fy"]), bool(cmd.get("double")))
                out = {"ok": True}
            elif op == "type":
                portal.type(str(cmd["text"]))
                out = {"ok": True}
            elif op == "keys":
                for chord in cmd["keys"]:
                    portal.chord(str(chord))
                out = {"ok": True}
            elif op == "scroll":
                portal.scroll(int(cmd.get("dx", 0)), int(cmd.get("dy", 0)))
                out = {"ok": True}
            else:
                out = {"ok": False, "error": f"unknown op {op!r}"}
        except Exception as e:  # noqa: BLE001 - every failure goes back as a line
            out = {"ok": False, "error": str(e)}
        sys.stdout.write(json.dumps(out) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
