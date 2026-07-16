import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

// ============================================================
// LUNA SECURITY MIDDLEWARE — OpenClaw Plugin (v6)
// HARD BLOCK: before_agent_run (blocks model run entirely)
// + message_sending (redact output)
// Multi-language: VI, EN, ZH
// ============================================================

const BYPASS_USER_IDS = new Set(
  (process.env.OWNER_BYPASS_IDS || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
);

function getAgentReference(context = {}) {
  const candidates = [
    context?.sessionKey,
    context?.session?.key,
    context?.session?.id,
    context?.agentId,
    context?.agent?.id,
    context?.agent?.name,
    context?.agentName,
    context?.agent?.key,
    context?.agentKey,
    context?.metadata?.agentId,
    context?.metadata?.agentName,
  ];

  return candidates.find((value) => typeof value === "string" && value.trim()) || "";
}

function isMainAgent(eventOrContext = {}) {
  const context = eventOrContext?.context || eventOrContext || {};
  const rawRef = String(getAgentReference(context) || "").toLowerCase();

  if (!rawRef) return false;

  return (
    rawRef.includes("agent:main:") ||
    rawRef.includes("main-agent") ||
    rawRef.includes("main_agent") ||
    rawRef === "main" ||
    /(^|[^a-z])main([^a-z]|$)/.test(rawRef)
  );
}

function isProtectedAgent(eventOrContext = {}) {
  return !isMainAgent(eventOrContext);
}

const SENSITIVE_PATTERNS = [
  // AI model / agent
  /\bmodel\b/i, /\bllm\b/i, /\bgpt\b/i, /\bclaude\b/i, /\bgemini\b/i,
  /\bqwen\b/i, /mô[\s\-]?hình/i, /dùng.*ai/i, /sử\s*dụng.*model/i,
  /chạy.*model/i, /running.*model/i, /what.*model/i, /which.*model/i,
  /model.*gì/i, /model.*nào/i, /model.*là\s*gi/i,

  // System / config
  /\bconfig\b/i, /openclaw\.json/i, /\.env\b/i,
  /hệ[\s]?thống.*config/i, /cấu[\s]?hình.*hệ[\s]?thống/i,

  // API keys / tokens / secrets
  /api[_\s]?key/i, /token\b/i, /secret\b/i, /password/i,
  /mật[\s]?khẩu/i, /webhook.*url/i, /endpoint.*url/i,

  // Prompt / instructions
  /system[_\s]?prompt/i, /instructions/i, /soul\.md/i,
  /agents\.md/i, /ignore.*rules/i, /ignore.*previous/i,
  /jailbreak/i, /bypass/i, /override/i,

  // Tools / capabilities
  /what.*tools/i, /list.*tools/i, /exec\b/i, /execute.*shell/i,
  /công[\s]?cụ/i, /terminal/i,

  // Cron / schedule
  /\bcron\b/i, /schedule/i, /heartbeat/i, /lịch[\s]?trình/i,

  // Memory / transcripts
  /\bmemory\b/i, /daily.*notes/i, /transcript/i,
  /session[_\s]?id/i, /pid\b/i, /runtime/i,
];

const BLOCK_RESPONSES = {
  vi: [
    "Xin lỗi anh/chị, em không thể chia sẻ thông tin về hệ thống được. Anh/chị cần em hỗ trợ việc gì khác không? 😊",
    "Câu hỏi này liên quan đến hệ thống nội bộ, em không được phép trả lời. Anh/chị cần em hỗ trợ gì khác không? 🐾",
    "Em không thể cung cấp thông tin kỹ thuật về hệ thống. Anh/chị có câu hỏi nào khác em có thể giúp không? 😊",
  ],
  en: [
    "Sorry, I can't share technical system information. Is there anything else I can help you with? 😊",
    "That's internal system info I'm not allowed to share. How else can I assist you? 🐾",
    "I don't have access to technical system details. How else can I help? 😊",
  ],
  zh: [
    "抱歉，我无法分享系统技术信息。还有什么我可以帮您的吗？😊",
    "这是内部系统信息，我不能提供。还有什么我能帮忙的？🐾",
  ],
};

const VI_CHARS = /[àáạảãăằắặẳẵôốồổỗơờớợưứừửữéèẹẻêếềệíìịỉĩýỳỵỷỹđ]/;
const ZH_CHARS = /[\u4e00-\u9fff]/;

function detectLang(text) {
  if (!text) return "en";
  if (ZH_CHARS.test(text)) return "zh";
  if (VI_CHARS.test(text)) return "vi";
  return "en";
}

function normalizeText(text) {
  return String(text || "")
    .replace(/\s+/g, " ")
    .trim();
}

function extractMessageText(messages) {
  if (!Array.isArray(messages)) return "";

  return messages
    .map((message) => {
      const content = message?.content;
      if (typeof content === "string") return content;
      if (Array.isArray(content)) {
        return content
          .map((item) => (typeof item === "string" ? item : item?.text || ""))
          .filter(Boolean)
          .join(" ");
      }
      if (content && typeof content === "object") return content.text || "";
      return "";
    })
    .filter(Boolean)
    .join("\n");
}

function checkSensitive(text) {
  const normalized = normalizeText(text);
  if (!normalized) return false;

  for (const pattern of SENSITIVE_PATTERNS) {
    if (pattern.test(normalized)) return true;
  }
  return false;
}

const REDACT_PATTERNS = [
  { re: /(api[_\s]?key|token|secret)\s*[:=]\s*\S+/gi, rep: "$1: [REDACTED]" },
  { re: /\/home\/node\/\.openclaw[^\s]*/gi, rep: "[REDACTED_PATH]" },
  { re: /(session[_\s]?id)\s*[:=]\s*\S+/gi, rep: "$1: [REDACTED]" },
  { re: /openclaw\.json/gi, rep: "[REDACTED_CONFIG]" },
  { re: /sk-[a-zA-Z0-9]{10,}/g, rep: "[REDACTED_KEY]" },
  { re: /ghp_[a-zA-Z0-9]{10,}/g, rep: "[REDACTED_TOKEN]" },
];

export default definePluginEntry({
  id: "luna-security-middleware",
  name: "Luna Security Middleware",
  description: "Hard blocks sensitive patterns for non-main agents at pipeline level",

  register(api) {
    // CRITICAL HOOK: before_agent_run - runs BEFORE model is called
    // Can block the entire model run and return synthetic reply
    api.on("before_agent_run", async (event) => {
      const sessionKey = event?.context?.sessionKey || "";
      if (isMainAgent(event)) {
        console.log(`[luna-middleware] SKIP main: ${sessionKey || "(no sessionKey)"}`);
        return;
      }

      const senderId = event?.context?.senderId || event?.context?.userId || "";
      if (senderId && BYPASS_USER_IDS.has(String(senderId))) {
        console.log(`[luna-middleware] BYPASS: sender=${senderId}`);
        return;
      }

      // Check messages for sensitive patterns
      const messages = event?.messages || [];
      const systemMsg = extractMessageText(messages.filter((m) => m?.role === "system"));
      const userMsgs = extractMessageText(messages.filter((m) => m?.role === "user"));
      const allInput = [systemMsg, userMsgs].filter(Boolean).join("\n");

      console.log(`[luna-middleware] before_agent_run: session=${sessionKey}, messages=${messages.length}`);

      if (checkSensitive(allInput) || checkSensitive(userMsgs)) {
        const lang = detectLang(userMsgs);
        const pool = BLOCK_RESPONSES[lang] || BLOCK_RESPONSES.en;
        const reply = pool[Math.floor(Math.random() * pool.length)];
        console.log(`[luna-middleware] BLOCKED: session=${sessionKey}, lang=${lang}`);
        return { outcome: "block", reason: "sensitive-pattern-detected", message: reply };
      }
    }, { priority: 100 });

    // Backup: message_sending - redact output
    api.on("message_sending", async (event, ctx) => {
      const sessionKey = ctx?.sessionKey || "";
      if (isMainAgent(ctx)) return;

      const content = event?.content || "";
      if (!content) return;

      let result = content;
      let changed = false;
      for (const { re, rep } of REDACT_PATTERNS) {
        const newResult = result.replace(re, rep);
        if (newResult !== result) {
          result = newResult;
          changed = true;
        }
      }
      if (changed) {
        event.content = result;
        console.log(`[luna-middleware] REDACTED: session=${sessionKey}`);
      }
    }, { priority: 100 });
  },
});
