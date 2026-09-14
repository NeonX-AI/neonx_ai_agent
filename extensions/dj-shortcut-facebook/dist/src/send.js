import { readFile } from "node:fs/promises";
import { basename } from "node:path";
import { fileURLToPath } from "node:url";
import { formatErrorMessage } from "openclaw/plugin-sdk/error-runtime";
import { resolveMessengerAccount } from "./accounts.js";
import { stripFacebookTargetPrefix } from "./naming.js";
import { createMessengerSendReceipt } from "./send-receipt.js";
const DEFAULT_GRAPH_API_VERSION = "v20.0";
const MESSENGER_SEND_TIMEOUT_MS = 10_000;
const MESSENGER_UPLOAD_TIMEOUT_MS = 30_000;
/** Messenger rejects image attachments larger than 8 MB. */
const MESSENGER_IMAGE_MAX_BYTES = 8 * 1024 * 1024;
export const MESSENGER_TEXT_MAX_LENGTH = 2000;
export const MESSENGER_TEXT_CHUNK_LIMIT = MESSENGER_TEXT_MAX_LENGTH;
const MESSENGER_IMAGE_CONTENT_TYPES = {
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".webp": "image/webp",
};
/** Returns true when the value looks like a local filesystem path rather than a public URL. */
export function isLocalImagePath(value) {
    const trimmed = value.trim();
    if (!trimmed) {
        return false;
    }
    if (/^https?:\/\//i.test(trimmed)) {
        return false;
    }
    return (trimmed.startsWith("file://") ||
        trimmed.startsWith("/") ||
        trimmed.startsWith("./") ||
        trimmed.startsWith("../") ||
        trimmed.startsWith("~"));
}
function resolveLocalImagePath(value) {
    const trimmed = value.trim();
    if (trimmed.startsWith("file://")) {
        return fileURLToPath(new URL(trimmed));
    }
    return trimmed;
}
function contentTypeForImagePath(filePath) {
    const extension = filePath.slice(filePath.lastIndexOf(".")).toLowerCase();
    return MESSENGER_IMAGE_CONTENT_TYPES[extension] ?? "application/octet-stream";
}
function resolveGraphApiVersion(value) {
    const trimmed = value?.trim();
    return trimmed || DEFAULT_GRAPH_API_VERSION;
}
function formatMessengerApiError(body) {
    const error = body && typeof body === "object" ? body.error : undefined;
    if (!error || typeof error !== "object") {
        return "Messenger API request failed";
    }
    const details = error;
    const message = details.message?.trim() || "Messenger API request failed";
    if (details.code === 190) {
        return `Messenger Page access token is invalid or expired: ${message}`;
    }
    if (details.code === 4 || details.code === 613) {
        return `Messenger API rate limit reached: ${message}`;
    }
    if (details.code === 10 && details.error_subcode === 2534022) {
        return `Messenger cannot send outside the 24-hour response window: ${message}`;
    }
    if (details.code === 200) {
        return `Messenger permission or app review issue: ${message}`;
    }
    if (details.code === 551 || details.error_subcode === 1545041) {
        return `Messenger recipient is unavailable: ${message}`;
    }
    return `Messenger API error${details.code ? ` ${details.code}` : ""}: ${message}`;
}
function normalizeMessengerQuickReplies(quickReplies) {
    if (!quickReplies?.length) {
        return undefined;
    }
    return quickReplies.map((quickReply) => ({
        content_type: quickReply.content_type,
        title: quickReply.title,
        payload: quickReply.payload,
    }));
}
function normalizeMessengerText(text) {
    if (text.length <= MESSENGER_TEXT_MAX_LENGTH) {
        return text;
    }
    return text.slice(0, MESSENGER_TEXT_MAX_LENGTH);
}
export async function sendMessengerText(to, text, opts) {
    const account = resolveMessengerAccount({ cfg: opts.cfg, accountId: opts.accountId });
    if (!account.pageId.trim()) {
        throw new Error(`Messenger pageId missing for account "${account.accountId}".`);
    }
    if (!account.pageAccessToken.trim()) {
        throw new Error(`Messenger Page access token missing for account "${account.accountId}".`);
    }
    const normalizedTo = stripFacebookTargetPrefix(to) || to.trim();
    if (!normalizedTo) {
        throw new Error(`Messenger recipient id missing for account "${account.accountId}".`);
    }
    const fetchImpl = opts.fetch ?? fetch;
    const normalizedText = normalizeMessengerText(text);
    const quickReplies = normalizeMessengerQuickReplies(opts.quickReplies);
    const version = resolveGraphApiVersion(account.config.graphApiVersion);
    const url = `https://graph.facebook.com/${version}/${encodeURIComponent(account.pageId)}/messages`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), MESSENGER_SEND_TIMEOUT_MS);
    let response;
    try {
        response = await fetchImpl(url, {
            method: "POST",
            signal: controller.signal,
            headers: {
                Authorization: `Bearer ${account.pageAccessToken}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                recipient: { id: normalizedTo },
                messaging_type: "RESPONSE",
                message: {
                    text: normalizedText,
                    ...(quickReplies ? { quick_replies: quickReplies } : {}),
                },
            }),
        });
    }
    catch (error) {
        throw new Error(`Messenger send failed: ${formatErrorMessage(error)}`, { cause: error });
    }
    finally {
        clearTimeout(timeout);
    }
    const body = (await response.json().catch(() => null));
    if (!response.ok) {
        throw new Error(formatMessengerApiError(body));
    }
    const result = body;
    const messageId = result.message_id?.trim();
    const recipientId = result.recipient_id?.trim();
    if (!messageId || !recipientId) {
        throw new Error("Messenger send succeeded but response did not include message_id and recipient_id.");
    }
    return {
        messageId,
        recipientId,
        receipt: createMessengerSendReceipt({ messageId, recipientId }),
    };
}
export async function sendMessengerImage(to, imageUrl, opts) {
    const normalizedImageUrl = imageUrl.trim();
    if (!normalizedImageUrl) {
        throw new Error(`Messenger image url missing for account "${opts.accountId ?? "default"}".`);
    }
    if (isLocalImagePath(normalizedImageUrl)) {
        return sendMessengerImageFile(to, normalizedImageUrl, opts);
    }
    const account = resolveMessengerAccount({ cfg: opts.cfg, accountId: opts.accountId });
    if (!account.pageId.trim()) {
        throw new Error(`Messenger pageId missing for account "${account.accountId}".`);
    }
    if (!account.pageAccessToken.trim()) {
        throw new Error(`Messenger Page access token missing for account "${account.accountId}".`);
    }
    const normalizedTo = stripFacebookTargetPrefix(to) || to.trim();
    if (!normalizedTo) {
        throw new Error(`Messenger recipient id missing for account "${account.accountId}".`);
    }
    const fetchImpl = opts.fetch ?? fetch;
    const version = resolveGraphApiVersion(account.config.graphApiVersion);
    const url = `https://graph.facebook.com/${version}/${encodeURIComponent(account.pageId)}/messages`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), MESSENGER_SEND_TIMEOUT_MS);
    let response;
    try {
        response = await fetchImpl(url, {
            method: "POST",
            signal: controller.signal,
            headers: {
                Authorization: `Bearer ${account.pageAccessToken}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                recipient: { id: normalizedTo },
                messaging_type: "RESPONSE",
                message: {
                    attachment: {
                        type: "image",
                        payload: {
                            url: normalizedImageUrl,
                            is_reusable: false,
                        },
                    },
                },
            }),
        });
    }
    catch (error) {
        throw new Error(`Messenger image send failed: ${formatErrorMessage(error)}`, {
            cause: error,
        });
    }
    finally {
        clearTimeout(timeout);
    }
    return parseMessengerSendResponse(response, "image send");
}
/**
 * Uploads a local image file to Messenger via the multipart `filedata` send
 * path. Use this when the image only exists on the local filesystem and no
 * public URL is available — Messenger rejects non-public attachment urls
 * with error (#100) "should represent a valid URL".
 */
export async function sendMessengerImageFile(to, filePath, opts) {
    const account = resolveMessengerAccount({ cfg: opts.cfg, accountId: opts.accountId });
    if (!account.pageId.trim()) {
        throw new Error(`Messenger pageId missing for account "${account.accountId}".`);
    }
    if (!account.pageAccessToken.trim()) {
        throw new Error(`Messenger Page access token missing for account "${account.accountId}".`);
    }
    const normalizedTo = stripFacebookTargetPrefix(to) || to.trim();
    if (!normalizedTo) {
        throw new Error(`Messenger recipient id missing for account "${account.accountId}".`);
    }
    const resolvedPath = resolveLocalImagePath(filePath);
    const readImpl = opts.readFile ?? readFile;
    let fileBuffer;
    try {
        fileBuffer = await readImpl(resolvedPath);
    }
    catch (error) {
        throw new Error(`Messenger image file could not be read: ${resolvedPath}`, { cause: error });
    }
    if (fileBuffer.byteLength === 0) {
        throw new Error(`Messenger image file is empty: ${resolvedPath}`);
    }
    if (fileBuffer.byteLength > MESSENGER_IMAGE_MAX_BYTES) {
        throw new Error(`Messenger image file exceeds the 8 MB limit (${fileBuffer.byteLength} bytes): ${resolvedPath}`);
    }
    const fetchImpl = opts.fetch ?? fetch;
    const version = resolveGraphApiVersion(account.config.graphApiVersion);
    const url = `https://graph.facebook.com/${version}/${encodeURIComponent(account.pageId)}/messages`;
    const form = new FormData();
    form.append("recipient", JSON.stringify({ id: normalizedTo }));
    form.append("messaging_type", "RESPONSE");
    form.append("message", JSON.stringify({
        attachment: {
            type: "image",
            payload: { is_reusable: false },
        },
    }));
    form.append("filedata", new Blob([new Uint8Array(fileBuffer)], { type: contentTypeForImagePath(resolvedPath) }), basename(resolvedPath) || "image.png");
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), MESSENGER_UPLOAD_TIMEOUT_MS);
    let response;
    try {
        response = await fetchImpl(url, {
            method: "POST",
            signal: controller.signal,
            headers: {
                Authorization: `Bearer ${account.pageAccessToken}`,
            },
            body: form,
        });
    }
    catch (error) {
        throw new Error(`Messenger image upload failed: ${formatErrorMessage(error)}`, {
            cause: error,
        });
    }
    finally {
        clearTimeout(timeout);
    }
    return parseMessengerSendResponse(response, "image upload");
}
async function parseMessengerSendResponse(response, operation) {
    const body = (await response.json().catch(() => null));
    if (!response.ok) {
        throw new Error(formatMessengerApiError(body));
    }
    const result = body;
    const messageId = result.message_id?.trim();
    const recipientId = result.recipient_id?.trim();
    if (!messageId || !recipientId) {
        throw new Error(`Messenger ${operation} succeeded but response did not include message_id and recipient_id.`);
    }
    return {
        messageId,
        recipientId,
        receipt: createMessengerSendReceipt({ messageId, recipientId }),
    };
}
/**
 * Sends a text caption and an image as separate Messenger messages.
 * The Messenger Send API does not allow `text` and `attachment` in one
 * message, so a non-empty caption is delivered first, then the image.
 * Empty captions are skipped and only the image is sent.
 */
export async function sendMessengerTextAndImage(to, text, imageUrl, opts) {
    const caption = text.trim();
    const textResult = caption ? await sendMessengerText(to, caption, opts) : undefined;
    const imageResult = await sendMessengerImage(to, imageUrl, opts);
    return { text: textResult, image: imageResult };
}
export async function sendMessengerSenderAction(to, senderAction, opts) {
    const account = resolveMessengerAccount({ cfg: opts.cfg, accountId: opts.accountId });
    if (!account.pageId.trim()) {
        throw new Error(`Messenger pageId missing for account "${account.accountId}".`);
    }
    if (!account.pageAccessToken.trim()) {
        throw new Error(`Messenger Page access token missing for account "${account.accountId}".`);
    }
    const normalizedTo = stripFacebookTargetPrefix(to) || to.trim();
    if (!normalizedTo) {
        throw new Error(`Messenger recipient id missing for account "${account.accountId}".`);
    }
    const fetchImpl = opts.fetch ?? fetch;
    const version = resolveGraphApiVersion(account.config.graphApiVersion);
    const url = `https://graph.facebook.com/${version}/${encodeURIComponent(account.pageId)}/messages`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), MESSENGER_SEND_TIMEOUT_MS);
    let response;
    try {
        response = await fetchImpl(url, {
            method: "POST",
            signal: controller.signal,
            headers: {
                Authorization: `Bearer ${account.pageAccessToken}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                recipient: { id: normalizedTo },
                sender_action: senderAction,
            }),
        });
    }
    catch (error) {
        throw new Error(`Messenger sender action failed: ${formatErrorMessage(error)}`, {
            cause: error,
        });
    }
    finally {
        clearTimeout(timeout);
    }
    const body = (await response.json().catch(() => null));
    if (!response.ok) {
        throw new Error(formatMessengerApiError(body));
    }
}
