#!/bin/zsh
# 빌드해서 TestFlight 에 올린다. 몇 분 뒤 폰의 TestFlight 앱에 새 버전이 뜬다.
# 사용법: ./scripts/testflight.sh
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_DIR=build/testflight
BUILD_NUMBER=$(date +%Y%m%d%H%M)

command -v xcodegen >/dev/null || brew install xcodegen
xcodegen generate --quiet
rm -rf "$BUILD_DIR"

echo "빌드 번호 $BUILD_NUMBER 아카이브 중"
xcodebuild archive -project XTimer.xcodeproj -scheme XTimer -configuration Release \
  -destination "generic/platform=iOS" -archivePath "$BUILD_DIR/XTimer.xcarchive" \
  -allowProvisioningUpdates -quiet CURRENT_PROJECT_VERSION="$BUILD_NUMBER"

echo "App Store Connect 로 업로드 중"
xcodebuild -exportArchive -archivePath "$BUILD_DIR/XTimer.xcarchive" \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath "$BUILD_DIR/export" \
  -allowProvisioningUpdates

echo "업로드 완료. App Store Connect 처리가 끝나면 폰의 TestFlight 앱에 뜹니다."
