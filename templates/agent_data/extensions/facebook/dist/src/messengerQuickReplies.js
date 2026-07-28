import { MESSENGER_OPENCLAW_ACTION_PREFIX, MESSENGER_QUICK_REPLY_CONTENT_TYPE, MESSENGER_QUICK_REPLY_MAX_COUNT, MESSENGER_QUICK_REPLY_MIN_COUNT, MESSENGER_QUICK_REPLY_PAYLOAD_MAX_BYTES, MESSENGER_QUICK_REPLY_TITLE_MAX_LENGTH, } from "./messengerPresentationTypes.js";
import { hasText, stripMessengerMarkdown, trimToCodePoints, utf8ByteLength, } from "./messengerPresentationText.js";
function normalizeQuickReplyLabel(value) {
    if (!hasText(value)) {
        return null;
    }
    const label = trimToCodePoints(stripMessengerMarkdown(value), MESSENGER_QUICK_REPLY_TITLE_MAX_LENGTH);
    return label || null;
}
function normalizeQuickReplyPayload(value, fallback) {
    const payload = hasText(value)
        ? stripMessengerMarkdown(value)
        : stripMessengerMarkdown(fallback);
    if (!payload || utf8ByteLength(payload) > MESSENGER_QUICK_REPLY_PAYLOAD_MAX_BYTES) {
        return null;
    }
    return payload;
}
function encodeOpenClawActionPayload(value) {
    const encoded = `${MESSENGER_OPENCLAW_ACTION_PREFIX}${value}`;
    return utf8ByteLength(encoded) > MESSENGER_QUICK_REPLY_PAYLOAD_MAX_BYTES ? null : encoded;
}
export function decodeOpenClawActionPayload(payload) {
    const trimmed = payload?.trim();
    if (!trimmed?.startsWith(MESSENGER_OPENCLAW_ACTION_PREFIX)) {
        return null;
    }
    const value = trimmed.slice(MESSENGER_OPENCLAW_ACTION_PREFIX.length).trim();
    return value || null;
}
function buttonToQuickReply(button) {
    if (button.disabled || button.url || button.webApp || button.web_app) {
        return null;
    }
    const title = normalizeQuickReplyLabel(button.label);
    if (!title) {
        return null;
    }
    const payload = normalizeQuickReplyPayload(button.value, button.label);
    if (!payload) {
        return null;
    }
    const encodedPayload = encodeOpenClawActionPayload(payload);
    if (!encodedPayload) {
        return null;
    }
    return { content_type: MESSENGER_QUICK_REPLY_CONTENT_TYPE, title, payload: encodedPayload };
}
function optionToQuickReply(option) {
    const title = normalizeQuickReplyLabel(option.label);
    if (!title) {
        return null;
    }
    const payload = normalizeQuickReplyPayload(option.value, option.label);
    if (!payload) {
        return null;
    }
    const encodedPayload = encodeOpenClawActionPayload(payload);
    if (!encodedPayload) {
        return null;
    }
    return { content_type: MESSENGER_QUICK_REPLY_CONTENT_TYPE, title, payload: encodedPayload };
}
function actionToQuickReply(action) {
    const title = normalizeQuickReplyLabel(action.label);
    if (!title) {
        return null;
    }
    const payload = normalizeQuickReplyPayload(action.inputText ?? action.value ?? action.id, action.label);
    if (!payload) {
        return null;
    }
    const encodedPayload = encodeOpenClawActionPayload(payload);
    if (!encodedPayload) {
        return null;
    }
    return { content_type: MESSENGER_QUICK_REPLY_CONTENT_TYPE, title, payload: encodedPayload };
}
export function extractQuickReplies(blocks) {
    const quickReplies = [];
    for (const block of blocks) {
        if (block.type === "buttons") {
            for (const button of block.buttons) {
                const quickReply = buttonToQuickReply(button);
                if (quickReply) {
                    quickReplies.push(quickReply);
                }
            }
            continue;
        }
        if (block.type === "select") {
            for (const option of block.options) {
                const quickReply = optionToQuickReply(option);
                if (quickReply) {
                    quickReplies.push(quickReply);
                }
            }
        }
    }
    return quickReplies;
}
export function extractActionQuickReplies(actions) {
    return (actions ?? [])
        .map(actionToQuickReply)
        .filter((quickReply) => quickReply !== null);
}
export function shouldRenderQuickReplies(quickReplies) {
    return (quickReplies.length >= MESSENGER_QUICK_REPLY_MIN_COUNT &&
        quickReplies.length <= MESSENGER_QUICK_REPLY_MAX_COUNT);
}
export function getMessengerQuickReplies(payload) {
    const quickReplies = payload.channelData?.facebook
        ?.quickReplies;
    return quickReplies && shouldRenderQuickReplies(quickReplies) ? quickReplies : undefined;
}
