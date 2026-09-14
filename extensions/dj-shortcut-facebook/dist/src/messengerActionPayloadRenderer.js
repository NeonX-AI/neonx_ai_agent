import { extractNumberedChoicesFromText, stripNumberedChoicesFromText, } from "./messengerNumberedChoices.js";
import { extractActionQuickReplies, shouldRenderQuickReplies, } from "./messengerQuickReplies.js";
import { hasText, stripMessengerMarkdown, } from "./messengerPresentationText.js";
function normalizePayloadText(payload) {
    const rawText = hasText(payload.text) ? payload.text.trim() : null;
    const text = rawText ? stripMessengerMarkdown(rawText) : null;
    return rawText && text ? { rawText, text } : null;
}
function hasNativeQuickReplies(payload) {
    return Boolean(payload.channelData?.facebook
        ?.quickReplies?.length);
}
function withMessengerQuickReplies(payload, text, quickReplies) {
    return {
        ...payload,
        text,
        channelData: {
            ...(payload.channelData ?? {}),
            facebook: {
                ...(payload.channelData?.facebook ?? {}),
                quickReplies,
            },
        },
    };
}
export function renderMessengerActionPayload(payload) {
    const normalized = normalizePayloadText(payload);
    if (!normalized) {
        return null;
    }
    const inferredActions = extractNumberedChoicesFromText(normalized.rawText);
    const quickReplies = extractActionQuickReplies([
        ...inferredActions,
        ...(payload.actions ?? []),
    ]);
    if (!shouldRenderQuickReplies(quickReplies)) {
        return null;
    }
    const text = inferredActions.length
        ? stripNumberedChoicesFromText(normalized.text)
        : normalized.text;
    return withMessengerQuickReplies(payload, text, quickReplies);
}
export function renderMessengerInferredChoicePayload(payload) {
    if (payload.actions?.length || payload.presentation || hasNativeQuickReplies(payload)) {
        return null;
    }
    const normalized = normalizePayloadText(payload);
    if (!normalized) {
        return null;
    }
    const quickReplies = extractActionQuickReplies(extractNumberedChoicesFromText(normalized.rawText));
    if (!shouldRenderQuickReplies(quickReplies)) {
        return null;
    }
    return withMessengerQuickReplies(payload, stripNumberedChoicesFromText(normalized.text), quickReplies);
}
