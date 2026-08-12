const crypto = require("node:crypto");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");

const openAiApiKey = defineSecret("OPENAI_API_KEY");
const allowedTypes = new Set(["expense", "income"]);

function cleanString(value, maxLength) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function cleanCategories(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((item) => cleanString(item, 20)).filter(Boolean))]
    .slice(0, 30);
}

function maskSensitive(value) {
  return value
    .replace(/(?:(?:\d{4}[- ]?){3}\d{4}|\d{12,19})/g, "[카드번호 숨김]")
    .replace(/0\d{1,2}[- ]?\d{3,4}[- ]?\d{4}/g, "[전화번호 숨김]")
    .replace(/(?<![\d,])\d{6,}(?![\d,원])/g, "[번호 숨김]");
}

exports.analyzeTransaction = onCall(
  {
    region: "asia-northeast3",
    secrets: [openAiApiKey],
    timeoutSeconds: 30,
    memory: "256MiB",
    maxInstances: 3,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
    }

    const message = maskSensitive(cleanString(request.data?.message, 4000));
    const expenseCategories = cleanCategories(request.data?.expenseCategories);
    const incomeCategories = cleanCategories(request.data?.incomeCategories);
    const ruleResult = request.data?.ruleResult ?? {};
    const fallbackType = allowedTypes.has(ruleResult.type)
      ? ruleResult.type
      : "expense";
    const fallback = {
      title: cleanString(ruleResult.title, 50) || "카드 결제",
      amount: Number.isSafeInteger(ruleResult.amount) && ruleResult.amount > 0
        ? ruleResult.amount
        : 0,
      category: cleanString(ruleResult.category, 20),
      type: fallbackType,
      date: cleanString(ruleResult.date, 40),
    };

    if (!message || fallback.amount <= 0 ||
        expenseCategories.length === 0 || incomeCategories.length === 0) {
      throw new HttpsError("invalid-argument", "분석할 내역이 올바르지 않습니다.");
    }

    const categoryValues = [...new Set([...expenseCategories, ...incomeCategories])];
    const schema = {
      type: "object",
      additionalProperties: false,
      required: ["title", "amount", "category", "type", "date", "confidence"],
      properties: {
        title: {type: "string"},
        amount: {type: "integer", minimum: 1},
        category: {type: "string", enum: categoryValues},
        type: {type: "string", enum: ["expense", "income"]},
        date: {type: "string"},
        confidence: {type: "number", minimum: 0, maximum: 1},
      },
    };
    const safetyIdentifier = crypto
      .createHash("sha256")
      .update(request.auth.uid)
      .digest("hex")
      .slice(0, 32);

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openAiApiKey.value()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        store: false,
        temperature: 0,
        safety_identifier: safetyIdentifier,
        messages: [
          {
            role: "system",
            content: [
              "한국 금융 문자와 Push 알림을 가계부 내역으로 정리한다.",
              "사용처는 상태 문구(완료, 승인, 결제, 출금, 입금)가 아닌 실제 가맹점·상호·송금 상대를 적는다.",
              "결제금액과 잔액·누적·한도가 함께 있으면 실제 거래금액을 선택한다.",
              "분류는 주어진 목록에서만 선택한다.",
              "애매하면 규칙 분석 결과를 유지하고 confidence를 낮게 설정한다.",
              "date는 ISO 8601 형식으로 반환한다.",
            ].join(" "),
          },
          {
            role: "user",
            content: JSON.stringify({
              notification: message,
              ruleResult: fallback,
              expenseCategories,
              incomeCategories,
            }),
          },
        ],
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "transaction_analysis",
            strict: true,
            schema,
          },
        },
      }),
    });

    if (!response.ok) {
      throw new HttpsError("unavailable", "AI 분석 서버에 연결하지 못했습니다.");
    }
    const payload = await response.json();
    const content = payload.choices?.[0]?.message?.content;
    if (!content) {
      throw new HttpsError("internal", "AI 분석 결과가 없습니다.");
    }

    let result;
    try {
      result = JSON.parse(content);
    } catch (_) {
      throw new HttpsError("internal", "AI 분석 형식이 올바르지 않습니다.");
    }

    const available = result.type === "income" ? incomeCategories : expenseCategories;
    if (!available.includes(result.category)) {
      result.category = available.includes(fallback.category)
        ? fallback.category
        : available[0];
    }
    if (!Number.isSafeInteger(result.amount) || result.amount <= 0) {
      result.amount = fallback.amount;
    }
    result.title = cleanString(result.title, 50) || fallback.title;
    result.confidence = Math.max(0, Math.min(1, Number(result.confidence) || 0));
    return result;
  },
);
