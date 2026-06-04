#!/usr/bin/env python3
"""Renumber personalization word IDs and fix image_uri extensions."""

from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "assets" / "personalization" / "personalization_words.json"
IMAGES_DIR = ROOT / "assets" / "personalization" / "images"
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}


def build_stem_index() -> dict[str, list[tuple[float, str]]]:
    by_stem: dict[str, list[tuple[float, str]]] = defaultdict(list)
    for file in IMAGES_DIR.iterdir():
        if file.is_file() and file.suffix.lower() in IMAGE_EXTS:
            by_stem[file.stem.lower()].append((file.stat().st_mtime, file.name))
    return by_stem


def resolve_uri(old_uri: str, by_stem: dict[str, list[tuple[float, str]]]) -> tuple[str, str | None]:
    name = Path(old_uri).name
    stem = Path(name).stem.lower()
    candidates = by_stem.get(stem, [])
    if not candidates:
        return old_uri, f"missing file for stem: {stem}"

    exact = [item for item in candidates if item[1] == name]
    chosen = exact[0][1] if exact else max(candidates, key=lambda item: item[0])[1]
    new_uri = f"assets/personalization/images/{chosen}"
    note = None if new_uri == old_uri else f"{name} -> {chosen}"
    return new_uri, note


def main() -> None:
    by_stem = build_stem_index()
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    words = data["personalization_words"]
    fixes: list[str] = []

    for index, word in enumerate(words, start=1):
        word["id"] = index
        old_uri = word["image_uri"]
        new_uri, note = resolve_uri(old_uri, by_stem)
        word["image_uri"] = new_uri
        if note:
            fixes.append(f"id {index} ({word['word_arabic']}): {note}")

    JSON_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    missing = [
        (word["id"], word["word_arabic"], word["image_uri"])
        for word in words
        if not (ROOT / word["image_uri"]).exists()
    ]

    print(f"words: {len(words)}, ids: 1..{len(words)}")
    print("uri fixes:")
    if fixes:
        for line in fixes:
            print(f"  {line}")
    else:
        print("  (none)")

    if missing:
        print("still missing:")
        for item in missing:
            print(f"  {item}")
    else:
        print("all image files exist")


if __name__ == "__main__":
    main()
