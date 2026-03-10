import * as functions from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { GoogleGenerativeAI } from "@google/generative-ai";

admin.initializeApp();
const db = admin.firestore();

// Gemini 클라이언트 (API 키는 Cloud Functions 환경변수에만 저장 - 클라이언트에 절대 노출 안 됨)
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

// ─── 타입 ───────────────────────────────────────────────────────────────────

interface AnalyzeFreeRequest {
  chatContent: string;
}

interface AnalyzePremiumRequest {
  chatContent: string;
}

interface MbtiRequest {
  myMbti: string;
  theirMbti: string;
}

interface TossConfirmRequest {
  paymentKey: string;
  orderId: string;
  amount: number;
}

// ─── 헬퍼 ───────────────────────────────────────────────────────────────────

async function getUserCredits(uid: string): Promise<number> {
  const doc = await db.collection("users").doc(uid).get();
  return (doc.data()?.credits ?? 0) as number;
}

async function deductCredit(uid: string): Promise<void> {
  const ref = db.collection("users").doc(uid);
  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    const credits = (doc.data()?.credits ?? 0) as number;
    if (credits <= 0) throw new Error("크레딧이 부족합니다");
    tx.update(ref, { credits: credits - 1 });
  });
}

async function callGemini(systemPrompt: string, userPrompt: string): Promise<string> {
  const model = genAI.getGenerativeModel({
    model: "gemini-2.0-flash",
    systemInstruction: systemPrompt,
    generationConfig: {
      responseMimeType: "application/json",
      temperature: 0.7,
      maxOutputTokens: 1000,
    } as any,
  });

  const result = await model.generateContent(userPrompt);
  return result.response.text();
}

// ─── 무료 분석 (호감도 점수 + 한 줄 요약) ────────────────────────────────────

export const analyzeFree = functions.onCall(
  { region: "asia-northeast3", memory: "256MiB", timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth) throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");

    const { chatContent } = request.data as AnalyzeFreeRequest;
    if (!chatContent || chatContent.length < 10) {
      throw new functions.HttpsError("invalid-argument", "대화 내용이 너무 짧습니다");
    }

    // 최근 200줄만 처리 (토큰 절약)
    const trimmed = chatContent.split("\n").slice(-200).join("\n");

    const result = await callGemini(
      `당신은 연애 심리 전문가입니다. 카카오톡 대화를 분석해 상대방의 호감도를 측정합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{"score": <0~100 정수>, "summary": "<20자 이내 한 줄 요약>"}`,
      `다음 카카오톡 대화를 분석해주세요:\n\n${trimmed}`
    );

    // 원문은 이 시점에 메모리에서 사라짐 (저장 안 함)
    return JSON.parse(result);
  }
);

// ─── 유료 분석 (상세 분석, 크레딧 1개 차감) ─────────────────────────────────

export const analyzePremium = functions.onCall(
  { region: "asia-northeast3", memory: "512MiB", timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth) throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const uid = request.auth.uid;

    // 크레딧 확인 및 차감 (트랜잭션)
    const credits = await getUserCredits(uid);
    if (credits <= 0) throw new functions.HttpsError("resource-exhausted", "크레딧이 부족합니다");
    await deductCredit(uid);

    const { chatContent } = request.data as AnalyzePremiumRequest;

    const result = await callGemini(
      `당신은 연애 심리 전문가입니다. 카카오톡 대화를 심층 분석합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{
  "score": <0~100 정수>,
  "summary": "<한 줄 요약>",
  "replyPatterns": [{"label": "상대방", "avgMinutes": <숫자>}, {"label": "나", "avgMinutes": <숫자>}],
  "keywords": [{"word": "<키워드>", "count": <횟수>, "sentiment": "positive|negative|neutral"}],
  "emotionChart": [{"date": "<날짜 MM/DD>", "score": <0.0~1.0>}],
  "aiGuide": "<다음 대화 가이드 3줄 (줄바꿈 포함)>",
  "prediction": "<관계 발전 예측 2줄>"
}`,
      `다음 카카오톡 대화를 심층 분석해주세요:\n\n${chatContent}`
    );

    // 결과만 Firestore에 저장 (원문 저장 안 함)
    const parsed = JSON.parse(result);
    await db.collection("users").doc(uid).collection("analyses").add({
      ...parsed,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return parsed;
  }
);

// ─── MBTI 궁합 (캐싱 적용) ───────────────────────────────────────────────────

export const analyzeMbti = functions.onCall(
  { region: "asia-northeast3", memory: "256MiB", timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth) throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");

    const { myMbti, theirMbti } = request.data as MbtiRequest;

    // 캐시 키 (알파벳 정렬로 A+B == B+A)
    const cacheKey = [myMbti, theirMbti].sort().join("_");
    const cacheRef = db.collection("mbtiCache").doc(cacheKey);
    const cached = await cacheRef.get();

    if (cached.exists) {
      // 캐시 히트 → API 비용 0
      const data = cached.data()!;
      return { ...data, myMbti, theirMbti };
    }

    const result = await callGemini(
      `당신은 MBTI 전문가입니다. 두 MBTI의 연애 궁합을 팩폭 스타일로 분석합니다.
반드시 아래 JSON 형식으로만 응답하세요:
{
  "compatibilityScore": <0~100 정수>,
  "shockLine": "<충격적이고 재미있는 한 줄 팩폭, SNS 공유 유도>",
  "summary": "<궁합 요약 3~4문장>"
}`,
      `${myMbti}와 ${theirMbti}의 연애 궁합을 분석해주세요.`
    );

    const parsed = JSON.parse(result);

    // 캐시에 저장 (양방향 공통 데이터만)
    await cacheRef.set({ ...parsed, createdAt: admin.firestore.FieldValue.serverTimestamp() });

    return { ...parsed, myMbti, theirMbti };
  }
);

// ─── 토스페이먼츠 결제 확인 (카드사 심사용 웹 결제) ──────────────────────────

export const confirmTossPayment = functions.onCall(
  { region: "asia-northeast3", memory: "256MiB", timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth) throw new functions.HttpsError("unauthenticated", "로그인이 필요합니다");
    const uid = request.auth.uid;

    const { paymentKey, orderId, amount } = request.data as TossConfirmRequest;

    // 토스페이먼츠 결제 승인 API (시크릿 키는 서버에만 - 클라이언트 절대 노출 안 됨)
    const secretKey = process.env.TOSS_SECRET_KEY!;
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
      const error = await response.json() as any;
      throw new functions.HttpsError("internal", error.message || "결제 확인 실패");
    }

    // orderId 형식: credit_1_{uuid}, credit_5_{uuid}, credit_10_{uuid}
    const productId = orderId.split("_").slice(0, 2).join("_");
    const creditMap: Record<string, number> = {
      credit_1: 1,
      credit_5: 5,
      credit_10: 10,
    };

    const creditsToAdd = creditMap[productId];
    if (!creditsToAdd) throw new functions.HttpsError("invalid-argument", "알 수 없는 상품");

    await db.collection("users").doc(uid).set(
      { credits: admin.firestore.FieldValue.increment(creditsToAdd) },
      { merge: true }
    );

    return { success: true, creditsAdded: creditsToAdd };
  }
);

// ─── RevenueCat Webhook (앱 크레딧 충전) ─────────────────────────────────────

export const revenuecatWebhook = functions.onRequest(
  { region: "asia-northeast3" },
  async (req, res) => {
    // RevenueCat Authorization 헤더 검증
    const authHeader = req.headers.authorization;
    if (authHeader !== `Bearer ${process.env.RC_WEBHOOK_SECRET}`) {
      res.status(401).send("Unauthorized");
      return;
    }

    const event = req.body;
    if (event.event?.type !== "INITIAL_PURCHASE" && event.event?.type !== "NON_SUBSCRIPTION_PURCHASE") {
      res.status(200).send("ignored");
      return;
    }

    const uid: string = event.event?.app_user_id;
    const productId: string = event.event?.product_id;

    const creditMap: Record<string, number> = {
      credit_1: 1,
      credit_5: 5,
      credit_10: 10,
    };

    const credits = creditMap[productId];
    if (!uid || !credits) {
      res.status(400).send("unknown product");
      return;
    }

    await db.collection("users").doc(uid).set(
      { credits: admin.firestore.FieldValue.increment(credits) },
      { merge: true }
    );

    res.status(200).send("ok");
  }
);
