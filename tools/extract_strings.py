#!/usr/bin/env python3
"""Build game/locale/strings.csv from the player-visible English texts.

Sources:
  - tr("...") calls with a double-quoted literal in every .gd file under game/
    (skipping game/tests, game/tools and game/.godot).
  - JSON data fields (English text used as the key):
      divisions.json   stage_name
      research.json    name
      echo_shop.json   name_key
      milestones.json  name_key
      contracts.json   text, title, name, description

Output: game/locale/strings.csv, UTF-8, header "keys,en", one row per unique
text, sorted. Both columns hold the English text.

Usage: python tools/extract_strings.py
"""

import csv
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = os.path.join(ROOT, "game")
OUT = os.path.join(GAME, "locale", "strings.csv")
SKIP_DIRS = {"tests", "tools", ".godot"}

# tr("...") with a double-quoted literal. Group 1 is the raw literal body.
TR_RE = re.compile(r'\btr\(\s*"((?:[^"\\\n]|\\.)*)"')

# File name -> JSON field names that hold player-visible English text.
JSON_FIELDS = {
    "divisions.json": {"stage_name"},
    "research.json": {"name"},
    "echo_shop.json": {"name_key"},
    "milestones.json": {"name_key"},
    "contracts.json": {"text", "title", "name", "description"},
}

ESCAPES = {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}


def unescape(raw: str) -> str:
    out = []
    i = 0
    while i < len(raw):
        ch = raw[i]
        if ch == "\\" and i + 1 < len(raw):
            nxt = raw[i + 1]
            out.append(ESCAPES.get(nxt, "\\" + nxt))
            i += 2
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def gd_files():
    for dirpath, dirnames, filenames in os.walk(GAME):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            if name.endswith(".gd"):
                yield os.path.join(dirpath, name)


def collect_tr(found: set) -> int:
    count = 0
    for path in gd_files():
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
        for m in TR_RE.finditer(text):
            value = unescape(m.group(1))
            if value != "":
                found.add(value)
                count += 1
    return count


def walk_json(node, fields: set, hits: list, used: set):
    if isinstance(node, dict):
        for key, value in node.items():
            if key in fields and isinstance(value, str) and value != "":
                hits.append(value)
                used.add(key)
            else:
                walk_json(value, fields, hits, used)
    elif isinstance(node, list):
        for item in node:
            walk_json(item, fields, hits, used)


def collect_json(found: set) -> None:
    data_dir = os.path.join(GAME, "data")
    for file_name, fields in sorted(JSON_FIELDS.items()):
        path = os.path.join(data_dir, file_name)
        if not os.path.isfile(path):
            print(f"JSON missing: {file_name}")
            continue
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        hits: list = []
        used: set = set()
        walk_json(data, fields, hits, used)
        found.update(hits)
        print(f"JSON {file_name}: {len(hits)} texts, fields used: {sorted(used)}")


def main() -> None:
    found: set = set()
    tr_count = collect_tr(found)
    print(f"tr() calls found: {tr_count}")
    collect_json(found)

    rows = sorted(found)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(["keys", "en"])
        for text in rows:
            writer.writerow([text, text])
    print(f"Wrote {OUT}")
    print(f"Strings: {len(rows)}")


if __name__ == "__main__":
    main()
