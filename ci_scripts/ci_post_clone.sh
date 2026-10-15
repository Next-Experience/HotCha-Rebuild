#!/bin/sh
# Xcode Cloud가 저장소를 clone한 직후 이 스크립트를 자동 실행한다.
# Secrets.xcconfig 는 git 에 없으므로 빈 러너에서 빌드하려면 여기서 만든다.
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

# 공공데이터 서비스 키는 Xcode Cloud 워크플로의 비밀 환경 변수 HOTCHA_API_KEY 로 받는다.
# 키가 없어도 빌드는 되지만 노선 알람이 정류장 목록을 못 받는다 — 배포로 나가는 아카이브에서는 멈춘다.
if [ -n "$HOTCHA_API_KEY" ]; then
  printf 'API_KEY = %s\n' "$HOTCHA_API_KEY" > HotCha/Config/Secrets.xcconfig
elif [ "$CI_XCODEBUILD_ACTION" = "archive" ]; then
  echo "HOTCHA_API_KEY 가 없다 — 키 없이 아카이브하면 노선 알람이 동작하지 않는 빌드가 나간다" >&2
  exit 1
else
  echo "HOTCHA_API_KEY 없음 — 키 없이 빌드한다(검증용)"
fi

# TestFlight는 같은 (버전, 빌드 번호) 조합을 두 번 받지 않는다.
# Xcode Cloud가 빌드마다 올려주는 CI_BUILD_NUMBER를 빌드 번호로 쓴다. 앱과 위젯이 같은 값이어야 한다.
if [ -n "$CI_BUILD_NUMBER" ]; then
  /usr/bin/sed -i '' \
    "s/CURRENT_PROJECT_VERSION = [0-9.]*;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/" \
    HotCha/HotCha.xcodeproj/project.pbxproj
fi
