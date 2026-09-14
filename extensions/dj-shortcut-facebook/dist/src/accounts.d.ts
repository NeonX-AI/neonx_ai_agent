import type { OpenClawConfig } from "openclaw/plugin-sdk/account-resolution";
import type { ResolvedMessengerAccount } from "./types.js";
export { DEFAULT_ACCOUNT_ID } from "openclaw/plugin-sdk/account-id";
export declare function resolveMessengerAccount(params: {
    cfg: OpenClawConfig;
    accountId?: string | null;
}): ResolvedMessengerAccount;
export declare function listMessengerAccountIds(cfg: OpenClawConfig): string[];
export declare function resolveDefaultMessengerAccountId(cfg: OpenClawConfig): string;
export declare function normalizeAccountId(accountId: string | undefined): string;
