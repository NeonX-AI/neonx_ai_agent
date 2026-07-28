import type { ResolvedMessengerAccount } from "./types.js";
export declare const messengerConfigAdapter: {
    listAccountIds: (cfg: import("openclaw/plugin-sdk/core").OpenClawConfig) => string[];
    resolveAccount: (cfg: import("openclaw/plugin-sdk/core").OpenClawConfig, accountId?: string | null) => ResolvedMessengerAccount;
    inspectAccount?: (cfg: import("openclaw/plugin-sdk/core").OpenClawConfig, accountId?: string | null) => unknown;
    defaultAccountId?: (cfg: import("openclaw/plugin-sdk/core").OpenClawConfig) => string;
    setAccountEnabled?: (params: {
        cfg: import("openclaw/plugin-sdk/core").OpenClawConfig;
        accountId: string;
        enabled: boolean;
    }) => import("openclaw/plugin-sdk/core").OpenClawConfig;
    deleteAccount?: (params: {
        cfg: import("openclaw/plugin-sdk/core").OpenClawConfig;
        accountId: string;
    }) => import("openclaw/plugin-sdk/core").OpenClawConfig;
    resolveAllowFrom?: (params: {
        cfg: import("openclaw/plugin-sdk/core").OpenClawConfig;
        accountId?: string | null;
    }) => Array<string | number> | undefined;
    formatAllowFrom?: (params: {
        cfg: import("openclaw/plugin-sdk/core").OpenClawConfig;
        accountId?: string | null;
        allowFrom: Array<string | number>;
    }) => string[];
    resolveDefaultTo?: (params: {
        cfg: import("openclaw/plugin-sdk/core").OpenClawConfig;
        accountId?: string | null;
    }) => string | undefined;
};
