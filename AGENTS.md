# AGENTS.md — HotCha-Rebuild

> 이 문서가 원본이다. `CLAUDE.md`는 `@AGENTS.md` 한 줄로 이 파일을 불러오기만 한다 — 규칙을 고칠 때는 여기를 고친다.

핫챠(HotCha): 버스(와 기차)에서 **내릴 곳을 놓치지 않게** 알려 주는 iOS 앱.
탄 버스와 내릴 정류장을 고르면 몇 정류장 전에(**노선 알람**), 정류장만 고르면 거리로(**정류장 알람**), 기차역을 고르면 km 거리로(**기차역 알람**) 울린다.

## 스택

SwiftUI · iOS 26.1+(AlarmKit, 결정 0005) · 라이트 고정 · SwiftData · 내장 SQLite(`BusData.sqlite`) ·
알람 규칙 Swift 패키지 `HotChaKit`(Swift Testing) · Live Activity 위젯 익스텐션.
프로젝트 파일은 손으로 관리한다(폴더 동기화 — 폴더가 통째로 타깃에 들어간다). 외부 패키지 의존성 없음. 서버 없음 — 공공 버스 API 와 MapKit 을 직접 부른다.

## SSoT — 제품·계약은 hotcha 허브에

이 앱은 **hotcha 허브 저장소의 요구사항·계약을 구현**한다. 원격은 [Next-Experience/hotcha](https://github.com/Next-Experience/hotcha)(비공개), 로컬에선 작업공간의 형제 폴더 `../hotcha`.

- **어떤 기능을 왜 만드는가**(사용자 관점) → hotcha `requirements.md` (`FR-<도메인>-NN`)
- **앱 밖과 주고받는 규격**(버스 데이터 · 공공 API · 기차역 목록) → hotcha `contracts/`
- **왜 그렇게 정했나** → hotcha `reference/decisions/` · 알람 규칙의 불변식 → hotcha `reference/invariants.md`
- **개발 흐름**(이슈 → 구현 → 클로즈, 완료 정의): hotcha `AGENTS.md`. 기능 변경은 허브에서 시작한다.
  절차 스킬 — 아래 때가 오면 이 저장소의 `.claude/skills/<이름>/SKILL.md`를 읽고 그대로 밟는다.
  허브 스킬은 허브에서 옮겨 온 사본이다(머리에 표시). 원본은 허브이고, 고칠 때는 허브를 먼저 고친 뒤 사본을 맞춘다. 경로·명령은 허브 기준이다.
  - 기능·동작을 바꾸는 작업을 시작할 때 → `new-feature`
  - 허브 FR에 걸린 구현 PR을 병합한 직후 → `close-issue`
  - 완료했다고 보고하기 전 → `verify`(이 저장소 고유)
  - 앱 업데이트를 심사에 낼 때 · 낸 직후 → `ios-release`(이 저장소 고유)
- **코드 변경은 곧 문서 변경이다.** 기능 동작을 바꾸면 hotcha `requirements.md`를 같은 흐름에서 갱신하고 커밋·PR에 `FR-ID`를 남긴다.
- 어느 프로젝트에나 통하는 개발 규약은 작업공간의 `playbook/`에 있다.

## 명령어

```bash
cat .xcode-version                    # 팀이 쓰는 Xcode 메이저 버전 — verify.sh 가 다르면 막는다
git config core.hooksPath .githooks   # 클론마다 한 번 — 안 하면 .githooks/ 의 훅이 하나도 안 돈다
cp HotCha/Config/Secrets.xcconfig.example HotCha/Config/Secrets.xcconfig   # 공공데이터 키(hotcha onboarding.md)
open HotCha/HotCha.xcodeproj

./scripts/verify.sh           # 전체. 완료 판정은 이것만
./scripts/verify.sh --quick   # 앱 빌드 제외. 반복 작업 중에
cd HotChaKit && swift test    # 알람 규칙만. 초 단위, 시뮬레이터 불필요
```

실기기 설치 · 기기 로그 · TestFlight · 버전 번호 규칙은 `DEPLOYMENT.md`.
**Xcode 버전은 `.xcode-version`이 정한다.** 새 메이저로 넘어갈 때는 한 명이 새 Xcode로 `verify.sh`를 통과시킨 뒤 이 파일의 숫자를 올리는 PR을 낸다.
Xcode Cloud 워크플로는 아직 없다 — 생기면 `ci_scripts/ci_post_clone.sh`가 키와 빌드 번호를 넣는다(`DEPLOYMENT.md`).
GitHub Actions에는 커밋 위생 검사(`commit-hygiene.yml`)만 있다. 빌드 CI 는 없다 — 로컬 `verify.sh`가 게이트다.

## 작업 흐름 — 요청 하나가 지나가는 여섯 칸

```
0 브랜치 → 1 문서 → 2 개발 → 3 검증 → 4 커밋 → 5 PR
```

| | 칸 | 통과 조건 |
| --- | --- | --- |
| 0 | **브랜치** | `develop` 최신화 → 작업 브랜치. `develop`·`main` 위에서 코드를 고치지 않는다 |
| 1 | **문서** | **동작·계약이 바뀌면** 허브 `requirements.md`(`contracts/`)를 **먼저** 고친다. FR-ID를 정한다 |
| 2 | **개발** | 1에서 확정한 것만 만든다. 알람 규칙이면 🔴 → 🟢 → 🔵 |
| 3 | **검증** | `./scripts/verify.sh` 가 초록이다. **부분 검증은 통과가 아니다** |
| 4 | **커밋** | `type(scope): 한국어 요약 — FR-ID · 이슈`. 검증이 초록일 때만 |
| 5 | **PR** | 푸시하고 `develop` 으로 PR을 연다. **여기서 멈춘다** — 병합은 사람이 누른다 |

**칸을 건너뛰면 건너뛴다고 한 줄 말한다.** 조용히 건너뛰는 것이 이 흐름이 막으려는 것이다.
**1번이 면제되는 경우** — 순수 리팩터링(동작 불변) · 오타 · 포맷 · 빌드 설정 · 테스트 추가. 면제할 때는 "동작이 안 바뀌어 문서는 그대로 둡니다" 처럼 **말로 한다.**
**통합 브랜치는 `develop` 이다.** `main` 은 2025-02 의 README 커밋에 머물러 있고 코드가 없다.

### 무엇이 이 흐름을 강제하나

| 겹 | 무엇을 잡나 | 어디 |
| --- | --- | --- |
| 주입 | 매 요청에 흐름과 현재 브랜치·미커밋 상태 | `.claude/hooks/loop-context.sh` |
| 우회 차단 | `--no-verify` · `develop`·`main` 직접 푸시 | `.claude/hooks/loop-guard.sh` |
| 실제 게이트 | 통합 브랜치 위 커밋 · **검증 안 돈 커밋** · `CLAUDE.md`가 `@AGENTS.md` 한 줄이 아님 | `.githooks/pre-commit` |
| 커밋 기록 | AI 공동 작성자 트레일러를 지운다 | `.githooks/commit-msg` · `commit-hygiene.yml` |

**실제 차단은 git 훅이 한다.** 에이전트 훅은 명령 문자열을 파싱해야 해서 우회가 쉽고, 사람이 직접 커밋할 땐 아예 안 걸린다.

**검증 스탬프** — 검증이 **건너뛴 검사 없이 전부** 통과하면 `.claude/.verify-stamp` 에
`sha256(HEAD + git diff HEAD)` 를 쓴다. 검증 뒤에 한 글자라도 고치면 스탬프가 어긋나 커밋이 막힌다.
`--quick` 과 건너뛴 검사가 있는 실행은 스탬프를 **쓰지 않는다.**
**새 파일은 `git add` 를 먼저 한다** — 추적되지 않는 파일은 `git diff HEAD` 에 안 잡혀, 검증 뒤에 추가하면 스탬프가 어긋난다.

빠져나가는 문: `LOOP_ALLOW_MAIN=1`(통합 브랜치 위 커밋) · `LOOP_SKIP_VERIFY=1`(검증 스탬프).
둘 다 훅이 경고를 찍는다. 썼으면 무엇이 확인되지 않았는지 보고에 적는다.

## 검증 — 완료 전에 반드시

| 단계 | 내용 | 실패하면 |
| --- | --- | --- |
| Xcode 버전 | 로컬 메이저가 `.xcode-version` 과 같다 | 차단 |
| 프로젝트 규칙 | 목록은 `./scripts/check-project-rules.sh --list` | 차단 |
| 코드 포맷 | `swift format lint` (새 코드가 모이는 폴더만) | 경고만 |
| SwiftLint | `--strict`. 예전 코드가 대량으로 어기는 모양 규칙은 꺼 둠 | 차단 |
| **HotChaKit** | `swift test` — 알람 규칙의 방어선. 0건이면 실패 | 차단 |
| iOS 빌드 | 앱 + Live Activity 익스텐션, 처음부터 컴파일 | 차단 |
| **빌드 경고 0** | 컴파일러 경고를 직접 센다 | 차단 |

**이 검증이 보지 못하는 것.** 앱 타깃에는 테스트가 없다. 화면, 위치 추적, 알람, Live Activity 는
**빌드가 되는지까지만** 확인된다. 화면이나 알람 동작을 고쳤으면 시뮬레이터에서 직접 돌려 보고,
못 본 항목은 못 봤다고 보고에 적는다. 시뮬레이터는 AlarmKit 권한이 막혀 울림은 실기기로만 확인된다.

> **규칙 통과 ≠ 올바름.** 프로젝트 규칙은 grep 이다. 올바름은 테스트와 눈으로만 확인된다.

## 필수 규칙

1. **작업을 시작하기 전에 두 저장소(hotcha · HotCha-Rebuild)를 통합 브랜치로 최신화한다** — `git pull`은 지금 체크아웃된 브랜치만 최신화한다.
   그다음 **통합 브랜치에 직접 커밋·푸시하지 않는다.** 작업마다 `feat/` · `fix/` · `docs/` · `chore/` · `refactor/` 브랜치를 파서 커밋하고,
   푸시한 뒤 `develop`으로 PR을 연다. **병합은 사람이 누르고, 머지 커밋으로 한다(squash·rebase 금지)** — FR-ID별 커밋 추적을 살리기 위해서다.
   병합한 작업 브랜치는 지운다. 같은 체크아웃을 다른 세션이 쓰고 있을 수 있다 — 내 파일만 골라 커밋한다.
   구현이 허브 이슈에 대응하면 PR 본문에 `Refs Next-Experience/hotcha#N`으로 참조한다. **`Closes`·`Fixes`는 쓰지 않는다** — 병합 후 허브의 `close-issue` 절차로 닫는다.
   커밋 메시지는 **Conventional Commits + FR-ID**: `type(scope): 한국어 요약 — FR-ID · 이슈`
   (기능 변경엔 FR-ID 필수, 순수 잡무엔 생략). 전체 규칙은 hotcha `AGENTS.md`의 '커밋 메시지 규칙'. **Co-Authored-By에 AI 도구를 넣지 않는다.**
2. **문서 동기화는 작업 완료 조건이다.** 기능 동작이 바뀌면 hotcha `requirements.md`를, 데이터 규격이 바뀌면 hotcha `contracts/`를
   같은 작업에서 갱신한다. 코드와 문서가 다르면 그 작업은 끝나지 않은 것이다.
3. **문서·주석은 현재 상태만 서술한다.** 변경 이력·작성일·"기존 A에서 B로 교체" 서술 금지 — 변경 맥락은 커밋 메시지가 담당한다.
   주석은 "지금 이 코드가 무엇을 하는지"와 비자명한 "왜"만 적는다. **주석에 FR-ID·이슈 번호를 적지 않는다.**
4. **미해결 제약·보류 작업은 허브 이슈로 추적한다.** 이 저장소 안에 별도 목록 문서를 두지 않는다.
5. **API 키를 소스에 적지 않는다.** `Config/Secrets.xcconfig` 에 두고 `BusAPI.serviceKey` 로만 읽는다.
6. **알람 규칙은 `HotChaKit` 에서만 고친다.** 화면 쪽(`NearestBusViewModel`)은 결과를 화면·알림으로 옮기기만 한다.
   규칙을 바꿀 땐 실패하는 테스트를 먼저 쓴다.
7. **검색은 내장 DB 에서만 한다.** 검색을 위해 네트워크를 부르지 않는다. 장소 검색(MapKit)만 예외다.
   기차역도 내장 목록(`TrainStations.json`)에서 찾는다. 고른 역의 **좌표 확인**만 MapKit 을 부른다(결정 0006).
8. **화면은 시스템 기본 컴포넌트로 만든다.** `List` · `Form` · `.sheet` · `.alert` · `.searchable` · `Picker` · 시스템 글꼴.
   색은 강조색 `Color("mainpurple")` 하나와 시스템 색(`.primary` · `.secondary`)만 쓴다. 어두운 고정 배경을 만들지 않는다.
   바탕은 `HotChaContentBackground` 다. 디자인 규칙은 작업공간 루트 `디자인.md` 의 「확정 규칙」 절에 있다.
   **모서리 반경은 `HotChaRadius.card`(12) · `.tile`(8) · `.badge`(4) 만 쓴다.** 숫자를 직접 적으면 규칙 10 이 막는다.
   배너·카드의 바탕은 무늬 없는 `mainpurple` 단색이다. 예외는 안내가 없을 때의 홈 배너 하나 — 흰 바탕이다.
9. **`ObservableObject` 안에서 `@EnvironmentObject` 를 쓰지 않는다.** 뷰가 아니라서 읽는 순간 죽는다.
10. **실험용 화면·더미 데이터를 앱 폴더에 두지 않는다.** 폴더가 통째로 타깃에 들어가 출시 빌드에 실린다.
11. **안내는 한 번에 하나다.** 버스 안내를 시작하면 정류장 안내는 끝나고, 버스 안내 중에는 정류장 안내를 시작할 수 없다(FR-ALARM-01).

## 아키텍처 한눈에

```
HotCha-Rebuild/
├── HotChaKit/                 # 화면 없이 테스트하는 규칙 (Swift 패키지)
│   ├── Sources/HotChaKit/     #   RouteTracker(노선 알람) · StationApproach(기차역 알람) · Geo · NicknameGenerator
│   └── Tests/                 #   알람 규칙 테스트
├── HotCha/
│   ├── HotCha.xcodeproj       # 손으로 관리한다. 폴더는 통째로 타깃에 들어간다
│   ├── Config/                # HotCha.xcconfig · Secrets.xcconfig(git 제외)
│   ├── HotCha/
│   │   ├── App/               # 앱 진입점
│   │   ├── Core/              # Alarm(알람 엔진 · AlarmKit) · Location · LiveActivity · DevBus(디버그 전용 9999번)
│   │   ├── Data/              # Local(내장 DB · 기차역 목록) · Models(SwiftData) · Network(API)
│   │   ├── Features/          # 화면 단위
│   │   ├── Shared/            # 폰트 · 확장 · 유틸
│   │   └── Resources/         # 에셋 · BusData.sqlite · TrainStations.json
│   ├── HotchaLive/            # Live Activity · 다이내믹 아일랜드 화면 (위젯 익스텐션)
│   └── LiveActivityShared/    # Live Activity 데이터 모양 · 안내 단계. 앱과 위젯이 함께 컴파일한다
├── Tools/                     # build_bus_db.py · build_train_stations.py(+ train_stations_extra.csv)
├── ci_scripts/                # Xcode Cloud clone 직후 스크립트
└── scripts/                   # verify.sh · check-project-rules.sh · select-simulator.sh
```

**의존 방향**: `Features → Core → HotChaKit`, `Features → Data`. `HotChaKit` 은 아무것도 모른다
(SwiftUI·CoreLocation·네트워크를 가져오지 않는다). 왜 이렇게 나뉘었는지는 hotcha `reference/ios-architecture.md`.

**진실이 사는 곳**

| 무엇 | 어디 |
| --- | --- |
| 노선 알람이 언제 울리나 | `HotChaKit/Sources/HotChaKit/RouteTracker.swift` |
| 기차역 알람이 언제 울리나 (터널 포함) | `HotChaKit/Sources/HotChaKit/StationApproach.swift` |
| 기차역 검색 · 좌표 확인 | `Data/Local/TrainStationCatalog.swift` → `Resources/TrainStations.json` (`Tools/build_train_stations.py`) |
| 알람을 어떻게 울리나 | `Core/Alarm/AlarmRinger.swift` — AlarmKit 시스템 알람 하나. 로컬 알림 · 앱 소리는 쓰지 않는다 |
| 버스·정류장 검색 | `Data/Local/BusDatabase.swift` → `Resources/BusData.sqlite` |
| 노선의 정류장 순서 | API. `Data/Network/BusAPI.swift` 가 서울/지방을 가른다 |
| 즐겨찾기·이용 기록 | SwiftData (`Data/Models/`) |
| 진행 중인 안내 | `RouteAlarmSession`(버스) · `StopAlarmViewModel`(정류장 · 기차역). 탭 전체가 하나씩 나눠 쓴다 |
| Live Activity 데이터 모양 | `HotCha/LiveActivityShared/HotChaActivityAttributes.swift` |
| 안내 단계와 문구(홈 배너 · 잠금 화면 · 시트) | `HotCha/LiveActivityShared/HotChaGuidance.swift` |

## 작업별 문서 라우팅 — 코드를 만지기 전에 해당 문서부터

| 작업이 닿는 영역 | 먼저 읽을 문서 |
|---|---|
| 어떤 기능을 왜 만드는가(사용자 관점) | hotcha `requirements.md` (`FR-<도메인>-NN`) |
| 버스 데이터 · 공공 API · 내장 DB 를 다시 만들 때 | hotcha `contracts/bus-data.md` |
| 기차역 목록 · 좌표 | hotcha `contracts/train-stations.md` |
| 알람 규칙 (`HotChaKit`) | hotcha `reference/invariants.md` · 결정 0004 · 0006 |
| 화면 · 색 · 글자 | 작업공간 루트 `디자인.md` 「확정 규칙」 · 위 필수 규칙 8 |
| 배포 · 버전 · 실기기 | `DEPLOYMENT.md` |
| 화면 부품 · 옛 수용 기준 · 물렸던 것 | hotcha `legacy/features/` (배경 참조, 비권위) |

## 불변식 — 테스트가 지킨다

이름은 테스트 함수 이름과 정확히 같다. 사라지면 `check-project-rules.sh` 규칙 0 이 막는다. 뜻은 hotcha `reference/invariants.md`.

| 무엇 | 테스트 |
| --- | --- |
| 가장 가까운 정류장에서 출발한다 | `가장_가까운_정류장에서_출발한다` |
| 목적지를 지난 정류장은 출발점이 아니다 | `목적지를_지난_정류장은_출발점이_아니다` |
| 정류장을 건너뛰어도 따라잡는다 | `정류장을_하나_건너뛰어도_따라잡는다` |
| 뒤로는 가지 않는다 | `뒤로는_가지_않는다` |
| 알람은 한 번만 울린다 | `N정류장_전에_알람이_한_번만_울린다` |
| 알람 정류장을 놓쳐도 울린다 | `알람_정류장을_건너뛰어도_울린다` |
| 타자마자 울리지 않는다 | `시작부터_N보다_가까우면_바로_울리지_않고_한_정류장_전에_울린다` |
| 기차역 반경 안에서 한 번만 울린다 | `반경_안에_들어오면_한_번만_울린다` |
| 흐린 위치로는 울리지 않는다 | `흐린_위치로는_울리지_않고_거리도_바꾸지_않는다` |
| 반경 두 배 안에서 신호가 끊기면 미리 울린다 | `반경_두_배_안에서_신호가_끊기면_미리_울린다` |
| 멀리서 신호가 끊기면 울리지 않는다 | `멀리서_신호가_끊기면_울리지_않는다` |

## 도메인에서 절대 헷갈리면 안 되는 것

- **도시 코드가 두 벌이다.** 노선은 서울이 `"1"`(앱이 서울 API 를 고르는 값)이고, 정류장 파일은 서울이 `"11"` 이다.
  나머지 도시는 TAGO 코드로 같다. 변환은 `BusDatabase` 한 곳에서만 한다.
- **정류장 ID ≠ 정류장 번호.** ID 는 시스템 값(`SEB122000606`), 번호는 정류장에 적힌 다섯 자리(`23813`)다.
  사용자에게 보여 주는 것은 번호다.
- **순번(seq)으로 빼지 않는다.** API 에 따라 1 부터일 수도 1001 부터일 수도 있다. 남은 정류장 수는 배열의 자리로 센다.
- **기차역은 `BusStopRecord.isTrainStation` 이다.** 정류장 알람과 같은 화면 · 엔진을 쓰고 반경(km) · 위치 추적 · 문구만 다르다.
  공공데이터 역 좌표는 수십 km 틀린 것이 있어 알람 좌표로 쓰지 않는다. 목록은 「어느 역이 있나」 와 「어디쯤」 만 믿는다.
- **노선 알람 ≠ 정류장 알람.** 노선 알람은 버스를 고르고 남은 **정류장 수**로 울린다. 정류장 알람은 정류장만 고르고 **거리**로 울린다.
- **좌표 이름.** `gpsX` 가 경도, `gpsY` 가 위도다.

## 함정 — 어기면 사고

- **API 키** — 서비스 키가 소스 다섯 군데에 박힌 채 공개 저장소에 올라갔다. 키를 읽는 함수가 있었는데도 실제 요청은 하드코딩 값을 썼다.
- **타깃에 딸려 가는 파일** — 프로젝트가 폴더를 통째로 타깃에 넣는다. `test.swift` · `gg.swift` · 더미 데이터가 그대로 출시 빌드에 들어갔다.
- **검색 결과 이동** — 결과 줄의 `NavigationLink` 는 검색이 닫히며 줄이 사라지면 이동하지 못한다. 이동은 `HomeScreen` 이 `SearchDestination` 으로 맡는다.
- **`.alert` 의 버튼** — 파괴 역할 버튼만 두면 시스템이 `Cancel` 을 하나 더 붙인다. 다른 버튼에 `.cancel` 역할을 준다.
- **뷰 안의 `badge(...)`** — 뷰 구조체 안에서 `badge` 라는 함수를 부르면 SwiftUI 의 `.badge` 수식어로 읽힌다.
- **시트 아래의 지도** — 시트가 화면 아래 절반을 덮는다. 보여 줄 점을 지도 중심에 두면 시트에 가린다. 중심을 남쪽으로 내려서 맞춘다.
- **`onReceive($값)` 안에서 뷰모델을 다시 읽지 않는다** — 게시 시점에는 아직 이전 값이다. 넘어온 새 값을 쓴다. 현재 정류장 표시가 한 박자 늦었다.
- **Live Activity** — 데이터 모양이 앱과 위젯에 따로 적혀 있던 때는 한쪽만 바꾸면 컴파일은 되고 잠금 화면만 안 떴다. 지금은 `LiveActivityShared` 한 곳에 있다. 다이내믹 아일랜드 영역을 `EmptyView` 로 두면 아무것도 안 뜬다.
- **내장 DB** — 정류장 파일에는 노선이 없다. 노선 목록은 API 에서 받아 같은 DB 에 넣는다. 같은 정류장이 서울·경기 양쪽 시스템에 따로 올라와 있어 이름+번호로 한 번만 보여 준다.
- **장소 검색** — 한국에서 `MKLocalSearch` 는 정확한 이름에만 반응한다("선릉" → 중국 선전). `MKLocalSearchCompleter` 를 쓴다.
- **지도 핀 선택** — `Map(selection:)` 은 내용이 다시 그려질 때 선택이 다른 핀으로 튄다. 핀을 직접 그리고 탭으로 고른다.
- **증분 빌드는 경고를 숨긴다** — 안 바뀐 파일의 경고는 다시 안 찍힌다. 검증은 처음부터 컴파일한다.
- **API 호출 한도** — 키 하나의 하루 한도를 앱 사용자와 나눠 쓴다. 노선별 정류장을 한꺼번에 긁는 스크립트를 이 키로 돌리지 않는다.
- **AlarmKit 의 `.fixed(Date())`** — 시스템(mobiletimerd)에 닿을 때는 이미 지난 시각이라 `invalidInput` 으로 거절된다. 앱 쪽 `catch` 가 삼켜서 아무 소리 없이 안 울렸다. 실기기 로그에만 남는다("Cannot schedule an alarm with a fixed date in the past"). 조금 뒤 시각으로 건다.
- **MapKit 검색을 연달아 부르면** 조용히 빈 결과(throttled)가 온다. 앱은 역을 고를 때 한 번만 부른다. 맥에서 목록을 훑을 때는 3초 간격을 둔다.
- **worktree 에는 `Secrets.xcconfig` 가 없다** — git 에 없는 파일이라 새 worktree 를 파면 복사해 넣어야 노선 알람이 동작하는 빌드가 된다.

## 현재 상태 (2026-10-15)

- 재설계는 `feat/rebuild-redesign` 에 모여 원격에 올라가 있다 — `develop` 에는 아직 병합되지 않았다(`develop` 은 옛 코드다).
- 탭은 홈 · 이용 기록 · 지도 · 나의 핫챠 넷이다(FR-HOME-01). 설정 · 닉네임 · 이동 거리는 「나의 핫챠」 안에 있다.
- 알람이 울리면 루트(`NavigationView`)가 `AlarmRingingView` 를 전체 화면으로 띄운다. 안내 화면의 시트는 그동안 내려간다.
- 버스 그림은 `BusArt` 가 노선 유형으로 고른다. 클레이 그림(`Assets.xcassets/Clay`)은 `ClayIcon` · `Clay` 로 쓴다. 위젯에는 줄인 사본(216px)을 따로 둔다 — 큰 그림은 Live Activity 에서 안 뜬다.
- 노선 · 정류장 화면은 지도 + 시스템 시트다. 시트는 화면의 92% 까지만 올라간다 — `.large` 는 뒤 화면을 하얗게 바꾼다.
- 가로가 넓으면(`horizontalSizeClass == .regular`) 노선 · 정류장 화면은 시트 대신 지도 왼쪽 패널, 홈은 두 칸이다. `showsSheet` 는 시트든 패널이든 내용을 보여 줄지이고, 시트로 띄우는 것은 좁은 화면에서만이다.
- 저장소가 공개인데 **옛 서비스 키가 git 이력에 남아 있다.** 재발급이 필요하다.
- 실기기에서 확인하지 않은 것은 hotcha `AGENTS.md` "현재 상태"에 모아 둔다.
