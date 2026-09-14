export const FACEBOOK_CHANNEL_ID = "facebook";
export const LEGACY_MESSENGER_CHANNEL_ID = "messenger";
export const DEFAULT_FACEBOOK_WEBHOOK_PATH = "/facebook/webhook";
export const LEGACY_MESSENGER_WEBHOOK_PATH = "/messenger/webhook";
export const FACEBOOK_ENV_KEYS = {
    pageId: "FACEBOOK_PAGE_ID",
    pageAccessToken: "FACEBOOK_PAGE_ACCESS_TOKEN",
    appSecret: "FACEBOOK_APP_SECRET",
    verifyToken: "FACEBOOK_VERIFY_TOKEN",
};
export const LEGACY_MESSENGER_ENV_KEYS = {
    pageId: "MESSENGER_PAGE_ID",
    pageAccessToken: "MESSENGER_PAGE_ACCESS_TOKEN",
    appSecret: "MESSENGER_APP_SECRET",
    verifyToken: "MESSENGER_VERIFY_TOKEN",
};
export function readFacebookEnv(key, env = process.env) {
    return env[FACEBOOK_ENV_KEYS[key]]?.trim() ?? env[LEGACY_MESSENGER_ENV_KEYS[key]]?.trim() ?? "";
}
export function hasFacebookConfiguredEnv(env = process.env) {
    return Boolean((env.FACEBOOK_PAGE_ID?.trim() || env.MESSENGER_PAGE_ID?.trim()) &&
        (env.FACEBOOK_PAGE_ACCESS_TOKEN?.trim() || env.MESSENGER_PAGE_ACCESS_TOKEN?.trim()) &&
        (env.FACEBOOK_APP_SECRET?.trim() || env.MESSENGER_APP_SECRET?.trim()) &&
        (env.FACEBOOK_VERIFY_TOKEN?.trim() || env.MESSENGER_VERIFY_TOKEN?.trim()));
}
export function resolveFacebookConfig(cfg) {
    const channels = cfg.channels;
    if (channels?.[FACEBOOK_CHANNEL_ID]) {
        return { config: channels[FACEBOOK_CHANNEL_ID], key: FACEBOOK_CHANNEL_ID };
    }
    return {
        config: channels?.[LEGACY_MESSENGER_CHANNEL_ID],
        key: LEGACY_MESSENGER_CHANNEL_ID,
    };
}
export function stripFacebookTargetPrefix(value) {
    return value
        .trim()
        .replace(/^facebook:(?:user:)?/i, "")
        .replace(/^fb:/i, "")
        .replace(/^messenger:(?:user:)?/i, "")
        .replace(/^fbm:/i, "");
}
