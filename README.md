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
├── main.dart              # 앱 진입점
├── router.dart            # go_router 라우팅
├── models/
│   ├── analysis_result.dart  # 카톡 분석 결과 모델
│   └── mbti_result.dart      # MBTI 궁합 결과 모델
├── screens/
│   ├── home_screen.dart           # 홈 (3개 기능 카드)
│   ├── kakao_analysis_screen.dart # 카카오톡 분석
│   ├── mbti_screen.dart           # MBTI 궁합
│   ├── breakup_calculator_screen.dart # 손절 계산기
│   ├── paywall_screen.dart        # 결제 페이월
│   └── result_screen.dart         # 분석 결과
├── services/
│   ├── gpt_service.dart    # OpenAI API 연동
│   └── payment_service.dart # RevenueCat 결제
└── widgets/
    └── feature_card.dart   # 홈 기능 카드 위젯
```

## 개발 환경 설정

```bash
# 1. Flutter 설치 후
flutter pub get

# 2. 환경변수 설정
cp .env.example .env
# .env 파일에 API 키 입력

# 3. Firebase 설정
# android/app/google-services.json 추가
# ios/Runner/GoogleService-Info.plist 추가

# 4. 실행
flutter run --dart-define-from-file=.env
```

## 개발 로드맵

- [x] Phase 0: 프로젝트 구조, 화면 뼈대, 서비스 레이어
- [ ] Phase 1: Firebase 연동, 카카오톡 분석 MVP
- [ ] Phase 2: MBTI 캐싱, 인앱결제 연동, UI 폴리싱
- [ ] Phase 3: 테스트, 스토어 심사, 출시

## 프라이버시

카카오톡 원문은 Cloud Function 메모리에서만 처리하며, 분석 후 즉시 삭제됩니다.
Firestore에는 분석 결과만 저장됩니다.

---
*참고용이며 절대적 판단 기준이 아닙니다.*
