#!/usr/bin/env bash
# 커밋 범위에 AI 협업자 흔적이 남아 있는지 검사한다. CI 의 최종 강제.
#
#   ./.githooks/no-ai-trailers.sh <base>..<head>
#   ./.githooks/no-ai-trailers.sh            (인자 없으면 최근 20개)
#
# commit-msg 훅이 지우지만 훅은 `--no-verify` 로 건너뛸 수 있다.
# 건너뛴 것이 main 에 들어가지 않게 여기서 막는다.

set -uo pipefail

range="${1:-}"
if [ -z "$range" ] || ! git rev-parse "$range" >/dev/null 2>&1; then
  range="HEAD~20..HEAD"
  git rev-parse "$range" >/dev/null 2>&1 || range="HEAD"
fi

PATTERNS='^[[:space:]]*co-authored-by:[[:space:]]*claude
^[[:space:]]*co-authored-by:.*(anthropic\.com|claude)
^[[:space:]]*claude-session:[[:space:]]*http
^[[:space:]]*_?(🤖[[:space:]]*)?generated (with|by) \[claude code\]'

fail=0
while read -r sha; do
  [ -n "$sha" ] || continue
  hits="$(git log -1 --format='%B' "$sha" | grep -inE "$PATTERNS" || true)"
  if [ -n "$hits" ]; then
    fail=1
    printf '✕ %s  %s\n' "$(git log -1 --format='%h %s' "$sha")" ""
    printf '%s\n' "$hits" | sed 's/^/    /'
  fi
done < <(git rev-list "$range" 2>/dev/null)

if [ "$fail" -ne 0 ]; then
  cat >&2 <<'EOF'

✕ 커밋 메시지에 AI 협업자 흔적이 남아 있습니다.

이 저장소의 커밋 기록에는 사람만 남습니다. 아래로 고쳐 주세요.

  git config core.hooksPath .githooks     # 훅을 설치하면 자동으로 지워집니다
  git rebase -i <base>                    # 이미 올린 커밋은 메시지를 고쳐야 합니다

EOF
  exit 1
fi

echo "✓ 커밋 메시지에 AI 협업자 흔적 없음 ($range)"
exit 0
