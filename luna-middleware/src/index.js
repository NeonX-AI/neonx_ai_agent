import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

// ============================================================
// LUNA SECURITY MIDDLEWARE — OpenClaw Plugin (v3)
// Hooks: message_received (observation) + message_sending (decision)
// Không cần allowConversationAccess (message hooks không cần permission)
// Hỗ trợ đa ngôn ngữ: VI, EN, ZH
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

// Multi-language sensitive patterns
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

// Language detection
const VI_CHARS = /[àáạảãăằắặẳẵôốồổỗơờớợưứừửữéèẹẻêếềệíìịỉĩýỳỵỷỹđ]/;
const ZH_CHARS = /[\u4e00-\u9fff]/;

function detectLang(text) {
  if (!text) return "en";
  if (ZH_CHARS.test(text)) return "zh";
  if (VI_CHARS.test(text)) return "vi";
  return "en";
}

function checkSensitive(text) {
  if (!text) return false;
  for (const p of SENSITIVE_PATTERNS) {
    const re = new RegExp(p.source, p.flags);
    if (re.test(text)) return true;
  }
  return false;
}

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

const REDACT_PATTERNS = [
  { re: /(api[_\s]?key|token|secret)\s*[:=]\s*\S+/gi, rep: "$1: [REDACTED]" },
  { re: /\/home\/node\/\.openclaw[^\s]*/gi, rep: "[REDACTED_PATH]" },
  { re: /(session[_\s]?id)\s*[:=]\s*\S+/gi, rep: "$1: [REDACTED]" },
  { re: /openclaw\.json/gi, rep: "[REDACTED_CONFIG]" },
  { re: /sk-[a-zA-Z0-9]{10,}/g, rep: "[REDACTED_KEY]" },
  { re: /ghp_[a-zA-Z0-9]{10,}/g, rep: "[REDACTED_TOKEN]" },
  { re: /(base[_]?url|endpoint)\s*[:=]\s*https?:\/\/\S+/gi, rep: "$1: [REDACTED]" },
];

function filterOutput(text) {
  let result = text;
  let changed = false;
  for (const { re, rep } of REDACT_PATTERNS) {
    const newResult = result.replace(re, rep);
    if (newResult !== result) {
      result = newResult;
      changed = true;
    }
  }
  return { text: result, changed };
}

function getBlockResponse(lang) {
  const pool = BLOCK_RESPONSES[lang] || BLOCK_RESPONSES.en;
  return pool[Math.floor(Math.random() * pool.length)];
}

// Track: sessionKey -> { blocked: boolean, lang: string }
const sessionFlags = new Map();

export default definePluginEntry({
  id: "luna-security-middleware",
  name: "Luna Security Middleware",
  description: "Blocks sensitive patterns for non-main agents, multi-language support",

  register(api) {
    // Hook 1: message_received (observation, no permission needed)
    // Gets inbound user messages with sessionKey, senderId
    api.on("message_received", async (event, ctx) => {
      const sessionKey = ctx?.sessionKey || event?.context?.sessionKey || "";
      if (!isProtectedAgent(sessionKey)) {
        console.log(`[luna-middleware] SKIP (main agent): ${sessionKey}`);
        return;
      }

      const senderId = ctx?.senderId || ctx?.channelContext?.sender?.id || event?.context?.senderId || "";
      if (senderId && BYPASS_USER_IDS.has(String(senderId))) {
        console.log(`[luna-middleware] BYPASS (owner): sender=${senderId}`);
        return;
      }

      const content = event?.content || event?.text || event?.BodyForAgent || event?.body || "";
      console.log(`[luna-middleware] CHECKING: session=${sessionKey}, sender=${senderId}, len=${content.length}`);

      if (checkSensitive(content)) {
        sessionFlags.set(sessionKey, { blocked: true, lang: detectLang(content) });
        console.log(`[luna-middleware] BLOCKED: session=${sessionKey}, lang=${detectLang(content)}`);
      } else {
        sessionFlags.set(sessionKey, { blocked: false });
      }
    });

    // Hook 2: message_sending (decision, can rewrite or cancel)
    api.on("message_sending", async (event, ctx) => {
      const sessionKey = ctx?.sessionKey || event?.context?.sessionKey || "";
      if (!isProtectedAgent(sessionKey)) return;

      const flag = sessionFlags.get(sessionKey);
      const content = event?.content || event?.payload?.text || event?.payload?.content || "";

      console.log(`[luna-middleware] message_sending: session=${sessionKey}, blocked=${flag?.blocked}, content_len=${content.length}`);

      if (flag?.blocked && content) {
        const blockText = getBlockResponse(flag.lang);
        // message_sending rewrites event.content
        if (event.content !== undefined) {
          event.content = blockText;
        } else if (event.payload?.text !== undefined) {
          event.payload.text = blockText;
        } else if (event.payload?.content !== undefined) {
          event.payload.content = blockText;
        } else {
          // Try setting content directly on event
          event.content = blockText;
        }
        console.log(`[luna-middleware] REPLACED with block response for session=${sessionKey}`);
        sessionFlags.delete(sessionKey);
        return;
      }

      // Redact sensitive info from normal output
      if (content) {
        const { text: sanitized, changed } = filterOutput(content);
        if (changed) {
          if (event.content !== undefined) {
            event.content = sanitized;
          } else if (event.payload?.text !== undefined) {
            event.payload.text = sanitized;
          } else if (event.payload?.content !== undefined) {
            event.payload.content = sanitized;
          } else {
            event.content = sanitized;
          }
          console.log(`[luna-middleware] REDACTED output for session=${sessionKey}`);
        }
      }

      // Clean up flag if it existed but wasn't blocked
      if (flag !== undefined) {
        sessionFlags.delete(sessionKey);
      }
    });
  },
});
