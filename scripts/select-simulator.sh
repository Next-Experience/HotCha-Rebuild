#!/usr/bin/env bash
# 쓸 수 있는 iOS 시뮬레이터 UDID 를 고른다.
#
# 이름(name=iPhone 17 Pro)으로 지정하면 같은 이름이 여러 개일 때나
# 런타임이 안 맞을 때 조용히 실패한다. UDID 로 고정한다.
#
#   HOTCHA_SIMULATOR_ID=<udid>  로 덮어쓸 수 있다.

set -uo pipefail

if [ -n "${HOTCHA_SIMULATOR_ID:-}" ]; then
  echo "$HOTCHA_SIMULATOR_ID"; exit 0
fi

devices=$(xcrun simctl list devices available 2>/dev/null)

# 1) 이미 켜져 있는 iPhone — 부팅 시간을 아낀다
id=$(echo "$devices" | grep 'iPhone' | grep '(Booted)' | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')

# 2) 선호 기기
if [ -z "$id" ]; then
  for want in "iPhone 17 Pro" "iPhone 17" "iPhone 16 Pro" "iPhone 16"; do
    id=$(echo "$devices" | grep -F "$want (" | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
    [ -n "$id" ] && break
  done
fi

# 3) 아무 iPhone
[ -z "$id" ] && id=$(echo "$devices" | grep 'iPhone' | head -1 | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')

if [ -z "$id" ]; then
  echo "쓸 수 있는 iOS 시뮬레이터가 없습니다. Xcode > Settings > Platforms 에서 설치하세요." >&2
  exit 1
fi

echo "$id"
