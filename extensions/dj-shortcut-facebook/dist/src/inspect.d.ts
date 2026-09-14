import type { OpenClawConfig } from "openclaw/plugin-sdk/account-resolution";
export declare function inspectMessengerAccount(params: {
    cfg: OpenClawConfig;
    accountId?: string | null;
}): {
    accountId: string;
    name: string | undefined;
    enabled: boolean;
    configured: boolean;
    tokenStatus: "available" | "missing";
    tokenSource: import("./types.js").MessengerTokenSource;
};
