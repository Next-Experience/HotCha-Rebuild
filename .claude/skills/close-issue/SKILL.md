---
name: close-issue
description: 구현이 끝난 허브(hotcha) 기능을 닫는다 — 앱 PR 병합을 확인하고, 완료 정의 4항목을 대조하고, requirements.md의 [구현 필요]를 정리한 뒤 이슈를 직접 닫는다(원격이 있을 때). 구현 PR은 `Refs`로만 참조하므로 병합해도 이슈는 열려 있다. "이슈 닫아", "FR 마무리", "클로즈" 같은 요청이나, 허브 FR에 걸린 앱 PR을 병합한 직후에 쓴다.
---

<!-- 허브 hotcha에서 옮겨 온 사본 — 원본: hotcha .claude/skills/close-issue/SKILL.md. 고칠 때는 허브를 먼저 고치고 이 사본을 맞춘다. -->
> 이 절차의 경로(`AGENTS.md` · `requirements.md` · `contracts/` 등)와 명령은 **허브 hotcha 기준**이다.
> 작업공간의 허브 폴더(`../hotcha`)에서 실행한다.

# 허브 기능 닫기

완료 정의(DoD)의 원문은 `AGENTS.md` "이슈 → 구현 → 클로즈"다 — 먼저 읽는다.
하나라도 거짓이면 닫지 않는다.

**허브 원격이 아직 없으면** 이슈 대신 FR-ID로 대조하고, 결과를 사용자에게 보고하는 것으로 닫는다.
`AGENTS.md` "현재 상태"에 그 항목이 있으면 지운다.

## 1. 이슈와 PR을 모은다

```bash
gh issue view N --repo "$HUB" --json title,labels,state,body                                  # 원격이 있을 때
gh pr list --repo Next-Experience/HotCha-Rebuild --state all --search "FR-<ID>" --json number,title,state
git -C ../HotCha-Rebuild log --oneline --all --grep "FR-<ID>"
```

이미 닫혀 있으면(PR의 `Closes`로 자동으로 닫혔으면) 다시 열고 이 절차를 밟는다.

## 2. 앱에서 끝났는가

앱에 **병합된** 구현 PR이 있는지 본다. 열린 PR이 남았거나 PR이 없으면 여기서 멈추고 무엇이 남았는지 알린다.

## 3. 완료 정의를 대조한다

| 항목 | 어떻게 보나 |
|---|---|
| requirements.md가 최종 동작과 일치 | 그 FR 절을 읽고 동작과 맞는지, 끝난 부분에 `[구현 필요]`가 남지 않았는지 |
| 데이터 규격이 바뀌었다면 contracts/ 일치 | 앱 PR이 데이터 · API 를 바꿨으면 허브 `contracts/`에 같은 변경이 들어갔는지 |
| 앱 구현·검증 초록 | 앱 PR에 `./scripts/verify.sh` 통과가 적혔는지. 화면 · 위치 · 알람 · 실기기는 본 것과 못 본 것이 나뉘어 적혔는지 |
| 구현 커밋이 FR-ID와 이슈를 참조 | `git -C ../HotCha-Rebuild log --first-parent develop --grep "FR-<ID>"` |

FR과 무관한 버그·잡무 이슈는 첫째·둘째 줄을 "해당 없음"으로 적는다.
실기기에서 못 본 것이 남았으면 닫지 말고 그 항목을 이슈(또는 `AGENTS.md` "현재 상태")에 남긴다.

## 4. 닫는다

이슈에 댓글 하나로 결과를 남기고 닫는다 — 병합된 PR 목록, DoD 대조 결과.

```bash
gh issue close N --repo "$HUB" --reason completed --comment "<결과>"
```
