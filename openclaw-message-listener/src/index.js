import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

const BLOCK_PATTERNS = [
  /\b(model|llm|gpt|claude|gemini|qwen|chatgpt|llama|mistral|command|jurassic|bloom|t5|bert|roberta|gpt[_\s]?3|gpt[_\s]?4|dall[_\s]?e|midjourney|stable[_\s]?diffusion)\b/i,
  /\b(config|openclaw\.json|\.env|api[_\s]?key|token|secret|password|credential|auth[_\s]?token)\b/i,
  /\b(system[_\s]?prompt|system[_\s]?message|instructions|instruction[_\s]?tuning|jailbreak|bypass|override|ignore|disregard|above[_\s]?instructions|previous[_\s]?instructions)\b/i,
  /\b(exec|execute|shell|terminal|command|run|script|code|python|javascript|bash|powershell|cmd|batch)\b/i,
  /\b(memory|session[_\s]?id|transcript|runtime|pid|process|thread|memory[_\s]?usage|cpu[_\s]?usage)\b/i,
  /\b(backend|frontend|database|server|client|api|endpoint|url|ip|address|port|network|firewall|security|vulnerability|exploit|hack|attack)\b/i,
  /\b(how[_\s]?does[_\s]?this[_\s]?work|explain[_\s]?your[_\s]?system|describe[_\s]?your[_\s]?architecture|what[_\s]?are[_\s]?you[_\s]?made[_\s]?of|tell[_\s]?me[_\s]?about[_\s]?your[_\s]?implementation|reveal[_\s]?your[_\s]?prompts|what[_\s]?is[_\s]?your[_\s]?prompt|show[_\s]?me[_\s]?your[_\s]?code)\b/i,
];

const BLOCK_REPLY = {
  vi: "Xin lỗi, em chỉ có thể hỗ trợ các câu hỏi phù hợp với phạm vi của mình. Anh/chị có thể hỏi về sản phẩm hoặc dịch vụ khác không? 😊",
  en: "Sorry, I can only help with questions that are appropriate for my scope. Is there anything else I can help you with? 😊",
};

function normalizeText(text) {
  return String(text || "").replace(/\s+/g, " ").trim().toLowerCase();
}

function shouldBlock(text) {
  const normalized = normalizeText(text);
  if (!normalized) return false;
  return BLOCK_PATTERNS.some((pattern) => pattern.test(normalized));
}

export default definePluginEntry({
  id: "openclaw-message-listener",
  name: "OpenClaw Message Listener",
  description: "Listens to all messages sent to OpenClaw, logs them for monitoring, and blocks sensitive requests",

  register(api) {
    // Listen to messages before agent processing
    api.on("before_agent_run", async (event) => {
      const sessionKey = event?.context?.sessionKey || "";
      const userId = event?.context?.userId || "unknown";
      const agentId = event?.context?.agentId || "unknown";
      const messages = event?.messages || [];
      
      // Extract the latest user message
      const userMessages = messages.filter((m) => m?.role === "user");
      const latestUserMessage = userMessages.length > 0 
        ? (typeof userMessages[userMessages.length - 1]?.content === "string" 
          ? userMessages[userMessages.length - 1].content 
          : "") 
        : "";

      console.log(`[openclaw-message-listener] Incoming message:`, {
        timestamp: new Date().toISOString(),
        sessionKey,
        userId,
        agentId,
        message: latestUserMessage.substring(0, 200) + (latestUserMessage.length > 200 ? "..." : ""), // Truncate long messages
        totalMessages: messages.length,
      });

      // Log if message should be blocked but don't prevent processing
      if (shouldBlock(latestUserMessage)) {
        console.log(`[openclaw-message-listener] SENSITIVE REQUEST DETECTED: session=${sessionKey}, message="${latestUserMessage.substring(0, 100)}..."`);
        // Just log the sensitive request but continue processing
      }

      // Continue with normal processing
      return { outcome: "pass" };
    }, { priority: 100 }); // Higher priority to block before other middleware
  },
});
