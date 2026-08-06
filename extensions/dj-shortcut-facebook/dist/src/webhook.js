function isPageWebhookBody(body) {
    return body.object === "page";
}
function hasMessengerEventParticipants(event) {
    return Boolean(event.sender?.id && event.recipient?.id);
}
function getMessengerMessagingEvents(body) {
    return isPageWebhookBody(body) ? (body.entry ?? []).flatMap((entry) => entry.messaging ?? []) : [];
}
function hasMessengerInboundContent(event) {
    if (event.message?.is_echo || !hasMessengerEventParticipants(event)) {
        return false;
    }
    const text = event.message?.text?.trim();
    const payload = event.message?.quick_reply?.payload?.trim() ?? event.postback?.payload?.trim();
    const hasAttachments = (event.message?.attachments?.length ?? 0) > 0;
    return Boolean(text || payload || hasAttachments);
}
export function handleMessengerWebhookVerification(params) {
    if (params.url.searchParams.get("hub.mode") !== "subscribe") {
        params.log?.("messenger webhook verification rejected: unsupported mode");
        params.res.statusCode = 403;
        params.res.end("Forbidden");
        return true;
    }
    if (params.url.searchParams.get("hub.verify_token") !== params.verifyToken) {
        params.log?.("messenger webhook verification rejected: verify token mismatch");
        params.res.statusCode = 403;
        params.res.end("Forbidden");
        return true;
    }
    params.log?.("messenger webhook verification accepted");
    params.res.statusCode = 200;
    params.res.setHeader("Content-Type", "text/plain");
    params.res.end(params.url.searchParams.get("hub.challenge") ?? "");
    return true;
}
export function extractMessengerImageAttachmentUrls(event) {
    return extractMessengerAttachmentUrls(event)
        .filter((attachment) => attachment.kind === "image")
        .map((attachment) => attachment.url);
}
export function normalizeMessengerAttachmentKind(type) {
    const normalized = type?.trim().toLowerCase();
    switch (normalized) {
        case "image":
            return "image";
        case "audio":
            return "audio";
        case "video":
            return "video";
        case "file":
            return "file";
        default:
            return "unknown";
    }
}
export function extractMessengerAttachmentUrls(event) {
    return (event.message?.attachments ?? [])
        .map((attachment) => ({
        type: attachment.type?.trim().toLowerCase() || "unknown",
        kind: normalizeMessengerAttachmentKind(attachment.type),
        url: attachment.payload?.url?.trim() ?? "",
    }))
        .filter((attachment) => attachment.url.length > 0);
}
export function extractMessengerInboundMessages(body) {
    return getMessengerMessagingEvents(body).filter(hasMessengerInboundContent);
}
