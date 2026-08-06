import { formatAllowFromLowercase } from "openclaw/plugin-sdk/allow-from";
import { adaptScopedAccountAccessor, createScopedChannelConfigAdapter, } from "openclaw/plugin-sdk/channel-config-helpers";
import { listMessengerAccountIds, resolveDefaultMessengerAccountId, resolveMessengerAccount, } from "./accounts.js";
import { inspectMessengerAccount } from "./inspect.js";
import { FACEBOOK_CHANNEL_ID } from "./naming.js";
function resolveMessengerConfigAccessorAccount(params) {
    return {
        config: resolveMessengerAccount({ cfg: params.cfg, accountId: params.accountId ?? undefined })
            .config,
    };
}
export const messengerConfigAdapter = createScopedChannelConfigAdapter({
    sectionKey: FACEBOOK_CHANNEL_ID,
    listAccountIds: listMessengerAccountIds,
    resolveAccount: adaptScopedAccountAccessor(resolveMessengerAccount),
    resolveAccessorAccount: resolveMessengerConfigAccessorAccount,
    inspectAccount: adaptScopedAccountAccessor(inspectMessengerAccount),
    defaultAccountId: resolveDefaultMessengerAccountId,
    clearBaseFields: [
        "pageId",
        "pageAccessToken",
        "tokenFile",
        "appSecret",
        "appSecretFile",
        "verifyToken",
        "verifyTokenFile",
        "name",
    ],
    resolveAllowFrom: (account) => account.config.allowFrom,
    formatAllowFrom: (allowFrom) => formatAllowFromLowercase({
        allowFrom,
        stripPrefixRe: /^(?:facebook|fb|messenger|fbm):(?:user:)?/i,
    }),
    resolveDefaultTo: (account) => account.config.defaultTo,
});
