#!/usr/bin/env python3
"""Takes a screenshot through the desktop portal (works on GNOME/KDE Wayland)
and prints the PNG's path. Exit code 1 with a reason on stderr otherwise."""
import secrets
import sys
from urllib.parse import unquote, urlparse

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
token = "octo" + secrets.token_hex(6)
sender = bus.get_unique_name()[1:].replace(".", "_")
handle = f"/org/freedesktop/portal/desktop/request/{sender}/{token}"
loop = GLib.MainLoop()
result = {}


def on_response(_conn, _sender, _path, _iface, _signal, params):
    code, results = params.unpack()
    result["code"] = code
    result["uri"] = results.get("uri")
    loop.quit()


bus.signal_subscribe("org.freedesktop.portal.Desktop", "org.freedesktop.portal.Request",
                     "Response", handle, None, Gio.DBusSignalFlags.NO_MATCH_RULE, on_response)
bus.call_sync("org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop",
              "org.freedesktop.portal.Screenshot", "Screenshot",
              GLib.Variant("(sa{sv})", ("", {"handle_token": GLib.Variant("s", token),
                                             "interactive": GLib.Variant("b", False)})),
              None, Gio.DBusCallFlags.NONE, -1, None)
GLib.timeout_add_seconds(int(sys.argv[1]) if len(sys.argv) > 1 else 60, loop.quit)
loop.run()
if result.get("code") == 0 and result.get("uri"):
    print(unquote(urlparse(result["uri"]).path))
    sys.exit(0)
print({0: "no picture", 1: "not allowed", 2: "failed"}.get(result.get("code"), "timed out"), file=sys.stderr)
sys.exit(1)
