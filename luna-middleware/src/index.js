import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

// ============================================================
// LUNA SECURITY MIDDLEWARE — OpenClaw Plugin (v2)
// Hook: llm_input (observation) + message_sending (decision)
// Không cần allowConversationAccess
// Hỗ trợ đa ngôn ngữ (EN, VI, ZH)
// ============================================================

const BYPASS_USER_IDS = new Set(
  (process.env.OWNER_BYPASS_IDS || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
);

if (BYPASS_USER_IDS.size === 0) {
  console.warn("[luna-middleware] WARNING: OWNER_BYPASS_IDS not set — no bypass users.");
}

function isProtectedAgent(sessionKey) {
  if (!sessionKey) return false;
  if (sessionKey.includes("agent:main:")) return false;
  return true;
}

// Multi-language sensitive patterns (EN, VI, ZH)
const SENSITIVE_PATTERNS = [
  // AI model / agent
  /(\bmodel\b|\bllm\b|\bagent|\bai\b|\bgpt\b|\bclaude\b|\bgemini\b|\bqwen\b)/i,
  /(mô[\s\-]?hình|dùng|sử\s*dụng|chạy|running|using|utiliz)/i,
  /(model|ai|agent|llm|mô[\s\-]?hình).*(name|id|version|provider|gì|nào|là gì|what|which)/i,

  // System / config
  /(\bconfig\b|configuration|openclaw\.json|\.env|hệ[\s]?thống|cấu[\s]?hình|配置)/i,

  // API keys / tokens
  /(api[_\s]?key|token|secret|password|credential|mật[\s]?khẩu|密钥)/i,
  /(webhook|endpoint)[_\s]?(url|secret|path)/i,

  // Prompt / instructions
  /(system[_\s]?prompt|instructions|rules|soul\.md|agents\.md|identity\.md|chỉ[\s]?thị)/i,

  // Jailbreak / bypass
  /(ignore\s+(all|previous)|dan\s*mode|jailbreak|bypass|override|vượt[\s]?qua)/i,

  // File / workspace probing
  /(read|cat|open|access|đọc|xem|lấy).*(memory|workspace|\.openclaw|config|\.env)/i,

  // Tools / capabilities
  /(what\s+tools|list\s+tools|available\s+tools|exec|execute|shell|bash|terminal|công[\s]?cụ)/i,

  // Cron / scheduling
  /(cron|schedule|heartbeat|task|job|lịch[\s]?trình).*(list|config|show|detail|info|gì)/i,

  // Memory / transcripts
  /(memory|daily|transcript|nhật[\s]?ký|bộ[\s]?nhớ).*(show|read|list|dump|search|đọc|xem)/i,
  /(session[_\s]?id|pid|runtime|process[_\s]?id)/i,
];

const REDACT_PATTERNS = [
  { pattern: /(api[_\s]?key|token|secret)\s*[:=]\s*\S+/gi, replacement: "$1: [REDACTED]" },
  { pattern: /\/home\/node\/\.openclaw[^\s]*/gi, replacement: "[REDACTED_PATH]" },
  { pattern: /(session[_\s]?id)\s*[:=]\s*\S+/gi, replacement: "$1: [REDACTED]" },
  { pattern: /openclaw\.json/gi, replacement: "[REDACTED_CONFIG]" },
  { pattern: /sk-[a-zA-Z0-9]{10,}/g, replacement: "[REDACTED_KEY]" },
  { pattern: /ghp_[a-zA-Z0-9]{10,}/g, replacement: "[REDACTED_TOKEN]" },
  { pattern: /(base[_]?url|endpoint)\s*[:=]\s*https?:\/\/\S+/gi, replacement: "$1: [REDACTED]" },
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

function containsSensitive(text) {
  if (!text) return false;
  for (const p of SENSITIVE_PATTERNS) {
    const re = new RegExp(p.source, p.flags);
    if (re.test(text)) return true;
  }
  return false;
}

function filterOutput(text) {
  let result = text;
  let changed = false;
  for (const { pattern, replacement } of REDACT_PATTERNS) {
    const re = new RegExp(pattern.source, pattern.flags);
    if (re.test(result)) {
      result = result.replace(re, replacement);
      changed = true;
    }
  }
  return { text: result, changed };
}

function getBlockResponse(text) {
  const lang = detectLang(text);
  const pool = BLOCK_RESPONSES[lang] || BLOCK_RESPONSES.en;
  return pool[Math.floor(Math.random() * pool.length)];
}

// Track blocked sessions: sessionKey -> { blocked: true, lang }
const blockedSessions = new Map();

export default definePluginEntry({
  id: "luna-security-middleware",
  name: "Luna Security Middleware",
  description: "Blocks sensitive patterns for non-main agents, multi-language support",

  register(api) {
    // Hook 1: llm_input (observation) — detect sensitive input
    // No allowConversationAccess needed for observation hooks
    api.on("llm_input", async (event) => {
      const sessionKey = event.context?.sessionKey || "";
      if (!isProtectedAgent(sessionKey)) return;

      const userId = event.context?.userId || event.context?.userIdStr || "";
      if (userId && BYPASS_USER_IDS.has(String(userId))) return;

      const prompt = event.prompt || "";
      const systemPrompt = event.systemPrompt || "";
      const fullInput = (systemPrompt || "") + " " + (prompt || "");

      if (containsSensitive(fullInput) || containsSensitive(prompt)) {
        blockedSessions.set(sessionKey, {
          blocked: true,
          lang: detectLang(prompt),
        });
        console.log(`[luna-middleware] BLOCKED input detected for session: ${sessionKey}`);
      } else {
        blockedSessions.set(sessionKey, { blocked: false });
      }
    }, { priority: 100 });

    // Hook 2: message_sending — replace blocked messages with safety response
    api.on("message_sending", async (event) => {
      const sessionKey = event.context?.sessionKey || "";
      if (!isProtectedAgent(sessionKey)) return;

      const flag = blockedSessions.get(sessionKey);
      const text = event.payload?.text || event.payload?.content || "";

      if (flag?.blocked) {
        const blockText = getBlockResponse(flag.lang);
        if (event.payload?.text !== undefined) {
          event.payload.text = blockText;
        } else if (event.payload?.content !== undefined) {
          event.payload.content = blockText;
        }
        console.log(`[luna-middleware] Replaced blocked reply for session: ${sessionKey}`);
        blockedSessions.delete(sessionKey);
        return;
      }

      // Even if not blocked, redact sensitive info from output
      if (text) {
        const { text: sanitized, changed } = filterOutput(text);
        if (changed) {
          if (event.payload?.text !== undefined) {
            event.payload.text = sanitized;
          } else if (event.payload?.content !== undefined) {
            event.payload.content = sanitized;
          }
        }
      }
    }, { priority: 100 });
  },
});
