# 핫챠 (HotCha) — 작업 규칙

버스에서 **내릴 정류장을 놓치지 않게** 알려 주는 iOS 앱. SwiftUI · iOS 26.1+ (AlarmKit, 결정 0005).

> 제품이 무엇이고 무엇을 만들기로 했는지는 문서 허브 `hotcha/` 에 있다 (작업공간에서 이 저장소의 형제 폴더).
> 어느 프로젝트에나 통하는 개발 규약은 `playbook/` 에 있다.

---

## 루프 — 요청 하나가 지나가는 여섯 칸

```
0 브랜치 → 1 문서 → 2 개발 → 3 검증 → 4 커밋 → 5 PR
```

| | 칸 | 통과 조건 |
| --- | --- | --- |
| 0 | **브랜치** | `develop` 최신화 → 작업 브랜치. `develop`·`main` 위에서 코드를 고치지 않는다 |
| 1 | **문서** | **동작·계약이 바뀌면** 허브(`hotcha/`)의 문서를 **먼저** 고친다 |
| 2 | **개발** | 1에서 확정한 것만 만든다. 알람 규칙이면 🔴 → 🟢 → 🔵 |
| 3 | **검증** | `./scripts/verify.sh` 가 초록이다. **부분 검증은 통과가 아니다** |
| 4 | **커밋** | `type(scope): 요약`. 검증이 초록일 때만 |
| 5 | **PR** | 푸시하고 `develop` 으로 PR을 연다. **여기서 멈춘다** — 병합은 사람이 누른다 |

**칸을 건너뛰면 건너뛴다고 한 줄 말한다.** 조용히 건너뛰는 것이 이 루프가 막으려는 것이다.

**1번이 면제되는 경우** — 순수 리팩터링(동작 불변) · 오타 · 포맷 · 빌드 설정 · 테스트 추가.
면제할 때는 "동작이 안 바뀌어 문서는 그대로 둡니다" 처럼 **말로 한다.**

**통합 브랜치는 `develop` 이다.** `main` 은 2025-02 의 README 커밋에 머물러 있고 코드가 없다.
브랜치는 `develop` 에서 따고 PR 도 `develop` 으로 연다.

### 무엇이 이 루프를 강제하나

| 겹 | 무엇을 잡나 | 어디 |
| --- | --- | --- |
| 주입 | 매 요청에 루프와 현재 브랜치·미커밋 상태 | `.claude/hooks/loop-context.sh` |
| 우회 차단 | `--no-verify` · `develop`·`main` 직접 푸시 | `.claude/hooks/loop-guard.sh` |
| 실제 게이트 | 통합 브랜치 위 커밋 · **검증 안 돈 커밋** · `CLAUDE.md`≠`AGENTS.md` | `.githooks/pre-commit` |
| 커밋 기록 | AI 공동 작성자 트레일러를 지운다 | `.githooks/commit-msg` |

**실제 차단은 git 훅이 한다.** 에이전트 훅은 명령 문자열을 파싱해야 해서 우회가 쉽고, 사람이 직접
커밋할 땐 아예 안 걸린다.

**설치 — 클론마다 한 번.** 안 하면 `.githooks/` 의 훅이 하나도 안 돈다.

```bash
git config core.hooksPath .githooks
```

**검증 스탬프** — 검증이 **건너뛴 검사 없이 전부** 통과하면 `.claude/.verify-stamp` 에
`sha256(HEAD + git diff HEAD)` 를 쓴다. 검증 뒤에 한 글자라도 고치면 스탬프가 어긋나 커밋이 막힌다.
`--quick` 과 건너뛴 검사가 있는 실행은 스탬프를 **쓰지 않는다.**
**새 파일은 `git add` 를 먼저 한다** — 추적되지 않는 파일은 `git diff HEAD` 에 안 잡혀, 검증 뒤에
추가하면 스탬프가 어긋난다.

빠져나가는 문: `LOOP_ALLOW_MAIN=1`(통합 브랜치 위 커밋) · `LOOP_SKIP_VERIFY=1`(검증 스탬프).
둘 다 훅이 경고를 찍는다. 썼으면 무엇이 확인되지 않았는지 보고에 적는다.

---

## 검증 — 완료 전에 반드시

```bash
./scripts/verify.sh           # 전체. 완료 판정은 이것만
./scripts/verify.sh --quick   # 앱 빌드 제외. 반복 작업 중에
cd HotChaKit && swift test    # 알람 규칙만. 초 단위
```

| 단계 | 내용 | 실패하면 |
| --- | --- | --- |
| 프로젝트 규칙 | 목록은 `./scripts/check-project-rules.sh --list` | 차단 |
| 코드 포맷 | `swift format lint` (새 코드가 모이는 폴더만) | 경고만 |
| SwiftLint | `--strict`. 예전 코드가 대량으로 어기는 모양 규칙은 꺼 둠 | 차단 |
| **HotChaKit** | `swift test` — 알람 규칙의 방어선. 0건이면 실패 | 차단 |
| iOS 빌드 | 앱 + Live Activity 익스텐션, 처음부터 컴파일 | 차단 |
| **빌드 경고 0** | 컴파일러 경고를 직접 센다 | 차단 |

**이 검증이 보지 못하는 것.** 앱 타깃에는 테스트가 없다. 화면, 위치 추적, 알림, Live Activity 는
**빌드가 되는지까지만** 확인된다. 화면이나 알람 동작을 고쳤으면 시뮬레이터에서 직접 돌려 보고,
못 본 항목은 못 봤다고 보고에 적는다.

> **규칙 통과 ≠ 올바름.** 프로젝트 규칙은 grep 이다. 올바름은 테스트와 눈으로만 확인된다.

---

## 구조

```
HotCha-Rebuild/
├── HotChaKit/                 # 화면 없이 테스트하는 규칙 (Swift 패키지)
│   ├── Sources/HotChaKit/     #   RouteTracker(노선 알람 규칙) · GeoPoint
│   └── Tests/                 #   알람 규칙 테스트
├── HotCha/
│   ├── HotCha.xcodeproj       # 손으로 관리한다. 폴더는 통째로 타깃에 들어간다
│   ├── Config/                # HotCha.xcconfig · Secrets.xcconfig(git 제외)
│   ├── HotCha/
│   │   ├── App/               # 앱 진입점
│   │   ├── Core/              # 알람 엔진 · 위치 · Live Activity · 알림 · 소리 · 햅틱
│   │   ├── Data/              # Local(내장 DB) · Models(SwiftData) · Network(API)
│   │   ├── Features/          # 화면 단위
│   │   ├── Shared/            # 폰트 · 확장 · 유틸
│   │   └── Resources/         # 에셋 · 알람 소리 · BusData.sqlite
│   ├── HotchaLive/            # Live Activity · 다이내믹 아일랜드 화면 (위젯 익스텐션)
│   └── LiveActivityShared/    # Live Activity 데이터 모양. 앱과 위젯이 함께 컴파일한다
├── Tools/build_bus_db.py      # BusData.sqlite 생성
└── scripts/                   # verify.sh · check-project-rules.sh
```

**의존 방향**: `Features → Core → HotChaKit`, `Features → Data`. `HotChaKit` 은 아무것도 모른다
(SwiftUI·CoreLocation·네트워크를 가져오지 않는다).

**진실이 사는 곳**

| 무엇 | 어디 |
| --- | --- |
| 노선 알람이 언제 울리나 | `HotChaKit/Sources/HotChaKit/RouteTracker.swift` |
| 알람을 어떻게 울리나 | `Core/Alarm/AlarmRinger.swift` — AlarmKit 시스템 알람 하나. 로컬 알림 · 앱 소리는 쓰지 않는다 |
| 버스·정류장 검색 | `Data/Local/BusDatabase.swift` → `Resources/BusData.sqlite` |
| 노선의 정류장 순서 | API. `Data/Network/BusAPI.swift` 가 서울/지방을 가른다 |
| 즐겨찾기·이용 기록 | SwiftData (`Data/Models/`) |
| 진행 중인 안내 | `RouteAlarmSession`(버스) · `StopAlarmViewModel`(정류장). 탭 전체가 하나씩 나눠 쓴다 |
| Live Activity 데이터 모양 | `HotCha/LiveActivityShared/HotChaActivityAttributes.swift` |
| 안내 단계와 문구(홈 배너 · 잠금 화면 · 시트) | `HotCha/LiveActivityShared/HotChaGuidance.swift` |

---

## 반드시 지킬 것

1. **API 키를 소스에 적지 않는다.** `Config/Secrets.xcconfig` 에 두고 `BusAPI.serviceKey` 로만 읽는다.
2. **알람 규칙은 `HotChaKit` 에서만 고친다.** 화면 쪽(`NearestBusViewModel`)은 결과를 화면·알림으로 옮기기만 한다.
   규칙을 바꿀 땐 실패하는 테스트를 먼저 쓴다.
3. **검색은 내장 DB 에서만 한다.** 검색을 위해 네트워크를 부르지 않는다. 장소 검색(MapKit)만 예외다.
4. **화면은 시스템 기본 컴포넌트로 만든다.** `List` · `Form` · `.sheet` · `.alert` · `.searchable` · `Picker` · 시스템 글꼴.
   색은 강조색 `Color("mainpurple")` 하나와 시스템 색(`.primary` · `.secondary`)만 쓴다. 어두운 고정 배경을 만들지 않는다.
   바탕은 `HotChaContentBackground` 다. 디자인 규칙은 작업공간 루트 `디자인.md` 의 「확정 규칙」 절에 있다.
   **모서리 반경은 `HotChaRadius.card`(12) · `.tile`(8) · `.badge`(4) 만 쓴다.** 숫자를 직접 적으면 규칙 10 이 막는다.
   배너·카드의 바탕은 무늬 없는 `mainpurple` 단색이다. 예외는 안내가 없을 때의 홈 배너 하나 — 흰 바탕이다.
5. **`ObservableObject` 안에서 `@EnvironmentObject` 를 쓰지 않는다.** 뷰가 아니라서 읽는 순간 죽는다.
6. **실험용 화면·더미 데이터를 앱 폴더에 두지 않는다.** 폴더가 통째로 타깃에 들어가 출시 빌드에 실린다.
7. **안내는 한 번에 하나다.** 버스 안내를 시작하면 정류장 안내는 끝나고, 버스 안내 중에는 정류장 안내를 시작할 수 없다.

---

## 불변식 — 테스트가 지킨다

이름은 테스트 함수 이름과 정확히 같다. 사라지면 `check-project-rules.sh` 규칙 0 이 막는다.

| 무엇 | 테스트 |
| --- | --- |
| 가장 가까운 정류장에서 출발한다 | `가장_가까운_정류장에서_출발한다` |
| 목적지를 지난 정류장은 출발점이 아니다 | `목적지를_지난_정류장은_출발점이_아니다` |
| 정류장을 건너뛰어도 따라잡는다 | `정류장을_하나_건너뛰어도_따라잡는다` |
| 뒤로는 가지 않는다 | `뒤로는_가지_않는다` |
| 알람은 한 번만 울린다 | `N정류장_전에_알람이_한_번만_울린다` |
| 알람 정류장을 놓쳐도 울린다 | `알람_정류장을_건너뛰어도_울린다` |
| 타자마자 울리지 않는다 | `시작부터_N보다_가까우면_바로_울리지_않고_한_정류장_전에_울린다` |

---

## 도메인에서 절대 헷갈리면 안 되는 것

- **도시 코드가 두 벌이다.** 노선은 서울이 `"1"`(앱이 서울 API 를 고르는 값)이고, 정류장 파일은 서울이 `"11"` 이다.
  나머지 도시는 TAGO 코드로 같다. 변환은 `BusDatabase` 한 곳에서만 한다.
- **정류장 ID ≠ 정류장 번호.** ID 는 시스템 값(`SEB122000606`), 번호는 정류장에 적힌 다섯 자리(`23813`)다.
  사용자에게 보여 주는 것은 번호다.
- **순번(seq)으로 빼지 않는다.** API 에 따라 1 부터일 수도 1001 부터일 수도 있다. 남은 정류장 수는 배열의 자리로 센다.
- **노선 알람 ≠ 정류장 알람.** 노선 알람은 버스를 고르고 남은 **정류장 수**로 울린다. 정류장 알람은 정류장만 고르고 **거리**로 울린다.
- **좌표 이름.** `gpsX` 가 경도, `gpsY` 가 위도다.

---

## 함정 — 실제로 겪은 것

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

---

## 커밋

`type(scope): 요약` (Conventional Commits). 한국어로 쓴다. AI 도구를 `Co-Authored-By` 에 넣지 않는다
— `commit-msg` 훅이 지운다. 전체 규칙: `playbook/git-and-commits.md`.

---

## 현재 상태 (2026-10-14)

- `refactor/offline-bus-data` 브랜치. `82082a1` 위에 화면 재설계가 **커밋되지 않은 채** 쌓여 있다.
- 탭은 홈 · 이용 기록 · 나의 핫챠 · 검색 넷이다. 검색 탭은 화면이 아니라 홈 위쪽 검색창을 여는 버튼이다.
- 설정은 「나의 핫챠」 안에 있다. 거기에 닉네임(`NicknameGenerator`)과 이동 거리·시간(`JourneyLog`)도 있다.
- 알람이 울리면 루트(`NavigationView`)가 `AlarmRingingView` 를 전체 화면으로 띄운다. 안내 화면의 시트는 그동안 내려간다. 개발자 메뉴는 「나의 핫챠」의 버전을 다섯 번 누르면 열린다.
- 버스 그림은 `BusArt` 가 노선 유형으로 고른다. 클레이 그림(`Assets.xcassets/Clay`)은 `ClayIcon` · `Clay` 로 쓴다. 위젯에는 줄인 사본(216px)을 따로 둔다 — 큰 그림은 Live Activity 에서 안 뜬다.
- 노선 화면 · 정류장 화면은 지도 + 시스템 시트다. 노선 안내 중에는 지도가 내 위치를 따라가고 시트는 절반 높이로 열린다. 시트는 화면의 92% 까지만 올라간다 — `.large` 는 뒤 화면을 하얗게 바꾼다. 옛 어두운 화면(`AlarmSetting` · `AlarmEnd` · 옛 `MainView`)은 지웠다.
- 저장소가 공개인데 **옛 서비스 키가 git 이력에 남아 있다.** 재발급이 필요하다.
- 실기기에서 확인하지 않은 것: 백그라운드 위치 추적 · 잠금 화면 Live Activity · 소리와 진동.
- 시뮬레이터에서 확인하지 않은 것: 온보딩 · 스플래시의 새 바탕 · 즐겨찾기 저장 흐름 · 정류장 안내 중의 홈 배너.
- GitHub Actions 는 커밋 위생 검사만 있다. 빌드 CI 는 없다.
