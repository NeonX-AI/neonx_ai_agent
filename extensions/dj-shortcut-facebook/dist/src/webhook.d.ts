import type { ServerResponse } from "node:http";
import type { MessengerWebhookBody, MessengerWebhookMessaging } from "./types.js";
export type MessengerAttachmentKind = "image" | "audio" | "video" | "file" | "unknown";
export type MessengerAttachmentUrl = {
    type: string;
    kind: MessengerAttachmentKind;
    url: string;
};
export declare function handleMessengerWebhookVerification(params: {
    url: URL;
    verifyToken: string;
    res: ServerResponse;
    log?: (message: string) => void;
}): boolean;
export declare function extractMessengerImageAttachmentUrls(event: MessengerWebhookMessaging): string[];
export declare function normalizeMessengerAttachmentKind(type: string | undefined): MessengerAttachmentKind;
export declare function extractMessengerAttachmentUrls(event: MessengerWebhookMessaging): MessengerAttachmentUrl[];
export declare function extractMessengerInboundMessages(body: MessengerWebhookBody): MessengerWebhookMessaging[];
