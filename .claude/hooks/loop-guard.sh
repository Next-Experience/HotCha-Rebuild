#!/usr/bin/env bash
# PreToolUse(Bash) 훅 — git 훅으로는 막을 수 없는 우회를 막는다.
#
# 실제 검증 게이트는 .githooks/pre-commit 이다. 이 훅의 몫은 두 가지다.
#   1. `--no-verify` — pre-commit 을 통째로 무력화하는 문. 여기서만 막을 수 있다.
#   2. `develop`·`main` 직접 푸시 — 커밋이 아니라 푸시라 pre-commit 이 못 본다.
# 그 외에는 막지 않는다. 막을 게 많아지면 사람이 훅을 꺼 버린다.
#
# 규약: AGENTS.md 「무엇이 이 흐름을 강제하나」
set -uo pipefail

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(printf '%s' "$1" | jq -Rs .)"
  exit 0
}

command -v jq >/dev/null 2>&1 || exit 0
input="$(cat 2>/dev/null || true)"
[ -n "$input" ] || exit 0

cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -n "$cmd" ] || exit 0
case "$cmd" in *git*) ;; *) exit 0 ;; esac

hook_cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
[ -n "$hook_cwd" ] && [ -d "$hook_cwd" ] && cd "$hook_cwd" 2>/dev/null || true

# 명령이 가리키는 저장소를 찾는다: `git -C <dir>` → `cd <dir> &&` → 세션 cwd
target="."
if [[ "$cmd" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
  target="${BASH_REMATCH[1]}"
elif [[ "$cmd" =~ ^[[:space:]]*cd[[:space:]]+([^[:space:]\;\&\|]+) ]]; then
  target="${BASH_REMATCH[1]}"
fi
target="${target%\"}"; target="${target#\"}"
target="${target%\'}"; target="${target#\'}"
[ -d "$target" ] || target="."

branch="$(git -C "$target" branch --show-current 2>/dev/null || true)"

# ── 1. pre-commit 우회 ────────────────────────────────────────
if [[ "$cmd" =~ (^|[[:space:]])git([[:space:]]|.)*(commit|merge) ]] && [[ "$cmd" =~ --no-verify|[[:space:]]-n([[:space:]]|$) ]]; then
  deny "\`--no-verify\` 는 .githooks/pre-commit 을 통째로 무력화합니다 — 검증 스탬프·통합 브랜치 보호·CLAUDE.md=@AGENTS.md 검사가 전부 꺼집니다.

검증이 아직 안 돌았다면 돌리세요:
    ./scripts/verify.sh

정말 게이트를 열어야 하는 상황이라면, 무엇을 여는지 이름을 붙여 여세요:
    LOOP_SKIP_VERIFY=1 git commit ...     검증 스탬프만
    LOOP_ALLOW_MAIN=1 git commit ...      develop·main 위 커밋만
둘 다 훅이 경고를 찍습니다. (AGENTS.md)"
fi

# ── 2. main 직접 푸시 ─────────────────────────────────────────
if [[ "$cmd" =~ (^|[[:space:]])git([[:space:]]|.)*push ]]; then
  pushes_main=0
  # 명시적 refspec: `git push origin main` · `git push origin HEAD:main`
  # 앞에 공백이나 ':' 를 요구한다 — 안 그러면 `feature/main` 같은 브랜치명에 오탐이 난다.
  [[ "$cmd" =~ push.*[[:space:]:](main|master|develop)([[:space:]]|$) ]] && pushes_main=1
  # 암묵적: main 위에서 그냥 `git push`
  { [ "$branch" = "main" ] || [ "$branch" = "master" ] || [ "$branch" = "develop" ]; } && pushes_main=1
  # 브랜치를 명시적으로 올리는 건 정상
  [[ "$cmd" =~ push([[:space:]]|.)*(-u|--set-upstream)([[:space:]]|.)*HEAD ]] && [ "$branch" != "main" ] && [ "$branch" != "develop" ] && pushes_main=0

  if [ "$pushes_main" = "1" ]; then
    deny "\`develop\`·\`main\` 에 직접 푸시하지 않습니다 (저장소: ${target}, 현재 브랜치: ${branch:-?}).

브랜치 → PR → 사람이 병합이 순서입니다:
    git switch -c <type>/<주제>
    git push -u origin HEAD
    gh pr create

PR 에서 멈춥니다. 병합은 사람이 누릅니다. (AGENTS.md)"
  fi
fi

exit 0
