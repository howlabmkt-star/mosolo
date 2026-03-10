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
exports.revenuecatWebhook = exports.analyzeMbti = exports.analyzePremium = exports.analyzeFree = void 0;
const functions = __importStar(require("firebase-functions/v2/https"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
// ─── Gemini API 호출 ─────────────────────────────────────────────────────────
async function callGemini(systemPrompt, userPrompt) {
    var _a, _b, _c, _d, _e, _f;
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey)
        throw new Error("GEMINI_API_KEY is missing");
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            system_instruction: { parts: [{ text: systemPrompt }] },
            contents: [{ parts: [{ text: userPrompt }] }],
            generationConfig: {
                temperature: 0.7,
                maxOutputTokens: 1000,
                responseMimeType: "application/json",
            },
        }),
    });
    const data = await response.json();
    return (_f = (_e = (_d = (_c = (_b = (_a = data.candidates) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.content) === null || _c === void 0 ? void 0 : _c.parts) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.text) !== null && _f !== void 0 ? _f : "{}";
}
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
// ─── 무료 분석 (호감도 점수 + 한 줄 요약) ────────────────────────────────────
exports.analyzeFree = functions.onCall({ region: "asia-northeast3", memory: "256MiB", timeoutSeconds: 30 }, async (request) => {
    if (!request.auth)
        throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const { chatContent } = request.data;
    if (!chatContent || chatContent.length < 10) {
        throw new functions.HttpsError("invalid-argument", "대화 내용이 너무 짧습니다");
    }
    const trimmed = chatContent.split("\n").slice(-200).join("\n");
    const result = await callGemini(`당신은 연애 심리 전문가입니다. 카카오톡 대화를 분석해 상대방의 호감도를 측정합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{"score": <0~100 정수>, "summary": "<20자 이내 한 줄 요약>"}`, `다음 카카오톡 대화를 분석해주세요:\n\n${trimmed}`);
    return JSON.parse(result);
});
// ─── 유료 분석 (상세 분석, 크레딧 1개 차감) ─────────────────────────────────
exports.analyzePremium = functions.onCall({ region: "asia-northeast3", memory: "512MiB", timeoutSeconds: 60 }, async (request) => {
    if (!request.auth)
        throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const uid = request.auth.uid;
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
    const parsed = JSON.parse(result);
    await db.collection("users").doc(uid).collection("analyses").add({
        ...parsed,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return parsed;
});
// ─── MBTI 궁합 (캐싱 적용) ───────────────────────────────────────────────────
exports.analyzeMbti = functions.onCall({ region: "asia-northeast3", memory: "256MiB", timeoutSeconds: 30 }, async (request) => {
    if (!request.auth)
        throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const { myMbti, theirMbti } = request.data;
    const cacheKey = [myMbti, theirMbti].sort().join("_");
    const cacheRef = db.collection("mbtiCache").doc(cacheKey);
    const cached = await cacheRef.get();
    if (cached.exists) {
        const data = cached.data();
        return { ...data, myMbti, theirMbti };
    }
    const result = await callGemini(`당신은 MBTI 전문가입니다. 두 MBTI의 연애 궁합을 팩폭 스타일로 분석합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{
  "compatibilityScore": <0~100 정수>,
  "shockLine": "<충격적이고 재미있는 한 줄 팩폭, SNS 공유 유도>",
  "summary": "<궁합 요약 3~4문장>"
}`, `${myMbti}와 ${theirMbti}의 연애 궁합을 분석해주세요.`);
    const parsed = JSON.parse(result);
    await cacheRef.set({ ...parsed, createdAt: admin.firestore.FieldValue.serverTimestamp() });
    return { ...parsed, myMbti, theirMbti };
});
// ─── RevenueCat Webhook (크레딧 충전) ─────────────────────────────────────────
exports.revenuecatWebhook = functions.onRequest({ region: "asia-northeast3" }, async (req, res) => {
    var _a, _b, _c, _d;
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