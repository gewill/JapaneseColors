#!/usr/bin/env python3
"""Validate the bundled 365-color dataset offline with Python's standard library."""

import calendar
import hashlib
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
SERIES = {
    "yellow": "黄色", "green": "绿色", "red": "红色", "purple": "紫色",
    "blue": "蓝色", "pink": "粉色", "brown": "棕色", "orange": "橙色",
    "black": "黑色", "gray": "灰色", "white": "白色",
}
FIELDS = ("month", "date", "kanji", "hex", "ruby", "series", "desc")
EXPECTED = {
    f"{month}_{day}"
    for month in range(1, 13)
    for day in range(1, calendar.monthrange(2025, month)[1] + 1)
}
errors = []


def check(condition, message):
    if not condition:
        errors.append(message)


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        errors.append(f"{path.relative_to(ROOT)}: {error}")
        return None


def read_group(folder, names):
    records = {}
    check({p.stem for p in folder.glob("*.json")} == set(names),
          f"{folder.relative_to(ROOT)}: unexpected or missing JSON files")
    for name in names:
        path = folder / f"{name}.json"
        document = read_json(path)
        colors = document.get("colors") if isinstance(document, dict) else None
        if not isinstance(colors, list) or not colors:
            errors.append(f"{path.relative_to(ROOT)}: missing colors array")
            continue
        if folder.name == "byMonth":
            day_count = calendar.monthrange(2025, int(name))[1]
            check(len(colors) == day_count,
                  f"{path.relative_to(ROOT)}: wrong number of dates")
            check([color.get("date") for color in colors if isinstance(color, dict)]
                  == [str(day) for day in range(1, day_count + 1)],
                  f"{path.relative_to(ROOT)}: dates are not in calendar order")
        for color in colors:
            if not isinstance(color, dict) or not all(
                isinstance(color.get(field), str) and color[field].strip()
                for field in FIELDS
            ):
                errors.append(f"{path.relative_to(ROOT)}: missing or invalid color fields")
                continue
            identifier = f"{color['month']}_{color['date']}"
            check(identifier in EXPECTED, f"{path.name}: invalid date {identifier}")
            check(identifier not in records, f"{path.name}: duplicate date {identifier}")
            check(re.fullmatch(r"#[0-9A-Fa-f]{6}", color["hex"]),
                  f"{path.name}: invalid hex for {identifier}")
            if folder.name == "byMonth":
                check(color["month"] == name, f"{path.name}: misplaced date {identifier}")
            else:
                check(color["series"] == SERIES[name],
                      f"{path.name}: misplaced series for {identifier}")
            records[identifier] = color
    check(set(records) == EXPECTED, f"{folder.name}: does not cover all 365 dates")
    return records


by_month = read_group(ROOT / "scripts/byMonth", [str(month) for month in range(1, 13)])
by_color = read_group(ROOT / "scripts/byColor", SERIES)
for identifier in by_month.keys() & by_color.keys():
    check(by_month[identifier] == by_color[identifier],
          f"{identifier}: month and series records differ")

assets = ROOT / "JColors/Assets.xcassets"
color_assets = assets / "ColorImages"
check({path.stem for path in color_assets.glob("*.imageset")} == EXPECTED,
      "ColorImages: does not contain exactly the 365 expected image sets")
for path in assets.rglob("Contents.json"):
    contents = read_json(path)
    if not isinstance(contents, dict):
        errors.append(f"{path.relative_to(ROOT)}: invalid asset catalog metadata")
        continue
    for key in ("images", "assets", "layers"):
        for item in contents.get(key, []):
            if item.get("filename"):
                check((path.parent / item["filename"]).exists(),
                      f"{path.relative_to(ROOT)}: missing {item['filename']}")
    if path.parent.parent == color_assets:
        check(any(item.get("filename") == f"{path.parent.stem}.jpg"
                  for item in contents.get("images", [])),
              f"{path.relative_to(ROOT)}: date JPEG is not referenced")

image_bytes = 0
source_images = ROOT / "scripts/images"
check({path.stem for path in source_images.glob("*.jpg")} == EXPECTED,
      "scripts/images: does not contain exactly the 365 expected source images")
for identifier in sorted(EXPECTED):
    path = color_assets / f"{identifier}.imageset" / f"{identifier}.jpg"
    source = source_images / f"{identifier}.jpg"
    if not path.is_file() or not source.is_file():
        errors.append(f"{identifier}: missing bundled or source JPEG")
        continue
    data = path.read_bytes()
    image_bytes += len(data)
    check(data.startswith(b"\xff\xd8\xff") and data.endswith(b"\xff\xd9"),
          f"{identifier}: invalid JPEG file markers")
    check(hashlib.sha256(data).digest() == hashlib.sha256(source.read_bytes()).digest(),
          f"{identifier}: source JPEG and bundled JPEG differ")

if errors:
    print("\n".join(f"ERROR: {error}" for error in errors), file=sys.stderr)
    sys.exit(1)

print("OK: 365 dates, 12 months, 11 series, matching records and JPEGs; asset files exist.")
print(f"Color JPEG source size: {image_bytes:,} bytes ({image_bytes / 1024 ** 2:.2f} MiB).")
