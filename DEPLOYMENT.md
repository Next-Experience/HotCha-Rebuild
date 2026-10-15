# 배포 가이드

실기기 설치부터 TestFlight · 심사 제출까지의 순서다. 프로젝트 파일(`HotCha/HotCha.xcodeproj`)은 손으로 관리하고 git 에 들어 있다.

**배포로 나가는 빌드는 Release다.** 스킴의 Archive 액션이 Release로 고정돼 있다.

---

## 0. 미리 준비할 것

| 항목 | 값 |
|---|---|
| 팀 | Apple Developer Program 유료 멤버십이 활성 상태여야 한다 |
| 앱 번들 ID | `com.team.blueberrySmoothie` |
| Live Activity 번들 ID | `com.team.blueberrySmoothie.HotLive` |
| 최소 iOS | 26.1 (시스템 알람 — 허브 `requirements.md` FR-PLAT-01) |
| 마케팅 버전 | `project.pbxproj`의 `MARKETING_VERSION` (현재 `2.0.0`) — 아래 규칙 |
| 빌드 번호 | `project.pbxproj`의 `CURRENT_PROJECT_VERSION`. Xcode Cloud에서는 `CI_BUILD_NUMBER`가 들어간다 |
| 공공데이터 서비스 키 | `HotCha/Config/Secrets.xcconfig`의 `API_KEY` (로컬) · Xcode Cloud 비밀 환경 변수 `HOTCHA_API_KEY` |
| 출시 상태 | `[미정]` — 확인하지 않았다 |

### 버전 번호 규칙

**마케팅 버전은 그 판을 심사에 낸 직후 patch를 하나 올린다.** 프로젝트의 값은 "지금 내는 판"이 아니라
"지금 작업 중인 다음 판"이다 — 2.0.0을 심사에 냈으면 곧바로 2.0.1로 올리고, 그 뒤 병합되는 PR이 2.0.1의 내용이 된다.
심사 중인 판에 다음 작업의 빌드가 섞이지 않고, 승인된 버전으로는 더 올릴 수 없어서(ITMS-90062) 미리 올려 둔다.
minor·major는 사용자가 정할 때만 올린다.

**앱과 Live Activity 익스텐션의 두 값은 언제나 같다.** 두 타깃의 모든 구성(Debug · Release)에 같은 값을 적는다 —
어긋나면 업로드가 거부된다. 고친 뒤 확인한다:

```bash
grep -E 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' HotCha/HotCha.xcodeproj/project.pbxproj | sort | uniq -c   # 각각 한 가지 값만
```

**빌드 번호**는 같은 마케팅 버전 안에서 엄격히 증가해야 하고(중복은 ITMS-90189, 낮으면 ITMS-90188) 만료·삭제한 번호도 재사용할 수 없다.
Xcode Cloud로 올리면 `ci_scripts/ci_post_clone.sh`가 `CI_BUILD_NUMBER`를 넣으므로 사람이 만지지 않는다.
손으로 올릴 때는 TestFlight의 마지막 번호보다 크게, 앱 · 위젯 모든 구성을 함께 올린다.

---

## 1. 실기기 설치 (개발 확인용)

시스템 알람 · 백그라운드 위치 · 잠금 화면은 시뮬레이터에서 확인되지 않는다 — 실기기에서 본다.

```bash
xcodebuild build -project HotCha/HotCha.xcodeproj -scheme HotCha -destination "id=<기기 UDID>" \
  -derivedDataPath .build/device -allowProvisioningUpdates
xcrun devicectl device install app --device <기기 UDID> .build/device/Build/Products/Debug-iphoneos/HotCha.app   # 설치만 실패하면 이것만 다시
xcrun devicectl device process launch --device <기기 UDID> com.team.blueberrySmoothie
```

알람이 안 울리면 기기 로그에서 `mobiletimerd` 의 `AlarmKitCore` 줄을 본다 — 시스템이 알람을 거절한 이유가 거기에만 남는다.

```bash
sudo /usr/bin/log collect --device-udid <기기 UDID> --last 3h --output hotcha.logarchive
```

---

## 2. Xcode Cloud

워크플로는 아직 만들지 않았다 `[미정]`. 만들 때:

1. App Store Connect → 앱 → Xcode Cloud → 워크플로 만들기. 스킴 `HotCha`.
2. 환경 변수에 `HOTCHA_API_KEY`(비밀)를 넣는다. 없으면 `ci_post_clone.sh`가 아카이브를 멈춘다 — 노선 알람이 동작하지 않는 빌드가 나가지 않게.
3. Xcode 버전은 "최신 릴리스"다. 러너가 메이저를 올리면 한 명이 새 Xcode로 `./scripts/verify.sh`를 통과시킨 뒤 `.xcode-version`을 올리는 PR을 낸다.
4. PR 검증 워크플로를 두면 `develop`으로 가는 PR마다 빌드를 돌린다. 계산 시간은 월 25시간을 팀이 나눠 쓴다.

---

## 3. 손으로 올리기 (Xcode Cloud 없이)

```bash
xcodebuild -project HotCha/HotCha.xcodeproj -scheme HotCha -configuration Release \
  -destination generic/platform=iOS -archivePath .build/release/HotCha.xcarchive -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath .build/release/HotCha.xcarchive \
  -exportOptionsPlist <ExportOptions.plist: destination upload · method app-store-connect · signingStyle automatic> \
  -exportPath .build/release -allowProvisioningUpdates
```

로컬 키체인에 배포 인증서가 없어도 `-allowProvisioningUpdates`가 클라우드 서명으로 받는다. 빼면 「No Accounts」로 실패한다.

---

## 4. 첫 빌드에서 확인할 것

TestFlight로 받은 빌드에서 사람이 직접 본다. 검증(`verify.sh`)은 이것들을 보지 못한다.

- [ ] 첫 실행 안내 뒤 위치 「항상 허용」과 시스템 알람 권한을 받는다 (FR-ONBOARD-02)
- [ ] 노선 알람을 시작하고 화면을 끈 채 알림 정류장에서 시스템 알람이 울린다 (FR-ROUTE-05 · FR-ALARM-02)
- [ ] 무음 모드에서도 울린다 (FR-ALARM-02)
- [ ] 잠금 화면 · 다이내믹 아일랜드에 단계가 뜨고 안내를 끝내면 사라진다 (FR-LIVE-01)
- [ ] 개발자 버스 9999번이 검색에 나오지 않는다 — 출시 빌드에는 없다 (FR-DEV-01)

심사 제출 때의 릴리스 노트와 제출 직후 버전 올리기는 `.claude/skills/ios-release/SKILL.md`를 따른다.
