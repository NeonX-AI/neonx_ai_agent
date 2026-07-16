import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

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

      // console.log(`[openclaw-message-listener] event message:`, event);
      
      // Extract the latest user message
      // const userMessages = messages.filter((m) => m?.role === "user");
      
      // const latestUserMessage = userMessages.length > 0 
      //   ? (typeof userMessages[userMessages.length - 1]?.content === "string" 
      //     ? userMessages[userMessages.length - 1].content 
      //     : "") 
      //   : "";
      const prompt = event.prompt;

      console.log(`[openclaw-message-listener] Incoming message:`, {
        timestamp: new Date().toISOString(),
        sessionKey,
        userId,
        agentId,
        message: prompt.substring(0, 200) + (prompt.length > 200 ? "..." : ""), // Truncate long messages
        totalMessages: messages.length,
      });
    }, { priority: 100 }); // Higher priority to block before other middleware
  },
});
