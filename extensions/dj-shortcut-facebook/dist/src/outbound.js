import { defineChannelMessageAdapter, } from "openclaw/plugin-sdk/channel-message";
import { createAttachedChannelResultAdapter, createEmptyChannelResult, } from "openclaw/plugin-sdk/channel-send-result";
import { createLazyRuntimeModule } from "openclaw/plugin-sdk/lazy-runtime";
import { getMessengerQuickReplies } from "./messengerQuickReplies.js";
import { renderMessengerPresentationPayload, } from "./messengerPresentationRenderer.js";
import { renderMessengerReplyPayload, } from "./messengerReplyPayloadRenderer.js";
import { MESSENGER_QUICK_REPLY_MAX_COUNT } from "./messengerPresentationTypes.js";
import { FACEBOOK_CHANNEL_ID } from "./naming.js";
import { getMessengerRuntime } from "./runtime.js";
import { MESSENGER_TEXT_CHUNK_LIMIT } from "./send.js";
const loadMessengerRuntime = createLazyRuntimeModule(() => import("./send.js"));
export const messengerOutboundAdapter = {
    deliveryMode: "direct",
    textChunkLimit: MESSENGER_TEXT_CHUNK_LIMIT,
    presentationCapabilities: {
        supported: true,
        buttons: true,
        selects: true,
        limits: {
            actions: {
                maxActions: MESSENGER_QUICK_REPLY_MAX_COUNT,
                maxActionsPerRow: MESSENGER_QUICK_REPLY_MAX_COUNT,
                maxRows: 1,
                maxLabelLength: 20,
                maxValueBytes: 1000,
                supportsStyles: false,
                supportsDisabled: false,
            },
            selects: {
                maxOptions: MESSENGER_QUICK_REPLY_MAX_COUNT,
                maxLabelLength: 20,
                maxValueBytes: 1000,
            },
            text: {
                maxLength: MESSENGER_TEXT_CHUNK_LIMIT,
                encoding: "characters",
                markdownDialect: "plain",
            },
        },
    },
    renderPresentation: ({ payload, presentation }) => renderMessengerPresentationPayload({ payload, presentation }),
    chunker: (text, limit) => getMessengerRuntime().channel.text.chunkMarkdownText(text, limit),
    sendPayload: async ({ to, payload, accountId, cfg }) => {
        const deliveryPayload = renderMessengerReplyPayload(payload);
        const sendText = getMessengerRuntime().channel.facebook?.sendMessengerText ??
            (await loadMessengerRuntime()).sendMessengerText;
        const result = await sendText(to, deliveryPayload.text ?? "", {
            cfg,
            accountId: accountId ?? undefined,
            quickReplies: getMessengerQuickReplies(deliveryPayload),
        });
        return createEmptyChannelResult(FACEBOOK_CHANNEL_ID, {
            messageId: result.messageId,
            receipt: result.receipt,
        });
    },
    ...createAttachedChannelResultAdapter({
        channel: FACEBOOK_CHANNEL_ID,
        sendText: async ({ cfg, to, text, accountId }) => {
            const sendText = getMessengerRuntime().channel.facebook?.sendMessengerText ??
                (await loadMessengerRuntime()).sendMessengerText;
            return await sendText(to, text, { cfg, accountId: accountId ?? undefined });
        },
        sendMedia: async ({ cfg, to, text, mediaUrl, accountId, mediaReadFile }) => {
            if (!mediaUrl) {
                throw new Error("Messenger media send requires a mediaUrl");
            }
            const sendTextAndImage = getMessengerRuntime().channel.facebook?.sendMessengerTextAndImage ??
                (await loadMessengerRuntime()).sendMessengerTextAndImage;
            const result = await sendTextAndImage(to, text, mediaUrl, {
                cfg,
                accountId: accountId ?? undefined,
                readFile: mediaReadFile,
            });
            return { messageId: result.image.messageId, receipt: result.image.receipt };
        },
    }),
};
function toMessengerMessageSendResult(result) {
    if (!result.receipt) {
        throw new Error("Messenger message adapter send did not return a receipt");
    }
    return {
        messageId: result.messageId || result.receipt.primaryPlatformMessageId,
        receipt: result.receipt,
    };
}
export const messengerMessageAdapter = defineChannelMessageAdapter({
    id: FACEBOOK_CHANNEL_ID,
    durableFinal: {
        capabilities: {
            text: true,
            media: true,
            messageSendingHooks: true,
        },
    },
    send: {
        text: async ({ cfg, to, text, accountId }) => {
            const result = await messengerOutboundAdapter.sendPayload({
                cfg,
                to,
                text,
                accountId,
                payload: { text },
            });
            return toMessengerMessageSendResult(result);
        },
        media: async ({ cfg, to, text, mediaUrl, accountId, mediaReadFile }) => {
            if (!mediaUrl) {
                throw new Error("Messenger media send requires a mediaUrl");
            }
            const sendTextAndImage = getMessengerRuntime().channel.facebook?.sendMessengerTextAndImage ??
                (await loadMessengerRuntime()).sendMessengerTextAndImage;
            const result = await sendTextAndImage(to, text, mediaUrl, {
                cfg,
                accountId: accountId ?? undefined,
                readFile: mediaReadFile,
            });
            return {
                messageId: result.image.messageId,
                receipt: result.image.receipt,
            };
        },
    },
    receive: {
        defaultAckPolicy: "after_agent_dispatch",
        supportedAckPolicies: ["after_receive_record", "after_agent_dispatch"],
    },
});
