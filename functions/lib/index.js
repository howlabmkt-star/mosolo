"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.revenuecatWebhook = exports.confirmTossPayment = exports.analyzeSaju = exports.analyzeMbtiSaju = exports.analyzeMbti = exports.analyzePremium = exports.analyzeFree = void 0;
const functions = __importStar(require("firebase-functions/v2/https"));
const admin = __importStar(require("firebase-admin"));
const generative_ai_1 = require("@google/generative-ai");
admin.initializeApp();
const db = admin.firestore();
// Gemini 클라이언트 (API 키는 Cloud Functions 환경변수에만 저장 - 클라이언트에 절대 노출 안 됨)
const genAI = new generative_ai_1.GoogleGenerativeAI(process.env.GEMINI_API_KEY);
// ─── 헬퍼 ───────────────────────────────────────────────────────────────────
async function getUserCredits(uid) {
    var _a, _b;
    const doc = await db.collection("users").doc(uid).get();
    return ((_b = (_a = doc.data()) === null || _a === void 0 ? void 0 : _a.credits) !== null && _b !== void 0 ? _b : 0);
}
async function deductCredit(uid) {
    const ref = db.collection("users").doc(uid);
    await db.runTransaction(async (tx) => {
        var _a, _b;
        const doc = await tx.get(ref);
        const credits = ((_b = (_a = doc.data()) === null || _a === void 0 ? void 0 : _a.credits) !== null && _b !== void 0 ? _b : 0);
        if (credits <= 0)
            throw new Error("크레딧이 부족합니다");
        tx.update(ref, { credits: credits - 1 });
    });
}
async function callGemini(systemPrompt, userPrompt, maxTokens = 2000) {
    const model = genAI.getGenerativeModel({
        model: "gemini-2.0-flash",
        systemInstruction: systemPrompt,
        generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.85,
            maxOutputTokens: maxTokens,
        },
    });
    const result = await model.generateContent(userPrompt);
    return result.response.text();
}
// ─── 무료 분석 (호감도 점수 + 한 줄 요약) ────────────────────────────────────
exports.analyzeFree = functions.onCall({ region: "asia-northeast3", memory: "256MiB", timeoutSeconds: 30 }, async (request) => {
    if (!request.auth)
        throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const { chatContent } = request.data;
    if (!chatContent || chatContent.length < 10) {
        throw new functions.HttpsError("invalid-argument", "대화 내용이 너무 짧습니다");
    }
    // 최근 200줄만 처리 (토큰 절약)
    const trimmed = chatContent.split("\n").slice(-200).join("\n");
    const result = await callGemini(`당신은 연애 심리 전문가입니다. 카카오톡 대화를 분석해 상대방의 호감도를 측정합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{"score": <0~100 정수>, "summary": "<20자 이내 한 줄 요약>"}`, `다음 카카오톡 대화를 분석해주세요:\n\n${trimmed}`);
    // 원문은 이 시점에 메모리에서 사라짐 (저장 안 함)
    return JSON.parse(result);
});
// ─── 유료 분석 (상세 분석, 크레딧 1개 차감) ─────────────────────────────────
exports.analyzePremium = functions.onCall({ region: "asia-northeast3", memory: "512MiB", timeoutSeconds: 60 }, async (request) => {
    if (!request.auth)
        throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const uid = request.auth.uid;
    // 크레딧 확인 및 차감 (트랜잭션)
    const credits = await getUserCredits(uid);
    if (credits <= 0)
        throw new functions.HttpsError("resource-exhausted", "크레딧이 부족합니다");
    await deductCredit(uid);
    const { chatContent } = request.data;
    const result = await callGemini(`당신은 연애 심리 전문가입니다. 카카오톡 대화를 심층 분석합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{
  "score": <0~100 정수>,
  "summary": "<한 줄 요약>",
  "replyPatterns": [{"label": "상대방", "avgMinutes": <숫자>}, {"label": "나", "avgMinutes": <숫자>}],
  "keywords": [{"word": "<키워드>", "count": <횟수>, "sentiment": "positive|negative|neutral"}],
  "emotionChart": [{"date": "<날짜 MM/DD>", "score": <0.0~1.0>}],
  "aiGuide": "<다음 대화 가이드 3줄 (줄바꿈 포함)>",
  "prediction": "<관계 발전 예측 2줄>"
}`, `다음 카카오톡 대화를 심층 분석해주세요:\n\n${chatContent}`);
    // 결과만 Firestore에 저장 (원문 저장 안 함)
    const parsed = JSON.parse(result);
    await db.collection("users").doc(uid).collection("analyses").add({
        ...parsed,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return parsed;
});
// ─── MBTI 궁합 (풍부한 콘텐츠, 캐싱 적용) ───────────────────────────────────
exports.analyzeMbti = functions.onCall({ region: "asia-northeast3", memory: "256MiB", timeoutSeconds: 45 }, async (request) => {
    if (!request.auth)
        throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const { myMbti, theirMbti } = request.data;
    // 캐시 키 (알파벳 정렬로 A+B == B+A)
    const cacheKey = [myMbti, theirMbti].sort().join("_");
    const cacheRef = db.collection("mbtiCache").doc(cacheKey);
    const cached = await cacheRef.get();
    if (cached.exists) {
        // 캐시 히트 → API 비용 0
        const data = cached.data();
        return { ...data, myMbti, theirMbti };
    }
    const result = await callGemini(`당신은 MBTI 연애 전문가이자 SNS 바이럴 콘텐츠 크리에이터입니다.
두 MBTI 유형의 연애 궁합을 팩폭 스타일로 깊이 있게 분석합니다.
답변은 재미있고 공감되며 인스타/틱톡에서 스크린샷으로 공유하고 싶게 만들어야 합니다.

반드시 아래 JSON 형식으로만 응답하세요. 각 항목을 최대한 풍부하고 구체적으로 작성하세요:
{
  "compatibilityScore": <0~100 정수>,
  "compatibilityTag": "<천생연분|찰떡궁합|좋은 한 쌍|특이한 조합|극과 극|도전적 관계|위험한 매력|주의 요망 중 하나>",
  "shockLine": "<충격적이고 웃기고 공감되는 팩폭 한 줄. 캡처해서 친구들에게 보내고 싶게. 이모지 포함. 20~35자>",
  "summary": "<이 두 유형이 만나면 어떤 커플이 되는지 생생하게 2~3문장. 구체적 상황 예시 포함>",
  "heartPounds": ["<이 커플만의 심쿵 포인트 1. 구체적 상황>", "<심쿵 포인트 2>", "<심쿵 포인트 3>"],
  "dangerZones": ["<이 커플의 최대 갈등 패턴 1. 실제 대화 예시 포함>", "<갈등 패턴 2>"],
  "talkTips": ["<이 조합에서 효과적인 대화법 1. 구체적>", "<대화법 2>"],
  "lovePrediction": "<이 두 유형이 사귀면 어떻게 발전하는지. 3개월/6개월/1년 후 예측. 2~3문장>",
  "myPersonality": "<${myMbti} 유형의 연애 특성. 장점/단점/버릇 포함. 2~3문장. 읽으면 '맞아 이게 나야' 하게>",
  "theirPersonality": "<${theirMbti} 유형의 연애 특성. 장점/단점/버릇 포함. 2~3문장>"
}`, `${myMbti}와 ${theirMbti}의 연애 궁합을 팩폭 스타일로 분석해주세요.
${myMbti}가 나이고 ${theirMbti}가 상대방입니다.`, 2500);
    const parsed = JSON.parse(result);
    // 캐시에 저장 (양방향 공통 데이터만)
    await cacheRef.set({ ...parsed, createdAt: admin.firestore.FieldValue.serverTimestamp() });
    return { ...parsed, myMbti, theirMbti };
});
// ─── MBTI + 사주 합산 궁합 (실제 역술 기반, 크레딧 1개 차감) ────────────────
exports.analyzeMbtiSaju = functions.onCall({ region: "asia-northeast3", memory: "512MiB", timeoutSeconds: 60 }, async (request) => {
    if (!request.auth)
        throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const uid = request.auth.uid;
    // 크레딧 확인 및 차감
    const credits = await getUserCredits(uid);
    if (credits <= 0)
        throw new functions.HttpsError("resource-exhausted", "크레딧이 부족합니다");
    await deductCredit(uid);
    const { myMbti, theirMbti, myBirthDate, theirBirthDate, myBirthHour, theirBirthHour } = request.data;
    const myHourStr = myBirthHour !== undefined ? `출생 시간: ${myBirthHour}시` : "출생 시간 미입력";
    const theirHourStr = theirBirthHour !== undefined ? `출생 시간: ${theirBirthHour}시` : "출생 시간 미입력";
    const result = await callGemini(`당신은 MBTI 심리학과 동양 사주명리학(四柱命理學)을 결합한 연애 궁합 전문가이자 SNS 바이럴 콘텐츠 크리에이터입니다.
사주팔자(四柱八字)를 실제로 계산하고 오행(木火土金水) 상생상극, 십이지 궁합, 천간 조화를 분석합니다.
분석은 재미있고 팩폭 스타일로, SNS에서 바이럴될 만한 내용으로 작성합니다.

반드시 아래 JSON 형식으로만 응답하세요:
{
  "compatibilityScore": <MBTI+사주 종합 궁합 0~100>,
  "compatibilityTag": "<천생연분|찰떡궁합|좋은 한 쌍|특이한 조합|극과 극|도전적 관계|위험한 매력|주의 요망 중 하나>",
  "shockLine": "<MBTI와 사주를 결합한 충격적이고 재미있는 팩폭 한 줄. SNS 공유 유도. 이모지 포함. 20~35자>",
  "summary": "<MBTI 궁합 분석 2~3문장. 구체적 상황 예시 포함>",
  "heartPounds": ["<이 커플만의 심쿵 포인트 1>", "<심쿵 포인트 2>", "<심쿵 포인트 3>"],
  "dangerZones": ["<갈등 패턴 1. 실제 대화 예시 포함>", "<갈등 패턴 2>"],
  "talkTips": ["<대화법 1>", "<대화법 2>"],
  "lovePrediction": "<사주 기반 연애 발전 예측. 시간대별 흐름. 2~3문장>",
  "myPersonality": "<나의 MBTI 연애 특성 2~3문장>",
  "theirPersonality": "<상대방 MBTI 연애 특성 2~3문장>",
  "sajuAnalysis": "<사주팔자 실제 계산 결과 (년주/월주/일주/시주 간지 포함) + 오행 궁합 분석 3~4문장>",
  "myPillar": "<나의 사주 핵심: 일주(日柱) + 오행 특성 한 줄>",
  "theirPillar": "<상대방 사주 핵심: 일주(日柱) + 오행 특성 한 줄>",
  "overallVerdict": "<종합 판정: 천생연분/좋은궁합/보통/극과극/주의필요 중 하나 + 이유 한 줄>"
}`, `나: ${myMbti}, 생년월일 ${myBirthDate}, ${myHourStr}
상대방: ${theirMbti}, 생년월일 ${theirBirthDate}, ${theirHourStr}

위 두 사람의 MBTI와 사주팔자를 계산하고 종합 궁합을 분석해주세요.
사주는 만세력 기준으로 실제 간지(干支)를 계산하여 포함하세요.`, 3000);
    const parsed = JSON.parse(result);
    // 결과 저장 (원문 저장 안 함)
    await db.collection("users").doc(uid).collection("analyses").add({
        type: "mbtiSaju",
        myMbti, theirMbti,
        ...parsed,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { ...parsed, myMbti, theirMbti };
});
// ─── 사주 단독 분석 (나의 연애운, 무료) ──────────────────────────────────────
exports.analyzeSaju = functions.onCall({ region: "asia-northeast3", memory: "512MiB", timeoutSeconds: 60 }, async (request) => {
    if (!request.auth)
        throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const { birthDate, birthHour, gender, question } = request.data;
    if (!birthDate)
        throw new functions.HttpsError("invalid-argument", "생년월일이 필요합니다");
    const hourStr = birthHour !== undefined ? `출생 시간: ${birthHour}시` : "출생 시간 미입력";
    const questionStr = question ? `\n특별히 궁금한 것: ${question}` : "";
    const result = await callGemini(`당신은 동양 사주명리학(四柱命理學) 전문가이자 연애 코치입니다.
사주팔자(四柱八字)를 실제로 계산하고 오행(木火土金水), 십성, 신살을 분석합니다.
분석은 친근하고 재미있게, 하지만 전문적인 근거를 바탕으로 작성합니다.
SNS에서 공유하고 싶을 만큼 인상적인 내용으로 작성합니다.

반드시 아래 JSON 형식으로만 응답하세요:
{
  "fourPillars": {
    "year": "<년주 간지 (예: 甲子)>",
    "month": "<월주 간지 (예: 丙寅)>",
    "day": "<일주 간지 (예: 壬午)>",
    "hour": "<시주 간지 또는 '미입력'>",
    "summary": "<사주팔자 한 줄 설명>"
  },
  "fiveElements": {
    "dominant": "<가장 강한 오행>",
    "lacking": "<부족한 오행>",
    "description": "<오행 구성 특성 2문장>"
  },
  "daymaster": "<일간의 특성과 연애 스타일 2~3문장>",
  "lovePersonality": "<연애할 때 이 사람의 특징. 장점/단점/버릇. 3~4문장. '당신은~'으로 시작. 읽으면 '맞아 이게 나야' 하게>",
  "idealPartner": "<사주 기반 이상적인 파트너 오행/유형. 구체적으로 어떤 사람인지. 2~3문장>",
  "loveIn2025": "<2025년 연애운. 언제 좋은 시기인지, 주의해야 할 시기. 2~3문장>",
  "shockLine": "<이 사람의 연애 사주를 한 줄로 팩폭. 이모지 포함. 공유하고 싶게. 20~30자>",
  "advice": "<현재 연애 상황에 대한 조언. 구체적 행동 제안. 2~3문장>"
}`, `생년월일: ${birthDate}, ${hourStr}, 성별: ${gender}${questionStr}

위 정보를 바탕으로 사주팔자를 계산하고 연애운을 분석해주세요.
사주는 만세력 기준으로 실제 간지(干支)를 계산하여 포함하세요.`, 2500);
    return JSON.parse(result);
});
// ─── 토스페이먼츠 결제 확인 (카드사 심사용 웹 결제) ──────────────────────────
exports.confirmTossPayment = functions.onCall({ region: "asia-northeast3", memory: "256MiB", timeoutSeconds: 30 }, async (request) => {
    if (!request.auth)
        throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const uid = request.auth.uid;
    const { paymentKey, orderId, amount } = request.data;
    // 토스페이먼츠 결제 승인 API (시크릿 키는 서버에만 - 클라이언트 절대 노출 안 됨)
    const secretKey = process.env.TOSS_SECRET_KEY;
    const credentials = Buffer.from(`${secretKey}:`).toString("base64");
    const response = await fetch("https://api.tosspayments.com/v1/payments/confirm", {
        method: "POST",
        headers: {
            "Authorization": `Basic ${credentials}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ paymentKey, orderId, amount }),
    });
    if (!response.ok) {
        const error = await response.json();
        throw new functions.HttpsError("internal", error.message || "결제 확인 실패");
    }
    // orderId 형식: credit_1_{uuid}, credit_5_{uuid}, credit_10_{uuid}
    const productId = orderId.split("_").slice(0, 2).join("_");
    const creditMap = {
        credit_1: 1,
        credit_5: 5,
        credit_10: 10,
    };
    const creditsToAdd = creditMap[productId];
    if (!creditsToAdd)
        throw new functions.HttpsError("invalid-argument", "알 수 없는 상품");
    await db.collection("users").doc(uid).set({ credits: admin.firestore.FieldValue.increment(creditsToAdd) }, { merge: true });
    return { success: true, creditsAdded: creditsToAdd };
});
// ─── RevenueCat Webhook (앱 크레딧 충전) ─────────────────────────────────────
exports.revenuecatWebhook = functions.onRequest({ region: "asia-northeast3" }, async (req, res) => {
    var _a, _b, _c, _d;
    // RevenueCat Authorization 헤더 검증
    const authHeader = req.headers.authorization;
    if (authHeader !== `Bearer ${process.env.RC_WEBHOOK_SECRET}`) {
        res.status(401).send("Unauthorized");
        return;
    }
    const event = req.body;
    if (((_a = event.event) === null || _a === void 0 ? void 0 : _a.type) !== "INITIAL_PURCHASE" && ((_b = event.event) === null || _b === void 0 ? void 0 : _b.type) !== "NON_SUBSCRIPTION_PURCHASE") {
        res.status(200).send("ignored");
        return;
    }
    const uid = (_c = event.event) === null || _c === void 0 ? void 0 : _c.app_user_id;
    const productId = (_d = event.event) === null || _d === void 0 ? void 0 : _d.product_id;
    const creditMap = {
        credit_1: 1,
        credit_5: 5,
        credit_10: 10,
    };
    const credits = creditMap[productId];
    if (!uid || !credits) {
        res.status(400).send("unknown product");
        return;
    }
    await db.collection("users").doc(uid).set({ credits: admin.firestore.FieldValue.increment(credits) }, { merge: true });
    res.status(200).send("ok");
});
//# sourceMappingURL=index.js.map