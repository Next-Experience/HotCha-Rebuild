---
name: new-feature
description: 새 기능·기능 변경을 허브(hotcha)에서 시작한다 — 중복을 확인하고, FR-ID를 찾거나 새로 부여하고, 기능 이슈를 만들고(원격이 있을 때), requirements.md(필요하면 contracts/)를 고치는 첫 커밋을 낸다. "기능 추가", "새 기능", "요구사항 추가", "FR 만들어", "동작 바꿔" 같은 요청에 쓴다.
---

<!-- 허브 hotcha에서 옮겨 온 사본 — 원본: hotcha .claude/skills/new-feature/SKILL.md. 고칠 때는 허브를 먼저 고치고 이 사본을 맞춘다. -->
> 이 절차의 경로(`AGENTS.md` · `requirements.md` · `contracts/` 등)와 명령은 **허브 hotcha 기준**이다.
> 작업공간의 허브 폴더(`../hotcha`)에서 실행한다.

# 새 기능 시작

흐름의 원칙은 `AGENTS.md` "이슈 → 구현 → 클로즈"와 `requirements.md` 상단 "이 문서를 읽고 쓰는 법"에 있다 — 먼저 읽는다.
이 스킬은 그 1~2단계(이슈 생성 · 요구사항 반영)를 밟는 순서다.

**허브 원격이 아직 없으면** 4단계(이슈)를 건너뛰고 FR-ID만으로 간다 — `AGENTS.md` "원격이 생기기 전까지".
원격이 생기면 아래 `$HUB`는 그 저장소(`Next-Experience/<허브 이름>`)다.

## 1. 무엇을 만드는지 사용자와 맞춘다

- 사용자가 **무엇을 경험하는가**를 한두 문장으로 받아 적는다. 화면 구조·클래스는 적지 않는다.
- 실패했을 때 무엇을 말하는지, 위치 · 권한이 없을 때 어떻게 되는지를 같이 묻는다 — 핫챠의 기능은 거의 다 여기서 갈린다.
- 데이터를 새로 받거나 굽는 것이면 `contracts/`도 바뀐다고 알린다.

## 2. 이미 있는지 본다

```bash
grep -n "<핵심어>" requirements.md
gh issue list --repo "$HUB" --state all --search "<핵심어>" --limit 10    # 원격이 있을 때
```

기존 FR의 동작을 바꾸는 것이면 **새 번호를 만들지 않고** 그 FR-ID를 쓴다.

## 3. 새 FR-ID를 정한다 (새 기능일 때만)

도메인은 `requirements.md`의 절 제목 끝 괄호다(`## C. 노선 알람 (ROUTE)`). 다음 번호는 그 도메인에서 **쓰인 적 있는 가장 큰 번호 + 1** —
지금 문서에 없어도 과거에 쓰였으면 재사용하지 않는다.

```bash
D=ROUTE
grep -oE "FR-$D-[0-9]+" requirements.md | sort -t- -k3 -n | tail -1          # 지금 문서의 최댓값
git log -p --all -S "FR-$D-" -- requirements.md | grep -oE "FR-$D-[0-9]+" | sort -t- -k3 -n | tail -1   # 과거 포함
```

어느 도메인에도 안 맞으면 새 절을 만들고 도메인 이름을 사용자와 정한다.

## 4. 이슈를 만든다 (원격이 있을 때)

`.github/ISSUE_TEMPLATE/feature.md`의 절(기능 · 관련 FR-ID · 규칙·제약 · 전파 대상 · 완료 정의)을 채운다. 버그면 `bug.md`.

- 제목: `[FR-<도메인>-NN] <사용자 관점 한 문장, "~한다">` — 예 `[FR-TRAIN-07] 열차를 골라 남은 역 수와 도착 예정 시각을 본다`
- 라벨: `type:feature`(버그면 `type:bug`) + `area:ios`

## 5. 요구사항을 고친다 — 이 작업의 첫 커밋

허브 통합 브랜치를 최신화한 뒤 브랜치 `docs/<짧은 영문 이름>`.

- 새 FR은 그 도메인 절의 **끝**에 `### FR-<도메인>-NN  <제목>`으로 넣는다. 아직 없는 부분은 문장 끝에 `[구현 필요]`.
- 데이터 규격이 바뀌면 `contracts/`도 **같은 커밋**에서 고친다. 방향이 바뀌면 `reference/decisions/`에 결정을 남긴다.
- `python3 scripts/check-links.py`
- 커밋·PR 제목: `feat(<도메인 소문자>): <요약> — FR-<도메인>-NN · $HUB#N` (버그면 `fix`, 원격이 없으면 이슈 자리를 비운다).
  PR 본문 첫 줄에 `Refs #N` — 이 PR로 이슈가 끝나지 않는다(구현이 남았다).

## 6. 넘겨준다

사용자에게 알린다: (이슈 번호) · FR-ID · 허브 브랜치/PR · 다음은 앱(`HotCha-Rebuild`)에서 구현.
구현 PR은 제목·본문에 FR-ID(와 이슈 번호)를 적는다. 다 끝나면 `close-issue` 스킬로 닫는다.
