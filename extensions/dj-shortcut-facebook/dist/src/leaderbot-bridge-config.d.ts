export declare const DEFAULT_IMAGE_GEN_URL = "https://leaderbot-fb-image-gen.fly.dev";
export declare const IMAGE_GEN_REQUEST_TIMEOUT_MS = 5000;
export type LeaderbotImageGenRequestConfig = {
    ok: true;
    endpoint: string;
    token: string;
} | {
    ok: false;
    reason: "disabled_by_config" | "missing_token" | "invalid_url";
};
export declare function resolveImageGenRequestConfig(params?: {
    leaderbotBridgeEnabled?: boolean;
}): LeaderbotImageGenRequestConfig;
