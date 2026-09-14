import { extractQuickReplies, shouldRenderQuickReplies, } from "./messengerQuickReplies.js";
import { hasText, stripMessengerMarkdown, } from "./messengerPresentationText.js";
function presentationText(presentation, fallbackText) {
    const parts = [];
    if (hasText(fallbackText)) {
        parts.push(fallbackText.trim());
    }
    if (hasText(presentation.title) && !parts.includes(presentation.title.trim())) {
        parts.push(presentation.title.trim());
    }
    for (const block of presentation.blocks) {
        if ((block.type === "text" || block.type === "context") && hasText(block.text)) {
            const text = block.text.trim();
            if (!parts.includes(text)) {
                parts.push(text);
            }
        }
        if (block.type === "select" && hasText(block.placeholder)) {
            const text = block.placeholder.trim();
            if (!parts.includes(text)) {
                parts.push(text);
            }
        }
    }
    return parts.length > 0 ? stripMessengerMarkdown(parts.join("\n\n")) : null;
}
export function renderMessengerPresentationPayload(params) {
    const quickReplies = extractQuickReplies(params.presentation.blocks);
    const text = presentationText(params.presentation, params.payload.text);
    if (!text || !shouldRenderQuickReplies(quickReplies)) {
        return null;
    }
    return {
        ...params.payload,
        text,
        channelData: {
            ...(params.payload.channelData ?? {}),
            facebook: {
                ...(params.payload.channelData?.facebook ?? {}),
                quickReplies,
            },
        },
    };
}
