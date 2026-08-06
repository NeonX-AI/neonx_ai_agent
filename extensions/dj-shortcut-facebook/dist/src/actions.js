import { createLazyRuntimeModule } from "openclaw/plugin-sdk/lazy-runtime";
import { readStringParam } from "openclaw/plugin-sdk/param-readers";
import { jsonResult } from "openclaw/plugin-sdk/tool-results";
import { extractToolSend } from "openclaw/plugin-sdk/tool-send";
import { listMessengerAccountIds, resolveMessengerAccount } from "./accounts.js";
import { stripFacebookTargetPrefix } from "./naming.js";
import { getMessengerRuntime } from "./runtime.js";
const loadMessengerSendRuntime = createLazyRuntimeModule(() => import("./send.js"));
const MESSENGER_ACTIONS = new Set(["send"]);
function listConfiguredMessengerAccounts(cfg, accountId) {
    const ids = accountId ? [accountId] : listMessengerAccountIds(cfg);
    return ids.filter((id) => {
        try {
            const account = resolveMessengerAccount({ cfg, accountId: id });
            return account.enabled && Boolean(account.pageAccessToken?.trim());
        }
        catch {
            return false;
        }
    });
}
/**
 * Channel-owned action surface for the shared `message` tool.
 *
 * The gateway routes `message(action="send", ...)` through
 * `plugin.actions.handleAction` - the durable `message` adapter
 * (`messengerMessageAdapter.send.media`) only covers agent-reply delivery.
 * Without this adapter the gateway rejects sends with
 * "Channel facebook does not support action send".
 */
export const messengerMessageActions = {
    describeMessageTool: ({ cfg, accountId }) => {
        if (listConfiguredMessengerAccounts(cfg, accountId ?? undefined).length === 0) {
            return null;
        }
        return { actions: ["send"], capabilities: [] };
    },
    supportsAction: ({ action }) => MESSENGER_ACTIONS.has(action),
    extractToolSend: ({ args }) => extractToolSend(args, "sendMessage"),
    handleAction: async ({ action, params, cfg, accountId, mediaReadFile }) => {
        if (action !== "send") {
            return jsonResult({
                ok: false,
                error: `Action ${action} is not supported for channel facebook.`,
            });
        }
        try {
            const to = stripFacebookTargetPrefix(readStringParam(params, "to", { required: true }));
            const mediaUrl = readStringParam(params, "media", { trim: false }) ??
                readStringParam(params, "mediaUrl", { trim: false });
            const text = readStringParam(params, "message", {
                required: !mediaUrl,
                allowEmpty: true,
            }) ?? "";
            if (!to) {
                return jsonResult({ ok: false, error: "Messenger send requires a target (to)." });
            }
            if (!mediaUrl && !text.trim()) {
                return jsonResult({
                    ok: false,
                    error: "Messenger send requires a message or media param.",
                });
            }
            const runtime = getMessengerRuntime().channel.facebook;
            if (mediaUrl) {
                const sendTextAndImage = runtime?.sendMessengerTextAndImage ??
                    (await loadMessengerSendRuntime()).sendMessengerTextAndImage;
                const result = await sendTextAndImage(to, text, mediaUrl, {
                    cfg,
                    accountId: accountId ?? undefined,
                    readFile: mediaReadFile,
                });
                return jsonResult({ ok: true, to, messageId: result.image.messageId });
            }
            const sendText = runtime?.sendMessengerText ?? (await loadMessengerSendRuntime()).sendMessengerText;
            const result = await sendText(to, text, {
                cfg,
                accountId: accountId ?? undefined,
            });
            return jsonResult({ ok: true, to, messageId: result.messageId });
        }
        catch (error) {
            return jsonResult({
                ok: false,
                error: error instanceof Error ? error.message : String(error),
            });
        }
    },
};
