#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-https://pagewalker.org}"

echo "Running extended smoke checks against: $BASE_URL"

python3 - "$BASE_URL" <<'PY'
import json
import sys
import urllib.request

base = sys.argv[1].rstrip("/")

def get_json(url: str):
    req = urllib.request.Request(url, headers={"User-Agent": "pagewalker-smoke/1.0"})
    with urllib.request.urlopen(req, timeout=25) as resp:
        if resp.status != 200:
            raise SystemExit(f"FAIL: {url} returned {resp.status}")
        raw = resp.read().decode("utf-8")
        return json.loads(raw)

def assert_true(cond: bool, message: str):
    if not cond:
        raise SystemExit(f"FAIL: {message}")

trending = get_json(f"{base}/api/books?type=trending&startIndex=0&maxResults=8")
assert_true("books" in trending or "items" in trending, "books API missing books/items")
if "books" in trending:
    assert_true(isinstance(trending.get("books"), list), "books must be a list")
    assert_true(len(trending["books"]) > 0, "books list is empty")

search = get_json(f"{base}/api/books?type=search&q=harry%20potter&startIndex=0&maxResults=8")
assert_true("books" in search or "items" in search, "search API missing books/items")

detail_id = None
if isinstance(search.get("books"), list) and search["books"]:
    detail_id = search["books"][0].get("id")
elif isinstance(search.get("items"), list) and search["items"]:
    first = search["items"][0]
    detail_id = f"google_{first.get('id', '')}" if isinstance(first, dict) else None

if detail_id:
    detail = get_json(f"{base}/api/books?type=detail&id={detail_id}")
    assert_true(isinstance(detail.get("title"), str) and len(detail["title"]) > 0, "detail missing title")

print("Extended smoke checks passed.")
PY
