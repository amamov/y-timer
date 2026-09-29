#!/bin/zsh
# USB 나 같은 Wi-Fi 로 연결된 아이폰에 X-Timer 를 빌드해서 설치하고 실행한다.
# 사용법: ./scripts/install.sh
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID=com.amamov.xtimer
BUILD_DIR=build/device

command -v xcodegen >/dev/null || brew install xcodegen
xcodegen generate --quiet

# 시뮬레이터가 아닌 실제 아이폰 하나를 고른다.
JSON=$(mktemp -t xtimer-devices)
trap 'rm -f "$JSON"' EXIT
xcrun devicectl list devices --json-output "$JSON" >/dev/null
DEVICE=""
i=0
while hw=$(plutil -extract "result.devices.$i.hardwareProperties" json -o - "$JSON" 2>/dev/null); do
  if [[ $hw == *"\"reality\":\"physical\""* && $hw == *"\"platform\":\"iOS\""* ]]; then
    DEVICE=$(plutil -extract "result.devices.$i.hardwareProperties.udid" raw "$JSON")
    DEV_MODE=$(plutil -extract "result.devices.$i.deviceProperties.developerModeStatus" raw "$JSON" 2>/dev/null || echo unknown)
    break
  fi
  i=$((i + 1))
done

if [[ -z "$DEVICE" ]]; then
  echo "연결된 아이폰이 없습니다. 케이블로 연결하고 폰에서 '이 컴퓨터 신뢰'를 누른 뒤 다시 실행하세요."
  exit 1
fi
if [[ $DEV_MODE == disabled ]]; then
  echo "폰의 개발자 모드가 꺼져 있습니다. 설정 > 개인정보 보호 및 보안 > 개발자 모드를 켜고, 재시작 후 뜨는 창에서 켬을 누른 뒤 다시 실행하세요."
  exit 1
fi
echo "설치할 기기: $DEVICE"

xcodebuild -project XTimer.xcodeproj -scheme XTimer -configuration Release \
  -destination "id=$DEVICE" -derivedDataPath "$BUILD_DIR" \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration -quiet build \
  || { echo "빌드·서명 실패. Xcode > Settings > Accounts 에 Apple ID 가 로그인되어 있는지 확인하세요."; exit 1; }

APP="$BUILD_DIR/Build/Products/Release-iphoneos/XTimer.app"
xcrun devicectl device install app --device "$DEVICE" "$APP"
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID" || true
echo "설치 완료. 홈 화면을 길게 눌러 X-Timer 위젯을 추가하세요."
