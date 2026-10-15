#!/usr/bin/env bash
# 핫챠 전용 규칙 검사.
#
# 기성 린터가 모르는 것만 본다. 전부 이 저장소에서 실제로 한 번씩 사고를 냈거나,
# 어긋나면 조용히 깨지는 것들이다. 근거는 AGENTS.md 의 「함정」 절에 있다.

set -uo pipefail
cd "$(dirname "$0")/.."

RED=$'\033[31m'; YEL=$'\033[33m'; DIM=$'\033[2m'; OFF=$'\033[0m'
fail=0

report() {  # report <심각도> <규칙> <근거> <설명>
  local sev=$1 rule=$2 why=$3 msg=$4
  if [ "$sev" = error ]; then
    printf '%s✕%s %s  %s%s%s\n    %s\n' "$RED" "$OFF" "$rule" "$DIM" "$why" "$OFF" "$msg"; fail=1
  else
    printf '%s!%s %s  %s%s%s\n    %s\n' "$YEL" "$OFF" "$rule" "$DIM" "$why" "$OFF" "$msg"
  fi
}

KIT="HotChaKit/Sources/HotChaKit"
KIT_TESTS="HotChaKit/Tests/HotChaKitTests"
APP="HotCha/HotCha"
LIVE="HotCha/HotchaLive"
DB="$APP/Resources/BusData.sqlite"

# ── --list · 규칙 목록을 검사기가 직접 출력한다 ────────────────
# 개수를 문서에 손으로 적으면 반드시 어긋난다. 셈은 여기서만 한다.
if [ "${1:-}" = "--list" ]; then
  grep '^# ── 규칙' "$0" | sed 's/^# ── /  /' | sed 's/ ─.*$//'
  exit 0
fi

# 주석은 검사하지 않는다. 규칙을 설명하는 주석이 그 규칙에 걸리면 검사기가 자기 문서를 문다.
strip_comments() { grep -vE '^[^:]+:[0-9]+:[[:space:]]*(///?|\*|/\*)' || true; }

# ── 규칙 0 · 검사기 자신을 검사한다 ───────────────────────────
# 경로가 어긋나면 모든 grep 이 빈손으로 돌아오고 검사기는 조용히 초록을 낸다.
for dir in "$KIT" "$KIT_TESTS" "$APP" "$LIVE"; do
  [ -d "$dir" ] || report error "검사 대상 없음: $dir" "자기 검사" \
    "검사기가 아무것도 훑지 못했습니다 — 초록불은 거짓입니다."
done
scanned=$(find "$KIT" "$KIT_TESTS" "$APP" "$LIVE" -name '*.swift' 2>/dev/null | wc -l | tr -d ' ')
[ "$scanned" -ge 20 ] || report error "훑은 파일이 너무 적음 (${scanned}개)" "자기 검사" \
  "경로가 어긋났거나 체크아웃이 잘렸습니다. 이 상태의 통과는 근거가 없습니다."

# 알람 규칙을 실제로 지키는 것은 아래 grep 이 아니라 이 테스트들이다.
# 파일이나 테스트가 사라지면 방어선이 사라진 것이므로 여기서 막는다.
# 이름은 hotcha/reference/invariants.md 의 표와 정확히 같아야 한다.
CORE_TESTS=(
  "$KIT_TESTS/RouteTrackerTests.swift:가장_가까운_정류장에서_출발한다"
  "$KIT_TESTS/RouteTrackerTests.swift:목적지를_지난_정류장은_출발점이_아니다"
  "$KIT_TESTS/RouteTrackerTests.swift:정류장을_하나_건너뛰어도_따라잡는다"
  "$KIT_TESTS/RouteTrackerTests.swift:뒤로는_가지_않는다"
  "$KIT_TESTS/RouteTrackerTests.swift:N정류장_전에_알람이_한_번만_울린다"
  "$KIT_TESTS/RouteTrackerTests.swift:알람_정류장을_건너뛰어도_울린다"
  "$KIT_TESTS/RouteTrackerTests.swift:시작부터_N보다_가까우면_바로_울리지_않고_한_정류장_전에_울린다"
  "$KIT_TESTS/StationApproachTests.swift:반경_안에_들어오면_한_번만_울린다"
  "$KIT_TESTS/StationApproachTests.swift:흐린_위치로는_울리지_않고_거리도_바꾸지_않는다"
  "$KIT_TESTS/StationApproachTests.swift:반경_두_배_안에서_신호가_끊기면_미리_울린다"
  "$KIT_TESTS/StationApproachTests.swift:멀리서_신호가_끊기면_울리지_않는다"
)
for entry in "${CORE_TESTS[@]}"; do
  file="${entry%%:*}"; name="${entry##*:}"
  grep -q "func ${name}(" "$file" 2>/dev/null || report error "핵심 테스트 없음: ${name}" "불변식" \
    "${file} 에서 이 테스트가 사라졌습니다. 알람 규칙의 방어선입니다."
done

# ── 규칙 1 · 서비스 키를 소스에 적지 않는다 ────────────────────
# 공공데이터 서비스 키가 소스 다섯 군데에 박힌 채 공개 저장소에 올라가 있었다.
hits=$(grep -rnE 'serviceKey=[A-Za-z0-9%]{20,}|"[A-Za-z0-9%+/]{60,}={0,2}"' "$APP" "$LIVE" "$KIT" --include='*.swift' | strip_comments)
[ -z "$hits" ] || report error "규칙 1 · 하드코딩된 키" "함정: API 키" \
  "키는 Config/Secrets.xcconfig 에 두고 BusAPI.serviceKey 로 읽습니다.
$(printf '%s\n' "$hits" | cut -c1-120 | sed 's/^/      /')"

# ── 규칙 2 · API 키는 BusAPI 한 곳에서만 읽는다 ────────────────
# 읽는 곳이 여럿이면 한 곳은 반드시 하드코딩으로 되돌아간다. 실제로 그랬다.
hits=$(grep -rn '"API_KEY"' "$APP" "$LIVE" --include='*.swift' | grep -v 'Data/Network/BusAPI.swift' | strip_comments)
[ -z "$hits" ] || report error "규칙 2 · 키를 BusAPI 밖에서 읽음" "함정: API 키" \
  "$(printf '%s\n' "$hits" | cut -c1-120)"

# ── 규칙 3 · Secrets.xcconfig 는 git 에 올리지 않는다 ──────────
if git ls-files --error-unmatch HotCha/Config/Secrets.xcconfig >/dev/null 2>&1; then
  report error "규칙 3 · Secrets.xcconfig 가 추적되고 있음" "함정: API 키" \
    "git rm --cached HotCha/Config/Secrets.xcconfig"
fi

# ── 규칙 4 · 실험용 파일을 앱 타깃에 두지 않는다 ───────────────
# 폴더가 통째로 타깃에 들어간다(파일 시스템 동기화 그룹). test.swift · gg.swift ·
# Dummy.swift 같은 파일이 출시 빌드에 그대로 실려 나갔다.
hits=$(find "$APP" "$LIVE" -name '*.swift' | grep -iE '/(test[^/]*|gg|dummy[^/]*|untitled[^/]*|[^/]*junk[^/]*|[^/]*TestView)\.swift$|/TestFile/')
[ -z "$hits" ] || report error "규칙 4 · 실험용 파일" "함정: 타깃에 딸려 가는 파일" \
  "$(printf '%s\n' "$hits")"

# ── 규칙 5 · 알람 규칙은 HotChaKit 에만 있다 ──────────────────
# 정류장을 따라가는 계산이 화면 코드에 있으면 테스트할 수 없고, 고칠 때마다 눈으로만 확인하게 된다.
engine="$APP/Core/Alarm/NearestBusViewModel.swift"
if [ -f "$engine" ]; then
  grep -q 'RouteTracker' "$engine" || report error "규칙 5 · 노선 알람이 RouteTracker 를 쓰지 않음" "불변식" \
    "$engine 은 HotChaKit 의 RouteTracker 결과를 옮기기만 합니다."
  hits=$(grep -nE '\.distance\(from:|\.seq[[:space:]]*-' "$engine" | strip_comments)
  [ -z "$hits" ] || report error "규칙 5 · 화면 쪽에서 정류장 거리·순번을 직접 계산" "불변식" \
    "$(printf '%s\n' "$hits" | cut -c1-120)"
else
  report error "규칙 5 · 노선 알람 엔진 파일 없음" "자기 검사" "$engine"
fi

# ── 규칙 6 · 검색 결과 줄에서 NavigationLink 를 쓰지 않는다 ────
# 검색이 닫히면 결과 줄이 사라지고, 그 안의 NavigationLink 는 이동하지 못한 채 같이 사라진다.
# 이동은 사라지지 않는 HomeScreen 이 SearchDestination 으로 맡는다.
hits=$(grep -rn 'NavigationLink' "$APP/Features/Search" --include='*.swift' | strip_comments)
[ -z "$hits" ] || report error "규칙 6 · 검색 결과의 NavigationLink" "함정: 검색 결과 이동" \
  "destination = .bus(...) 처럼 SearchDestination 을 설정합니다.
$(printf '%s\n' "$hits" | cut -c1-120 | sed 's/^/      /')"

# ── 규칙 7 · Live Activity 데이터 모양은 한 곳에만 적는다 ───────
# 예전에는 앱과 위젯에 따로 적혀 있었다. 한쪽만 바꾸면 컴파일은 되고 잠금 화면만 조용히 안 뜬다.
# 지금은 두 타깃이 LiveActivityShared 폴더를 함께 컴파일한다.
SHARED="HotCha/LiveActivityShared"
defs=$(grep -rln 'ActivityAttributes {' "$APP" "$LIVE" "$SHARED" --include='*.swift' 2>/dev/null)
if [ "$defs" != "$SHARED/HotChaActivityAttributes.swift" ]; then
  report error "규칙 7 · Live Activity 데이터 모양이 한 곳이 아님" "함정: Live Activity" \
    "ActivityAttributes 는 $SHARED/HotChaActivityAttributes.swift 에만 둡니다. 찾은 곳: ${defs:-없음}"
fi
grep -q "LiveActivityShared" HotCha/HotCha.xcodeproj/project.pbxproj || report error "규칙 7 · 공유 폴더가 프로젝트에 없음" \
  "함정: Live Activity" "LiveActivityShared 가 두 타깃의 동기화 폴더에 들어 있어야 합니다."

# ── 규칙 8 · 내장 DB 가 있고 비어 있지 않다 ───────────────────
# 검색 전체가 이 파일 하나에 달려 있다. 없으면 빌드는 되고 검색만 0건이 된다.
if [ ! -s "$DB" ]; then
  report error "규칙 8 · BusData.sqlite 없음" "함정: 내장 DB" "Tools/build_bus_db.py 로 만듭니다 (Readme.md)."
elif command -v sqlite3 >/dev/null 2>&1; then
  stops=$(sqlite3 "$DB" 'SELECT count(*) FROM stops' 2>/dev/null || echo 0)
  routes=$(sqlite3 "$DB" 'SELECT count(*) FROM routes' 2>/dev/null || echo 0)
  { [ "${stops:-0}" -gt 100000 ] && [ "${routes:-0}" -gt 10000 ]; } || report error "규칙 8 · BusData.sqlite 가 비었거나 잘림" \
    "함정: 내장 DB" "정류장 ${stops}개 · 노선 ${routes}개. 다시 만듭니다."
fi

# ── 규칙 9 · 평문 HTTP 는 서울 버스 API 한 곳뿐이다 ────────────
# ATS 예외는 Info.plist 에 도메인 단위로 걸려 있다. 주소가 늘면 예외도 조용히 따라 늘어난다.
hits=$(grep -rn '"http://' "$APP" "$LIVE" "$KIT" --include='*.swift' | grep -v 'ws\.bus\.go\.kr' | strip_comments)
[ -z "$hits" ] || report error "규칙 9 · 평문 HTTP 주소" "함정: 평문 통신" \
  "$(printf '%s\n' "$hits" | cut -c1-120)"

# ── 규칙 10 · 모서리 반경은 HotChaRadius 로만 쓴다 ─────────────
# 화면마다 24 · 20 · 11 · 8 로 제각각이라 앱이 둥글둥글하고 어수선했다. 값은 세 가지뿐이다.
hits=$(grep -rnE 'cornerRadius: *[0-9]|\.cornerRadius\( *[0-9]|presentationCornerRadius' "$APP" "$LIVE" "$SHARED" --include='*.swift' | strip_comments)
[ -z "$hits" ] || report error "규칙 10 · 반경을 숫자로 적음" "디자인: 모서리" \
  "HotChaRadius.card · .tile · .badge 중 하나를 씁니다.
$(printf '%s\n' "$hits" | cut -c1-120 | sed 's/^/      /')"

[ "$fail" = "0" ] && printf '  ✓ 프로젝트 규칙 통과 (스위프트 파일 %s개)\n' "$scanned"
exit $fail
