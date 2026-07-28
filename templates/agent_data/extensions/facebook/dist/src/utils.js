export function hasText(value) {
    return typeof value === "string" && value.trim().length > 0;
}
export function hasMessengerCredentials(account) {
    return Boolean(hasText(account.pageId) &&
        hasText(account.pageAccessToken) &&
        hasText(account.appSecret) &&
        hasText(account.verifyToken));
}
