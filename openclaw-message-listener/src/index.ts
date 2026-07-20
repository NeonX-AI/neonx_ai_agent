import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

interface EventContext {
  sessionKey?: string;
  userId?: string;
  agentId?: string;
}

interface Message {
  role?: string;
  content?: string;
}

interface Event {
  context?: EventContext;
  messages?: Message[];
  prompt?: string;
}

export default definePluginEntry({
  id: "openclaw-message-listener",
  name: "OpenClaw Message Listener",
  description: "Listens to all messages sent to OpenClaw and logs them for monitoring",

  register(api: any) {
    // Listen to messages before agent processing
    api.on("before_agent_run", async (event: Event) => {
      const sessionKey = event?.context?.sessionKey || "";
      const userId = event?.context?.userId || "unknown";
      const agentId = event?.context?.agentId || "unknown";
      const messages = event?.messages || [];
      const prompt = event.prompt || "";

      console.log(`[openclaw-message-listener] Incoming message:`, {
        timestamp: new Date().toISOString(),
        sessionKey,
        userId,
        agentId,
        message: prompt.substring(0, 200) + (prompt.length > 200 ? "..." : ""), // Truncate long messages
        totalMessages: messages.length,
      });

      // Continue with normal processing
      return { outcome: "pass" };
    }, { priority: 100 }); // Higher priority to process before other middleware
  },
});
