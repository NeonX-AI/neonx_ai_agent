import type { OpenClawConfig } from "./channel-api.js";
import type { MessengerQuickReply } from "./messengerPresentationTypes.js";
import type { MessengerSendResult } from "./types.js";
export declare const MESSENGER_TEXT_MAX_LENGTH = 2000;
export declare const MESSENGER_TEXT_CHUNK_LIMIT = 2000;
type FetchLike = typeof fetch;
/** Returns true when the value looks like a local filesystem path rather than a public URL. */
export declare function isLocalImagePath(value: string): boolean;
export declare function sendMessengerText(to: string, text: string, opts: {
    cfg: OpenClawConfig;
    accountId?: string;
    fetch?: FetchLike;
    quickReplies?: readonly MessengerQuickReply[];
}): Promise<MessengerSendResult>;
export declare function sendMessengerImage(to: string, imageUrl: string, opts: {
    cfg: OpenClawConfig;
    accountId?: string;
    fetch?: FetchLike;
    readFile?: (path: string) => Promise<Buffer>;
}): Promise<MessengerSendResult>;
/**
 * Uploads a local image file to Messenger via the multipart `filedata` send
 * path. Use this when the image only exists on the local filesystem and no
 * public URL is available — Messenger rejects non-public attachment urls
 * with error (#100) "should represent a valid URL".
 */
export declare function sendMessengerImageFile(to: string, filePath: string, opts: {
    cfg: OpenClawConfig;
    accountId?: string;
    fetch?: FetchLike;
    readFile?: (path: string) => Promise<Buffer>;
}): Promise<MessengerSendResult>;
/**
 * Sends a text caption and an image as separate Messenger messages.
 * The Messenger Send API does not allow `text` and `attachment` in one
 * message, so a non-empty caption is delivered first, then the image.
 * Empty captions are skipped and only the image is sent.
 */
export declare function sendMessengerTextAndImage(to: string, text: string, imageUrl: string, opts: {
    cfg: OpenClawConfig;
    accountId?: string;
    fetch?: FetchLike;
    readFile?: (path: string) => Promise<Buffer>;
    quickReplies?: readonly MessengerQuickReply[];
}): Promise<{
    text?: MessengerSendResult;
    image: MessengerSendResult;
}>;
export declare function sendMessengerSenderAction(to: string, senderAction: "typing_on" | "typing_off" | "mark_seen", opts: {
    cfg: OpenClawConfig;
    accountId?: string;
    fetch?: FetchLike;
}): Promise<void>;
export {};
