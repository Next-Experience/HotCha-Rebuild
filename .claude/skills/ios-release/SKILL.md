---
name: ios-release
description: 앱 업데이트를 심사에 낼 때 릴리스 노트 초안을 쓰고, 낸 직후 마케팅 버전을 다음 판으로 올려 다음 업데이트 작업을 연다. "버전 올려", "심사 냈어", "다음 판", "배포 준비", "릴리스 노트" 같은 요청에 쓴다.
---

# 심사 제출과 마케팅 버전 올리기

버전 규칙의 원문은 `DEPLOYMENT.md`의 **"버전 번호 규칙"**이다. 이 스킬은 순서만 정하고 규칙을 옮겨 적지 않는다 —
시작 전에 그 절을 읽는다.

핵심: `project.pbxproj`의 `MARKETING_VERSION`은 **지금 작업 중인 판**이다. 그 판을 심사에 내면 곧바로 patch를 올려
다음 판의 작업을 연다. 그래서 일은 두 시점에 나뉜다.

- **A. 심사에 낼 때** — 그 판에 들어간 PR로 릴리스 노트 초안을 쓴다. 코드는 바꾸지 않는다.
- **B. 심사에 낸 직후** — 버전을 다음 판으로 올리는 PR을 만든다.

"버전 올려"처럼 B만 청하면 A가 끝났는지(노트를 이미 냈는지) 묻고, 필요하면 A부터 한다.

## A. 심사에 낼 때 — 릴리스 노트 초안

### 1. 이 판에 무엇이 들어갔나

```bash
git switch develop && git pull --ff-only
git log --first-parent --format='%h %s' -G'MARKETING_VERSION = ' -- HotCha/HotCha.xcodeproj/project.pbxproj | head -1   # 이 판으로 올린 커밋
git log --first-parent --format='%h %s' <그 커밋>..HEAD                                                                  # 그 뒤 병합된 PR = 이 판의 내용
```

커밋 메시지를 `--grep`으로 찾지 않는다 — 본문에 "마케팅 버전을"이 들어간 커밋이 잡힌다.
병합된 PR이 없으면 멈추고 알린다 — 낼 것이 없다.

### 2. 노트를 쓴다

1단계 목록에서 **사용자가 느끼는 변경만** 고른다 — `feat`·`fix`는 넣고 `refactor`·`test`·`chore`·`ci`·`docs`는 뺀다.
사용자가 한 문장으로 알아들을 말로 쓴다. 화면·기능 이름은 앱에 보이는 이름 그대로, 코드·FR-ID·이슈 번호는 쓰지 않는다.

- `• …했어요` / `• …할 수 있어요`

항목마다 `• `(가운뎃점 문자)로 시작하는 한 줄로 쓰고, 항목 사이에 빈 줄을 하나 둔다.
App Store Connect의 "이 버전의 새로운 기능" 칸은 마크다운을 그리지 않는다.

노트는 PR이 아니라 대화로 건넨다. 사용자가 할 일:

1. 이 판의 마지막 빌드가 TestFlight에 올라오면 `DEPLOYMENT.md` **"첫 빌드에서 확인할 것"** 체크리스트를 본다.
2. App Store Connect에서 이 버전을 만들고, 노트를 붙여 넣고, 그 빌드를 골라 심사에 낸다.
3. 내면 B로 넘어간다.

## B. 심사에 낸 직후 — 다음 판 열기

### 3. 다음 버전을 정한다

지금 `MARKETING_VERSION`(방금 낸 판)에서 patch를 하나 올린 값을 제안하고 사용자 확인을 받는다.
minor·major는 사용자가 정할 때만 올린다.

### 4. 버전을 고친다

고치는 곳은 둘뿐이다.

- `HotCha/HotCha.xcodeproj/project.pbxproj`의 `MARKETING_VERSION` — 앱 · Live Activity 두 타깃의 **모든 구성**
- `DEPLOYMENT.md` "미리 준비할 것" 표의 `(현재 \`x.y.z\`)`

```bash
sed -i '' 's/MARKETING_VERSION = <낸 버전>;/MARKETING_VERSION = <다음 버전>;/' HotCha/HotCha.xcodeproj/project.pbxproj
grep -E 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' HotCha/HotCha.xcodeproj/project.pbxproj | sort | uniq -c   # 각각 한 가지 값만
git diff --stat                                                                                               # project.pbxproj · DEPLOYMENT.md 둘만
```

`CURRENT_PROJECT_VERSION`(빌드 번호)은 이 PR에서 손대지 않는다. `./scripts/verify.sh`를 돌린다 — pbxproj 가 바뀌었다.

### 5. PR

브랜치 `chore/bump-<버전>`, 커밋과 PR 제목은 `chore: 마케팅 버전을 <버전>로 올린다`(받침에 따라 `으로`).
허브 이슈는 만들지 않는다 — 기능 변경이 아니다. 본문:

~~~markdown
<낸 버전> 심사 제출을 마쳤다. 버전을 <다음 버전>로 올려 다음 업데이트 작업을 시작한다 —
이 PR 뒤에 병합되는 PR이 <다음 버전>의 내용이 된다.
~~~

이 PR은 다른 PR보다 먼저 병합해야 한다 — 그 전에 병합된 PR의 빌드는 심사 중인 버전 번호로 올라간다.
