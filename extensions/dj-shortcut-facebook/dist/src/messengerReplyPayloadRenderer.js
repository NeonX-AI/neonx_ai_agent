import { renderMessengerActionPayload, renderMessengerInferredChoicePayload, } from "./messengerActionPayloadRenderer.js";
import { renderMessengerPresentationPayload } from "./messengerPresentationRenderer.js";
export function renderMessengerReplyPayload(payload) {
    const actionPayload = renderMessengerActionPayload(payload);
    if (actionPayload) {
        return actionPayload;
    }
    if (payload.presentation) {
        return renderMessengerPresentationPayload({
            payload,
            presentation: payload.presentation,
        }) ?? payload;
    }
    return renderMessengerInferredChoicePayload(payload) ?? payload;
}
