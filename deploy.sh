#!/bin/bash
# 솔로의 심쿵감지기 배포 스크립트
# 사용법: ./deploy.sh [functions|android|ios|all]

set -euo pipefail

TARGET=${1:-all}
echo "🚀 배포 시작: $TARGET"

# ── Cloud Functions ──────────────────────────────────────────────────────────
deploy_functions() {
  echo "📦 Cloud Functions 배포 중..."
  cd functions
  npm install
  npm run build
  cd ..
  firebase deploy --only functions
  echo "✅ Cloud Functions 배포 완료"
}

# ── Android ──────────────────────────────────────────────────────────────────
build_android() {
  echo "🤖 Android 빌드 중..."
  flutter build appbundle \
    --release \
    --dart-define-from-file=.env \
    --build-name=1.0.0 \
    --build-number=1
  echo "✅ Android AAB: build/app/outputs/bundle/release/app-release.aab"
  echo "→ Google Play Console에 업로드하세요"
}

# ── iOS ───────────────────────────────────────────────────────────────────────
build_ios() {
  echo "🍎 iOS 빌드 중..."
  flutter build ipa \
    --release \
    --dart-define-from-file=.env \
    --export-options-plist=ios/ExportOptions.plist
  echo "✅ iOS IPA: build/ios/ipa/"
  echo "→ Xcode Organizer 또는 altool로 App Store Connect에 업로드하세요"
}

# ── Firestore 규칙 ────────────────────────────────────────────────────────────
deploy_rules() {
  echo "🔒 Firestore 보안 규칙 배포 중..."
  firebase deploy --only firestore
  echo "✅ Firestore 규칙 배포 완료"
}

# ── 실행 ─────────────────────────────────────────────────────────────────────
case $TARGET in
  functions) deploy_functions ;;
  android)   build_android ;;
  ios)       build_ios ;;
  rules)     deploy_rules ;;
  all)
    deploy_functions
    deploy_rules
    build_android
    build_ios
    ;;
  *)
    echo "사용법: ./deploy.sh [functions|android|ios|rules|all]"
    exit 1
    ;;
esac

echo ""
echo "🎉 완료!"
