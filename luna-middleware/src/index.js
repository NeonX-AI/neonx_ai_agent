import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";

export default definePluginEntry({
  id: "luna-security-middleware",
  name: "Luna Security Middleware",
  description: "Test plugin that logs every incoming message",

  register(api) {
    api.on("before_agent_run", async (event) => {
      const sessionKey = event?.context?.sessionKey || "";
      const messages = event?.messages || [];
      const userText = messages
        .filter((m) => m?.role === "user")
        .map((m) => (typeof m?.content === "string" ? m.content : ""))
        .join("\n");

      console.log(`[luna-middleware] TEST INPUT: session=${sessionKey}`);
      console.log(`[luna-middleware] TEST INPUT CONTENT: ${userText || "(no user content)"}`);

      return { outcome: "pass", message: "test-pass" };
    }, { priority: 100 });
  },
});
