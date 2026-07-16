import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

// ============================================================
// LUNA SECURITY MIDDLEWARE — OpenClaw Plugin
// Hook vào pipeline: filter input + filter output cho TẤT CẢ agent (trừ main)
// ============================================================

// Configurable bypass user IDs — lấy từ env var, fallback vào hardcode
const BYPASS_USER_IDS = new Set(
  (process.env.OWNER_BYPASS_IDS || "2088229709")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
);

function isProtectedAgent(sessionKey) {
  if (!sessionKey) return false;
  // Block tất cả agent ngoài "main"
  if (sessionKey.includes("agent:main:")) return false;
  return true;
}

const SENSITIVE_PATTERNS = [
  // AI model / agent
  /(model|llm|agent|ai).*(name|id|version|provider|alias|config|gì|nào|which|what)/i,
  /(dùng|sử dụng|chạy|running|using).*(model|llm|agent|ai)/i,
  /model.*(gì|nào|là gì|là j|what|which)/i,
  /ai.*(gì|nào|là gì|là j|what|which)/i,

  // System / config
  /(config|configuration|openclaw\.json|\.env)/i,
  /(api[_\s]?key|token|secret|password|credential)/i,
  /webhook[_\s]?(url|secret|path)/i,

  // Prompt / instructions
  /(system[_\s]?prompt|instructions|rules|soul\.md|agents\.md|identity\.md)/i,
  /(show|read|dump|print|reveal).*(prompt|memory|config|context)/i,
  /ignore\s+(all|previous)\s+(rules|instructions)/i,
  /(dan|jailbreak|bypass|override)/i,

  // File / workspace probing
  /(read|cat|open|access|đọc|xem|lấy).*(memory|workspace|\.openclaw|config|\.env)/i,

  // Tools / capabilities
  /(what\s+tools|list\s+tools|available\s+tools|exec|execute|shell|bash|terminal)/i,

  // Cron / scheduling
  /(cron|schedule|heartbeat|task|job).*(list|config|show|detail|info|gì)/i,

  // Memory / transcripts
  /(memory|daily|transcript|nhật ký).*(show|read|list|dump|search|đọc|xem)/i,
  /(session[_\s]?id|pid|runtime)/i,
];

const REDACT_PATTERNS = [
  { pattern: /(api[_\s]?key|token|secret)\s*[:=]\s*\S+/gi, replacement: "$1: [REDACTED]" },
  { pattern: /\/home\/node\/\.openclaw[^\s]*/gi, replacement: "[REDACTED_PATH]" },
  { pattern: /(session[_\s]?id)\s*[:=]\s*\S+/gi, replacement: "$1: [REDACTED]" },
  { pattern: /openclaw\.json/gi, replacement: "[REDACTED_CONFIG]" },
];

const BLOCK_RESPONSES = [
  "Xin lỗi bạn, em không thể chia sẻ thông tin về hệ thống được. Em có thể giúp gì khác cho bạn không? 😊",
  "Câu hỏi này liên quan đến hệ thống nội bộ, em không được phép trả lời. Bạn cần em hỗ trợ việc gì khác không? 🐾",
  "Em không thể cung cấp thông tin kỹ thuật về hệ thống. Bạn có câu hỏi nào khác em có thể giúp không? 😊",
];

function filterInput(message, userId) {
  if (userId && BYPASS_USER_IDS.has(String(userId))) {
    return { allowed: true, bypassed: true };
  }

  const trimmed = message.trim();
  if (!trimmed) return { allowed: false, reason: "Empty message" };

  for (const pattern of SENSITIVE_PATTERNS) {
    if (pattern.test(trimmed)) {
      return { allowed: false, reason: `Sensitive pattern matched: ${pattern.source.slice(0, 40)}...` };
    }
  }

  return { allowed: true };
}

function filterOutput(response) {
  let sanitized = response;
  let changed = false;

  for (const { pattern, replacement } of REDACT_PATTERNS) {
    if (pattern.test(sanitized)) {
      sanitized = sanitized.replace(pattern, replacement);
      changed = true;
    }
  }

  return { sanitized, changed };
}

function getBlockResponse() {
  return BLOCK_RESPONSES[Math.floor(Math.random() * BLOCK_RESPONSES.length)];
}

export default definePluginEntry({
  id: "luna-security-middleware",
  name: "Luna Security Middleware",
  description: "Blocks sensitive patterns for Luna agent, filters output to redact technical info",

  register(api) {
    // Hook: Block input before agent run
    // Áp dụng cho TẤT CẢ agent TRỪ main agent
    api.on("before_agent_run", async (event) => {
      const sessionKey = event.context?.sessionKey || "";

      // Bỏ qua main agent — không chặn
      if (!isProtectedAgent(sessionKey)) return;

      const userMsg = event.messages?.filter((m) => m.role === "user")?.pop()?.content || "";
      const userId = event.context?.userId || event.context?.userIdStr || "";

      // Owner bypass — chat thoải mái
      const filter = filterInput(userMsg, userId);

      if (!filter.allowed) {
        return {
          cancel: true,
          reply: getBlockResponse(),
        };
      }
    }, { priority: 100 });

    // Hook: Filter output before sending
    // Áp dụng cho TẤT CẢ agent TRỪ main agent
    api.on("message_sending", async (event) => {
      const sessionKey = event.context?.sessionKey || "";

      // Bỏ qua main agent — không filter
      if (!isProtectedAgent(sessionKey)) return;

      const text = event.payload?.text || "";
      if (!text) return;

      const { sanitized, changed } = filterOutput(text);

      if (changed) {
        event.payload.text = sanitized;
      }
    }, { priority: 100 });
  },
});
