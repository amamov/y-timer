# X-Timer

그래비티 타이머에서 영감을 얻은 iOS 전용 프리셋 타이머. 5·10·15·30·60·100분을 한 번 눌러 바로 시작한다.

- 요구 사항: iOS 26.1 이상, Xcode 26 이상
- 타이머 엔진: AlarmKit. 무음 모드에서도 끝나면 알람이 울리고, 도는 동안 Live Activity 가 잠금 화면·상시표시·다이내믹 아일랜드·스탠바이에 뜬다.

## 시작하는 곳

| 위치 | 구성 |
|---|---|
| 홈 화면 위젯 (소·중·대) | 프리셋 버튼, 남은 시간·경과·종료 시각, 끝내기 |
| 잠금 화면 위젯 (원형·직사각형·한 줄) | 남은 시간과 진행 |
| 제어 센터 / 잠금 화면 하단 버튼 | 시간을 골라 둔 한 칸짜리 시작 버튼 |
| 액션 버튼·Siri·단축어 | "X-Timer 10분 시작" |

## 폰에 설치

아이폰을 케이블로 연결하고 한 줄만 실행한다.

```sh
./scripts/install.sh
```

처음 한 번은 Xcode > Settings > Accounts 에 Apple ID 로 로그인되어 있어야 한다. 폰에서는 설정 > 개인정보 보호 및 보안 > 개발자 모드를 켠다.

## TestFlight 에 올리기

```sh
./scripts/testflight.sh
```

빌드 번호는 실행 시각으로 자동으로 붙는다. 처음 한 번은 App Store Connect 에 번들 ID `com.amamov.xtimer` 로 앱을 등록해 두어야 한다.

## 빌드

```sh
brew install xcodegen
xcodegen generate
open XTimer.xcodeproj
```

`project.yml` 이 원본이다. `XTimer.xcodeproj` 는 생성물이므로 직접 고치지 않는다.

## 구조

- `Shared/`: 앱과 위젯이 함께 쓰는 프리셋, 타이머 시작·종료, App Intent
- `XTimer/`: 앱 화면
- `XTimerWidget/`: 홈·잠금 화면 위젯, 제어 센터 버튼, Live Activity
