#!/usr/bin/env python3
"""Validate a public podcast RSS feed before submitting it to directories."""

from __future__ import annotations

import argparse
import sys
import urllib.request
import xml.etree.ElementTree as ET

ITUNES = "http://www.itunes.com/dtds/podcast-1.0.dtd"
NS = {"itunes": ITUNES}
ALLOWED_AUDIO_TYPES = {"audio/aac", "audio/mp4", "audio/mpeg", "audio/x-m4a"}


def fail(message: str) -> None:
    raise ValueError(message)


def text(parent: ET.Element, path: str, label: str) -> str:
    value = parent.findtext(path, default="", namespaces=NS).strip()
    if not value:
        fail(f"missing {label}")
    return value


def fetch(url: str, timeout: float, byte_range: bool = False) -> tuple[bytes, str]:
    headers = {"User-Agent": "castopod-podcast-publisher-rss-validator/1.0"}
    if byte_range:
        headers["Range"] = "bytes=0-0"
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        content_type = response.headers.get_content_type()
        return response.read(1 if byte_range else -1), content_type


def validate(feed_url: str, timeout: float) -> int:
    feed_bytes, feed_type = fetch(feed_url, timeout)
    if feed_type not in {"application/rss+xml", "application/xml", "text/xml"}:
        fail(f"unexpected feed content type: {feed_type}")

    root = ET.fromstring(feed_bytes)
    if root.tag != "rss" or root.get("version") != "2.0":
        fail("root must be <rss version=\"2.0\">")

    channel = root.find("channel")
    if channel is None:
        fail("missing channel")

    for path, label in (
        ("title", "channel title"),
        ("description", "channel description"),
        ("link", "channel link"),
        ("language", "channel language"),
        ("itunes:author", "iTunes author"),
        ("itunes:owner/itunes:name", "owner name"),
        ("itunes:owner/itunes:email", "owner email"),
    ):
        text(channel, path, label)

    owner_email = text(channel, "itunes:owner/itunes:email", "owner email")
    if "@" not in owner_email:
        fail("owner email is invalid")

    image = channel.find("itunes:image", NS)
    image_url = image.get("href", "").strip() if image is not None else ""
    if not image_url:
        fail("missing iTunes image")
    _, image_type = fetch(image_url, timeout, byte_range=True)
    if not image_type.startswith("image/"):
        fail(f"unexpected image content type: {image_type}")

    items = channel.findall("item")
    if not items:
        fail("feed must contain at least one episode")

    for index, item in enumerate(items, start=1):
        text(item, "title", f"episode {index} title")
        text(item, "guid", f"episode {index} guid")
        text(item, "pubDate", f"episode {index} publication date")

        enclosure = item.find("enclosure")
        if enclosure is None:
            fail(f"episode {index} is missing enclosure")
        url = enclosure.get("url", "").strip()
        media_type = enclosure.get("type", "").strip().lower()
        length = enclosure.get("length", "").strip()
        if not url:
            fail(f"episode {index} enclosure is missing URL")
        if media_type not in ALLOWED_AUDIO_TYPES:
            fail(f"episode {index} has unsupported audio type: {media_type}")
        if not length.isdigit() or int(length) <= 0:
            fail(f"episode {index} has invalid enclosure length")

        _, served_type = fetch(url, timeout, byte_range=True)
        if served_type not in ALLOWED_AUDIO_TYPES:
            fail(f"episode {index} URL serves unexpected type: {served_type}")

    print(f"OK: {len(items)} episode(s), owner email {owner_email}, RSS is directory-ready")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("feed_url")
    parser.add_argument("--timeout", type=float, default=20)
    args = parser.parse_args()
    try:
        return validate(args.feed_url, args.timeout)
    except (ET.ParseError, OSError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
