import { definePluginEntry } from "openclaw/plugin-sdk/plugin-entry";
export default definePluginEntry({
    id: "openclaw-message-listener",
    name: "OpenClaw Message Listener",
    description: "Listens to all messages sent to OpenClaw and logs them for monitoring",
    register(api) {
        api.on("before_agent_run", async (event) => {
            const sessionKey = event?.context?.sessionKey || "";
            const userId = event?.context?.userId || "unknown";
            const agentId = event?.context?.agentId || "unknown";
            const prompt = event.prompt || "";
            return { outcome: "pass" };
        }, { priority: 100 });
    },
});
//# sourceMappingURL=index.js.map