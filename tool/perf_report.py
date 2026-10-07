#!/usr/bin/env python3
"""Markdown summary of the performance run (PLAN §5) for CI's job summary.

  python3 tool/perf_report.py perf.log build/steps.timeline_summary.json
"""
import json
import re
import sys

log, summary = sys.argv[1], sys.argv[2]
print("## Performance (emulator, software GPU — not a phone)\n")
try:
    m = re.search(r"list_ms: (\d+)", open(log).read())
    print(f"- Launch to the Octos list (in-app): **{m.group(1)} ms**" if m else "- Time to the list: not reported")
except OSError:
    print("- Time to the list: no log")
try:
    s = json.load(open(summary))
except (OSError, ValueError):
    print("- Frame timings: no summary (the run failed)")
    sys.exit(0)
rows = [
    ("Frames", s.get("frame_count")),
    ("Build, average (ms)", s.get("average_frame_build_time_millis")),
    ("Build, 90th percentile (ms)", s.get("90th_percentile_frame_build_time_millis")),
    ("Build, worst (ms)", s.get("worst_frame_build_time_millis")),
    ("Build, missed 16 ms budget", s.get("missed_frame_build_budget_count")),
    ("Raster, average (ms)", s.get("average_frame_rasterizer_time_millis")),
    ("Raster, 90th percentile (ms)", s.get("90th_percentile_frame_rasterizer_time_millis")),
    ("Raster, missed 16 ms budget", s.get("missed_frame_rasterizer_budget_count")),
]
print("\n50 steps streaming into an open thread:\n")
print("| | |\n| --- | --- |")
for name, value in rows:
    if value is not None:
        print(f"| {name} | {round(value, 2) if isinstance(value, float) else value} |")
