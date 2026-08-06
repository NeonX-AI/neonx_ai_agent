import type { MessagePresentation } from "openclaw/plugin-sdk/interactive-runtime";
import type { ReplyPayload } from "openclaw/plugin-sdk/reply-runtime";
import type { MessengerPresentationPayload } from "./messengerPresentationTypes.js";
export declare function renderMessengerPresentationPayload(params: {
    payload: ReplyPayload;
    presentation: MessagePresentation;
}): MessengerPresentationPayload | null;
