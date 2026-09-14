import type { OpenClawConfig } from "openclaw/plugin-sdk/account-resolution";
import type { MessengerConfig } from "./types.js";
export declare const FACEBOOK_CHANNEL_ID = "facebook";
export declare const LEGACY_MESSENGER_CHANNEL_ID = "messenger";
export declare const DEFAULT_FACEBOOK_WEBHOOK_PATH = "/facebook/webhook";
export declare const LEGACY_MESSENGER_WEBHOOK_PATH = "/messenger/webhook";
export declare const FACEBOOK_ENV_KEYS: {
    readonly pageId: "FACEBOOK_PAGE_ID";
    readonly pageAccessToken: "FACEBOOK_PAGE_ACCESS_TOKEN";
    readonly appSecret: "FACEBOOK_APP_SECRET";
    readonly verifyToken: "FACEBOOK_VERIFY_TOKEN";
};
export declare const LEGACY_MESSENGER_ENV_KEYS: {
    readonly pageId: "MESSENGER_PAGE_ID";
    readonly pageAccessToken: "MESSENGER_PAGE_ACCESS_TOKEN";
    readonly appSecret: "MESSENGER_APP_SECRET";
    readonly verifyToken: "MESSENGER_VERIFY_TOKEN";
};
export declare function readFacebookEnv(key: keyof typeof FACEBOOK_ENV_KEYS, env?: NodeJS.ProcessEnv): string;
export declare function hasFacebookConfiguredEnv(env?: Record<string, string | undefined>): boolean;
export declare function resolveFacebookConfig(cfg: OpenClawConfig): {
    config?: MessengerConfig;
    key: typeof FACEBOOK_CHANNEL_ID | typeof LEGACY_MESSENGER_CHANNEL_ID;
};
export declare function stripFacebookTargetPrefix(value: string): string;
