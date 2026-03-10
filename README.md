# 💘 솔로의 심쿵감지기

MZ세대 대상 AI 관계 분석 모바일 앱 (Flutter + Firebase + GPT-4o-mini)

## 핵심 기능

| 기능 | 가격 | 설명 |
|---|---|---|
| 카카오톡 속마음 분석 | 무료 맛보기 → **990원** | 호감도 점수 + 상세 AI 분석 |
| MBTI 궁합 팩폭 | 무료 + 990원 | 충격적 한 줄 + SNS 공유 |
| 관계 손절 계산기 | **완전 무료** | 20개 항목 체크리스트 |

## 기술 스택

- **Frontend**: Flutter 3.x (iOS/Android 단일 코드베이스)
- **Backend**: Firebase Blaze (Auth, Firestore, Cloud Functions)
- **AI**: OpenAI GPT-4o-mini (건당 약 3~5원)
- **결제**: RevenueCat (Google/Apple IAP 통합)
- **OCR**: Google ML Kit (온디바이스, 무료)

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점 (Firebase + RevenueCat 초기화)
├── router.dart            # go_router (탭 쉘 + 온보딩 리다이렉트)
├── models/
│   ├── analysis_result.dart
│   └── mbti_result.dart
├── screens/
│   ├── main_shell.dart              # BottomNavigationBar 쉘
│   ├── onboarding_screen.dart       # 첫 실행 온보딩 (4페이지)
│   ├── home_screen.dart             # 홈 (3개 기능 카드)
│   ├── kakao_analysis_screen.dart   # 카카오톡 분석 + 페이월 CTA
│   ├── mbti_screen.dart             # MBTI 궁합 팩폭
│   ├── breakup_calculator_screen.dart # 손절 계산기 (20문항)
│   ├── premium_result_screen.dart   # 유료 상세 결과 (그래프, 키워드)
│   ├── history_screen.dart          # 분석 기록
│   ├── paywall_screen.dart          # 1/5/10회 크레딧 결제
│   ├── settings_screen.dart         # 설정 + 크레딧 복원
│   └── privacy_policy_screen.dart   # 개인정보처리방침 + 이용약관
├── services/
│   ├── auth_service.dart      # Firebase 익명 로그인
│   ├── analysis_service.dart  # Cloud Functions 호출
│   ├── credit_service.dart    # 크레딧 실시간 스트림
│   └── payment_service.dart   # RevenueCat IAP
└── widgets/
    └── feature_card.dart

functions/
├── src/index.ts   # analyzeFree / analyzePremium / analyzeMbti / revenuecatWebhook
└── package.json
```

---

## 🖥️ 로컬 테스트 방법

### 방법 1: Flutter 에뮬레이터 (권장)

```bash
# Flutter SDK 설치 (https://flutter.dev/docs/get-started/install)
flutter --version   # 3.x 확인

# Android Studio에서 에뮬레이터 생성 후:
flutter emulators --launch <emulator_id>

# 또는 실제 디바이스 USB 연결 후:
flutter devices     # 디바이스 목록 확인
```

### 방법 2: Flutter Web (빠른 UI 확인용)

```bash
# 파이어베이스 없이 UI만 확인할 때
flutter run -d chrome

# 주의: file_picker, 인앱결제는 웹에서 동작하지 않음
# UI 레이아웃, 애니메이션 확인용으로만 사용
```

### 방법 3: Firebase 에뮬레이터 (백엔드 로컬 테스트)

```bash
# Firebase CLI 설치
npm install -g firebase-tools
firebase login

# 에뮬레이터 실행 (Firestore + Functions + Auth)
firebase emulators:start

# 에뮬레이터 UI: http://localhost:4000
# Functions 로그 실시간 확인 가능
```

### 방법 4: Functions 단독 테스트

```bash
cd functions
npm install
npx ts-node -e "
const { OpenAI } = require('openai');
// .env의 OPENAI_API_KEY로 GPT 응답 확인
"

# 단위 테스트
npx jest
```

---

## 🚀 개발 환경 전체 설정

```bash
# 1. 의존성
flutter pub get
cd functions && npm install && cd ..

# 2. 환경변수
cp .env.example .env
# .env에 아래 값 입력:
# OPENAI_API_KEY=sk-...
# RC_ANDROID_KEY=goog_...
# RC_IOS_KEY=appl_...
# RC_WEBHOOK_SECRET=your_secret

# 3. Firebase 프로젝트 연결
firebase use --add   # Firebase 프로젝트 선택

# 4. Firebase 설정 파일 추가
# android/app/google-services.json
# ios/Runner/GoogleService-Info.plist

# 5. 앱 실행
flutter run --dart-define-from-file=.env
```

---

## 📦 배포

```bash
# Cloud Functions + Firestore 규칙
./deploy.sh functions

# Android AAB (Google Play)
./deploy.sh android

# iOS IPA (App Store)
./deploy.sh ios

# 전체
./deploy.sh all
```

---

## 개발 로드맵

- [x] Phase 0: 프로젝트 구조, 화면 뼈대, 서비스 레이어
- [x] Phase 1: Firebase 연동, Cloud Functions, 상세 분석 결과 화면
- [x] Phase 2: 온보딩, 히스토리, 설정, 개인정보처리방침, 네이티브 설정
- [ ] Phase 3: Firebase 프로젝트 생성, API 키 연결, 에뮬레이터 테스트, 스토어 심사

## 프라이버시

카카오톡 원문은 Cloud Function 메모리에서만 처리하며, 분석 후 즉시 삭제됩니다.
Firestore에는 분석 결과만 저장됩니다.

---
*참고용이며 절대적 판단 기준이 아닙니다.*
