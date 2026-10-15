# 🚌 핫챠

> SwiftUI 기반 iOS 애플리케이션  
> 버스 하차 알람 서비스

---

## 📂 프로젝트 구조

```
HotCha/
├── Config/                 # xcconfig (Secrets.xcconfig 는 git 에 올리지 않음)
├── HotCha/
│   ├── App/                # 앱 진입점
│   ├── Core/               # 화면과 무관한 기능
│   │   ├── Alarm/          #   노선 알람 엔진, 알람 소리·알림 출력
│   │   ├── Location/       #   위치 추적
│   │   ├── LiveActivity/   #   Live Activity 시작·갱신
│   │   └── Notification/ Sound/ Haptic/
│   ├── Data/
│   │   ├── Local/          #   내장 DB(BusData.sqlite) 조회
│   │   ├── Models/         #   SwiftData 모델, 정류장 모델
│   │   └── Network/        #   노선별 정류장 목록 API (서울 / TAGO)
│   ├── Features/           # 화면 단위
│   │   ├── Main/ Search/ AlarmSetting/ AlarmEnd/
│   │   ├── StopAlarm/      #   정류장을 지도에서 골라 거리로 알람
│   │   └── UsageHistory/ Setting/ OnBoarding/ Splash/
│   ├── Shared/             # 폰트, 확장, 유틸
│   └── Resources/          # 에셋, 알람 소리, BusData.sqlite
├── HotchaLive/             # Live Activity 위젯 익스텐션
HotChaKit/                  # 화면 없이 테스트하는 알람 규칙 (Swift 패키지)
Tools/
└── build_bus_db.py         # BusData.sqlite 생성 스크립트
scripts/
├── verify.sh               # 검증 (규칙 · 린트 · 테스트 · 빌드 · 경고 0)
└── check-project-rules.sh  # 이 저장소 전용 규칙
```

## 🔑 처음 받았을 때

1. `HotCha/Config/Secrets.xcconfig.example` 을 `Secrets.xcconfig` 로 복사합니다.
2. 공공데이터포털에서 받은 **인코딩** 서비스 키를 `API_KEY` 에 넣습니다.
   - 국토교통부_(TAGO)_버스노선정보
   - 서울특별시_노선정보조회 서비스

키가 없어도 빌드와 검색(버스·정류장·장소), 정류장 알람은 동작합니다.
노선의 정류장 목록을 불러오는 노선 알람만 키가 필요합니다.

## 🗂 버스 데이터

검색은 앱에 내장된 `BusData.sqlite` 에서 합니다. (네트워크·API 키 불필요)

| 테이블 | 내용 | 출처 |
|---|---|---|
| `stops` | 전국 정류장 이름·좌표·정류장 번호 | 공공데이터포털 「국토교통부_전국 버스정류장 위치정보」 CSV |
| `routes` | 전국 노선 번호·기점·종점·유형 | 서울 노선 API + TAGO 버스노선정보 API |

데이터를 새로 만들 때:

```bash
HOTCHA_API_KEY=<인코딩 키> python3 Tools/build_bus_db.py <정류장.csv>
```

노선별 정류장 순서는 DB 에 넣지 않고, 알람을 맞출 때 API 로 한 번 조회합니다.

---
## ✅ 검증

검증 명령은 **하나**다. 사람·AI 에이전트·Git Hook 이 모두 이것을 쓴다.

```bash
git config core.hooksPath .githooks   # 클론마다 한 번
./scripts/verify.sh
```

알람 규칙만 빠르게 보려면 (시뮬레이터 불필요, 초 단위):

```bash
cd HotChaKit && swift test
```

작업 순서와 규칙은 [AGENTS.md](AGENTS.md) 에 있다.

---
# 📌 개발 규칙

## 1️⃣ 브랜치 전략
    - main : 배포 버전
    - develop : 통합 브랜치 (작업 브랜치 → PR → 머지. 직접 커밋·푸시하지 않는다)
    - feature/xxx : 새로운 기능 개발 (feature/login-ui)
    - fix/xxx : 버그 수정 (fix/crash-issue)

## 2️⃣ 커밋 컨벤션
    - feat: : 새로운 기능 추가
    - fix: : 버그 수정
    - refactor: : 코드 리팩토링
    - chore: : 빌드 설정 변경, 패키지 관리
    - docs: : 문서 수정 (README 등)
    - style: : 코드 스타일 변경 (세미콜론, 포맷팅 등)
    
## 3️⃣ 코드 컨벤션 (SwiftLint — `.swiftlint.yml`)
    - 네이밍 컨벤션: CamelCase 사용
    - 들여쓰기: 4 spaces
    - @StateObject 사용 시 private 접근 제어자 적용
    - ObservableObject는 final class로 선언
    - 뷰 파일명은 ScreenNameView.swift 형태로 작성 (예: HomeView.swift)
    - 색상과 폰트는 각각 에셋과 커스텀폰트만 사용
    - API 키는 소스에 적지 않고 `BusAPI.serviceKey` 로만 읽기

