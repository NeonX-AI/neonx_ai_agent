import type { ChannelSetupAdapter, OpenClawConfig } from "openclaw/plugin-sdk/setup";
import { listMessengerAccountIds } from "./channel-api.js";
export declare function patchMessengerAccountConfig(params: {
    cfg: OpenClawConfig;
    accountId: string;
    patch: Record<string, unknown>;
    clearFields?: string[];
    enabled?: boolean;
}): OpenClawConfig;
export declare function isMessengerConfigured(cfg: OpenClawConfig, accountId: string): boolean;
export declare function parseMessengerAllowFromId(value: string): string | null;
export declare const messengerSetupAdapter: ChannelSetupAdapter;
export { listMessengerAccountIds };
