#!/usr/bin/env bash
# 핫챠 검증 — 사람 · Claude · Git Hook · CI 가 모두 이 명령 하나를 쓴다.
#
#   ./scripts/verify.sh          전체 (규칙 + 포맷 + 린트 + 코어 테스트 + iOS 빌드 + 경고 0)
#   ./scripts/verify.sh --quick  빠른 것만 (앱 빌드 제외) — 반복 작업 중에 쓴다
#
# 완료 판정은 언제나 인자 없는 전체 실행이다.
#
# 설치 안 된 도구는 건너뛰되 무엇이 빠졌는지 알린다.
# 없다고 조용히 통과시키면 검증이 거짓말을 시작한다.
#
# **이 검증이 보지 못하는 것**: 앱 타깃에는 테스트가 없다. 화면과 위치·알림 동작은
# 빌드가 되는지까지만 확인되고, 실제로 도는지는 시뮬레이터나 기기에서 눈으로 봐야 한다.

set -uo pipefail
cd "$(dirname "$0")/.."

RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLD=$'\033[1m'; DIM=$'\033[2m'; OFF=$'\033[0m'
QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1
fail=0; skipped=()

step() { printf '\n%s▸ %s%s\n' "$BLD" "$1" "$OFF"; }
ok()   { printf '%s  ✓ %s%s\n' "$GRN" "$1" "$OFF"; }
bad()  { printf '%s  ✕ %s%s\n' "$RED" "$1" "$OFF"; fail=1; }
skip() { printf '%s  – %s (미설치)%s\n' "$DIM" "$1" "$OFF"; skipped+=("$2"); }

# 포맷은 새로 쓰는 코드가 모이는 곳만 본다. 예전 화면 코드는 한 번에 정리하기 전까지 지적이 수백 건이다.
FORMAT_DIRS="HotChaKit/Sources HotChaKit/Tests HotCha/HotCha/Data/Local HotCha/HotCha/Features/StopAlarm"

# ── 1. 프로젝트 전용 규칙 ────────────────────────────────────
step "프로젝트 규칙"
./scripts/check-project-rules.sh || fail=1

# ── 2. 포맷 (Xcode 내장) ────────────────────────────────────
step "코드 포맷"
if xcrun --find swift-format >/dev/null 2>&1; then
  # 경고로만 다룬다. 스타일 때문에 빌드를 막지 않는다.
  # 자동 수정은 사람이 명시적으로 요청했을 때만 (작업 범위 밖 파일까지 번지면 리뷰가 불가능해진다)
  if out=$(swift format lint --recursive $FORMAT_DIRS 2>&1); then
    ok "swift-format"
  else
    printf '%s  ! swift-format 지적 %s건%s\n' "$YEL" "$(echo "$out" | grep -c 'warning:\|error:')" "$OFF"
    echo "$out" | head -8 | sed 's/^/    /'
    printf '%s    고치기: swift format --in-place --recursive %s%s\n' "$DIM" "$FORMAT_DIRS" "$OFF"
  fi
else
  skip "swift-format" "Xcode 16+ 필요"
fi

# ── 3. 린트 ────────────────────────────────────────────────
step "SwiftLint"
if command -v swiftlint >/dev/null 2>&1; then
  if out=$(swiftlint lint --quiet --strict 2>&1); then ok "SwiftLint"
  else bad "SwiftLint"; echo "$out" | head -20 | sed 's/^/    /'; fi
else
  skip "SwiftLint" "brew install swiftlint"
fi

# ── 4. HotChaKit — 알람 규칙의 방어선 (시뮬레이터 불필요) ────
# 정류장을 따라가고 알람 시점을 정하는 규칙이 전부 여기 있다. 초 단위로 돈다.
step "HotChaKit"
kitlog=$(mktemp)
if (cd HotChaKit && swift test) > "$kitlog" 2>&1; then
  n=$(grep -oE 'Test run with [0-9]+ test' "$kitlog" | tail -1 | grep -oE '[0-9]+')
  if [ -z "${n:-}" ] || [ "$n" -eq 0 ]; then
    # 0건 실행되고도 성공하는 것이 가장 위험한 초록이다.
    bad "HotChaKit 테스트가 0건 실행됐다"
    tail -10 "$kitlog" | sed 's/^/    /'
  else
    ok "HotChaKit 테스트 ${n}건 통과"
  fi
else
  bad "HotChaKit 테스트 실패"
  grep -E 'recorded an issue|error:' "$kitlog" | head -15 | sed 's/^/    /'
fi
rm -f "$kitlog"

if [ $QUICK -eq 1 ]; then
  step "앱 빌드"
  printf '%s  – 건너뜀 (--quick)%s\n' "$DIM" "$OFF"
else
  # ── 5. iOS 빌드 ───────────────────────────────────────────
  # 앱과 Live Activity 익스텐션을 함께 컴파일한다. 서명은 하지 않는다.
  # 기본 DerivedData 는 스테일 소스를 컴파일할 수 있어 저장소 안의 자리를 쓴다.
  step "iOS 빌드"
  SIM_ID=$(./scripts/select-simulator.sh) || {
    printf '%s✕ 시뮬레이터 없음%s\n' "$RED" "$OFF"; exit 1;
  }
  # 원본 로그는 언제나 파일로 남긴다. 경고를 세려면 xcbeautify 가 걸러내기 전의 것이 필요하다.
  ilog=$(mktemp)
  # 증분 빌드는 안 바뀐 파일의 경고를 다시 찍지 않는다. 경고를 세려면 앱 타깃을 처음부터 컴파일해야 한다.
  xcodebuild clean build -project HotCha/HotCha.xcodeproj -scheme HotCha \
    -destination "id=$SIM_ID" -derivedDataPath .build/dd \
    CODE_SIGNING_ALLOWED=NO > "$ilog" 2>&1
  rc=$?
  if [ $rc -eq 0 ] && grep -q 'BUILD SUCCEEDED' "$ilog"; then
    ok "iOS 빌드 (앱 + Live Activity)"
  else
    bad "iOS 빌드 실패"
    if command -v xcbeautify >/dev/null 2>&1; then
      xcbeautify --quiet < "$ilog" | tail -20
    else
      grep -E 'error:' "$ilog" | head -15 | sed 's/^/    /'
    fi
  fi

  # ── 6. 빌드 경고 0 ────────────────────────────────────────
  # 문서에 적힌 게이트는 검사가 없으면 게이트가 아니다.
  # 컴파일러 경고만 센다 — 도구가 찍는 "... warning: ..." 줄까지 세면 언제나 실패한다.
  # 로그가 비면 셀 것이 없어 0건으로 초록이 난다. 그래서 먼저 컴파일이 실제로 돌았는지 본다.
  step "빌드 경고 0"
  compiled=$(grep -cE 'SwiftCompile|CompileSwift|SwiftDriver' "$ilog" || true)
  if [ "${compiled:-0}" -eq 0 ]; then
    bad "컴파일 흔적이 없다 — 경고를 셀 근거가 없다"
  else
    warnings=$(grep -E '^/.*:[0-9]+:[0-9]+: warning: ' "$ilog" | sort -u | wc -l | tr -d ' ')
    if [ "${warnings:-0}" -gt 0 ]; then
      bad "빌드 경고 ${warnings}건 (경고 0)"
      grep -E '^/.*:[0-9]+:[0-9]+: warning: ' "$ilog" | sort -u | sed 's/^/    /' | head -10
    else
      ok "빌드 경고 0"
    fi
  fi
  rm -f "$ilog"
fi

# ── 결과 ───────────────────────────────────────────────────
echo
if [ ${#skipped[@]} -gt 0 ]; then
  printf '%s건너뛴 검사%s\n' "$YEL" "$OFF"
  for s in "${skipped[@]}"; do printf '  · %s\n' "$s"; done
  echo
fi

if [ $fail -eq 0 ]; then
  if [ $QUICK -eq 1 ]; then
    printf '%s%s부분 검증 통과 — 완료 판정에는 전체를 돌린다%s\n' "$YEL" "$BLD" "$OFF"
  elif [ ${#skipped[@]} -gt 0 ]; then
    printf '%s%s건너뛴 검사가 있어 전체 통과가 아니다%s\n' "$YEL" "$BLD" "$OFF"
  else
    printf '%s%s검증 통과%s\n' "$GRN" "$BLD" "$OFF"
    # 커밋 게이트(.githooks/pre-commit)가 읽는 스탬프.
    # 전체 검증이 건너뛴 검사 없이 통과했을 때만 쓴다 — 부분 검증은 통과가 아니다.
    # git diff HEAD 는 정확히 '커밋될 내용' 이라, 이 뒤에 한 글자라도 고치면 어긋나 커밋이 막힌다.
    mkdir -p .claude
    printf '%s' "$(git rev-parse HEAD)$(git diff HEAD)" | shasum -a 256 | cut -d' ' -f1 > .claude/.verify-stamp
  fi
else
  printf '%s%s검증 실패 — 완료했다고 보고하지 않는다%s\n' "$RED" "$BLD" "$OFF"
fi
exit $fail
