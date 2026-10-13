#!/usr/bin/env bash
# UserPromptSubmit 훅 — 매 요청에 작업 루프와 현재 위치를 주입한다.
#
# stdout 이 그대로 모델 컨텍스트로 들어간다. 매 요청마다 돌기 때문에 짧고 빨라야 한다.
# 규약: CLAUDE.md 루프 절
set -uo pipefail

# 훅은 세션 cwd 에서 돌지만, 입력 JSON 의 cwd 가 더 정확하다.
input="$(cat 2>/dev/null || true)"
if command -v jq >/dev/null 2>&1 && [ -n "$input" ]; then
  hook_cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
  [ -n "$hook_cwd" ] && [ -d "$hook_cwd" ] && cd "$hook_cwd" || true
fi

cat <<'LOOP'
## 작업 루프 — 이 순서로 간다 (CLAUDE.md 루프 절)
0 브랜치 → 1 문서(동작·계약이 바뀔 때만) → 2 개발 → 3 검증 → 4 커밋 → 5 PR
PR 에서 멈춘다. 병합은 사람이 누른다.
칸을 건너뛰면 건너뛴다고 한 줄 말한다. 조용히 건너뛰는 것이 이 루프가 막으려는 것이다.
LOOP

# 저장소 하나의 상태를 한 줄로
state() {
  local dir="$1" name branch dirty
  name="$(basename "$(cd "$dir" && pwd)")"
  branch="$(git -C "$dir" branch --show-current 2>/dev/null)" || return 0
  dirty="$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  printf '· %s — %s' "$name" "$branch"
  [ "$dirty" != "0" ] && printf ' · 미커밋 %s개' "$dirty"
  { [ "$branch" = "main" ] || [ "$branch" = "develop" ]; } && [ "$dirty" != "0" ] && printf '  ⚠ %s 위에서 고치고 있다 — 브랜치를 판다' "$branch"
  printf '\n'
}

if root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  printf '\n현재 위치\n'
  state "$root"
else
  # 워크스페이스 루트 — '깨끗한 main' 이 아닌 저장소만 알린다
  found=0
  for d in */; do
    [ -d "${d}.git" ] || continue
    b="$(git -C "$d" branch --show-current 2>/dev/null)"
    n="$(git -C "$d" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    if { [ "$b" != "main" ] && [ "$b" != "develop" ]; } || [ "$n" != "0" ]; then
      [ "$found" = "0" ] && printf '\n진행 중인 저장소\n' && found=1
      state "$d"
    fi
  done
fi

exit 0
