export function hasText(value) {
    return typeof value === "string" && value.trim().length > 0;
}
export function trimToCodePoints(value, maxLength) {
    return Array.from(value.trim()).slice(0, maxLength).join("").trim();
}
export function stripMessengerMarkdown(value) {
    return value
        .replace(/```[a-z0-9_-]*\s*([\s\S]*?)```/giu, "$1")
        .replace(/`([^`]+)`/gu, "$1")
        .replace(/\*\*([^*]+)\*\*/gu, "$1")
        .replace(/__([^_]+)__/gu, "$1")
        .replace(/\*([^*\n]+)\*/gu, "$1")
        .replace(/_([^_\n]+)_/gu, "$1")
        .replace(/~~([^~]+)~~/gu, "$1")
        .replace(/^#{1,6}\s+/gmu, "")
        .trim();
}
export function utf8ByteLength(value) {
    return new TextEncoder().encode(value).byteLength;
}
