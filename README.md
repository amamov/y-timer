# Y-Timer

그래비티 타이머에서 영감을 얻은 iOS 전용 타이머. 프리셋을 한 번 누르거나 시·분·초를 굴려 바로 시작한다.

- 요구 사항: iOS 26.1 이상, Xcode 26 이상
- 타이머 엔진: AlarmKit. 무음 모드와 집중 모드에서도 울리고, 도는 동안 Live Activity 가 잠금 화면·상시표시·다이내믹 아일랜드·스탠바이에 뜬다.

## 기능

| 위치 | 구성 |
|---|---|
| 앱 | 프리셋 6개(분 단위로 편집), 시·분·초 휠로 직접 설정, 알림음 선택, '다시' 버튼 켜기·끄기 |
| 홈 화면 위젯 (소·중·대) | 앱에서 정한 프리셋. 누르면 앱을 열지 않고 시작 |
| 잠금 화면 위젯 | 원형(한 칸)과 직사각형(세 칸). 칸마다 분을 직접 정하고, 잠금 해제 없이 시작 |
| 제어 센터 / 잠금 화면 하단 버튼 | 분을 정해 둔 한 칸짜리 시작 버튼 |
| 액션 버튼·Siri·단축어 | "Y-Timer 타이머 시작". 분은 Siri 가 되묻는다 |

진동 패턴은 AlarmKit 이 설정을 제공하지 않아 iOS 설정(사운드 및 햅틱)을 따른다.

## 폰에 설치

아이폰을 케이블로 연결하고 실행한다. 처음 한 번은 Xcode > Settings > Accounts 에 Apple ID 로 로그인하고, 폰의 개발자 모드를 켠다.

```sh
./scripts/install.sh
```

## TestFlight 에 올리기

```sh
./scripts/testflight.sh
```

빌드 번호는 실행 시각으로 자동으로 붙는다.

## 설정값이 있는 곳

- 번들 ID, App Group, 표시 이름, 만든 사람: `project.yml` 의 `settings.base`. 코드는 Info.plist 로 읽는다(`Shared/AppConfig.swift`).
- 기본 프리셋과 범위: `Shared/AppConfig.swift` 의 `TimerLimits`. App Intents 가 리터럴을 요구하는 곳은 `IntentLiterals` 가 디버그 빌드에서 어긋남을 잡는다.
- 알림음: `swift scripts/make-sounds.swift YTimer/Sounds` 가 소리 파일과 목록(`sounds.json`)을 만든다. 앱은 목록을 읽어 보여 준다.
- 아이콘: `swift scripts/make-icon.swift YTimer/Assets.xcassets/AppIcon.appiconset/AppIcon.png Y`

## 빌드

```sh
brew install xcodegen
xcodegen generate
open YTimer.xcodeproj
```

`project.yml` 이 원본이다. `YTimer.xcodeproj` 는 생성물이므로 직접 고치지 않는다.

## 구조

- `Shared/`: 앱과 위젯이 함께 쓰는 설정, 저장소, 타이머 시작·종료, App Intent
- `YTimer/`: 앱 화면과 알림음
- `YTimerWidget/`: 홈·잠금 화면 위젯, 제어 센터 버튼, Live Activity
- `scripts/`: 설치, TestFlight 업로드, 아이콘·소리 생성
