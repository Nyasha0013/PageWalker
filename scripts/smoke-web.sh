#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-https://pagewalker.org}"
CURL_OPTS=(-sS -A "pagewalker-smoke/1.0" --connect-timeout 15 --max-time 45)

check_status() {
  local url="$1"
  local expected="$2"
  local attempts="${3:-1}"
  local delay="${4:-8}"
  local got=""
  local i

  for ((i = 1; i <= attempts; i++)); do
    got="$(curl "${CURL_OPTS[@]}" -o /dev/null -w "%{http_code}" "$url" || echo "000")"
    if [[ "$got" == "$expected" ]]; then
      echo "OK: $url ($got)"
      return 0
    fi
    if [[ "$i" -lt "$attempts" ]]; then
      echo "RETRY $i/$attempts: $url expected $expected got $got"
      sleep "$delay"
    fi
  done

  echo "FAIL: $url expected $expected got $got"
  return 1
}

check_classics_json() {
  local url="$1"
  local attempts="${2:-3}"
  local delay="${3:-8}"
  local i
  local body=""

  for ((i = 1; i <= attempts; i++)); do
    if body="$(curl "${CURL_OPTS[@]}" "$url" 2>/dev/null)" && [[ -n "$body" ]]; then
      if python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); sys.exit(0 if isinstance(d,dict) and "results" in d else 1)' <<<"$body"; then
        echo "OK: $url (200, valid classics JSON)"
        return 0
      fi
      echo "RETRY $i/$attempts: $url invalid classics JSON body"
    else
      echo "RETRY $i/$attempts: $url request failed"
    fi
    if [[ "$i" -lt "$attempts" ]]; then
      sleep "$delay"
    fi
  done

  echo "FAIL: $url classics response missing results[]"
  return 1
}

echo "Running smoke checks against: $BASE_URL"
check_status "$BASE_URL/" "200"
check_status "$BASE_URL/explore" "200"
check_status "$BASE_URL/discover" "200"
check_status "$BASE_URL/profile" "200"
check_status "$BASE_URL/api/config" "200" 2 5
check_status "$BASE_URL/api/books?type=trending&startIndex=0&maxResults=5" "200" 3 8
check_status "$BASE_URL/api/books?type=genre&genre=fantasy&startIndex=0&maxResults=5" "200" 3 8
check_status "$BASE_URL/api/books?type=search&q=harry%20potter&startIndex=0&maxResults=5" "200" 3 8
check_classics_json "$BASE_URL/api/books?type=classics&page=1" 3 8

echo "All smoke checks passed."
