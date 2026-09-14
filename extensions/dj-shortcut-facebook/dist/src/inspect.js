import { resolveMessengerAccount } from "./accounts.js";
import { hasMessengerCredentials } from "./utils.js";
export function inspectMessengerAccount(params) {
    const account = resolveMessengerAccount(params);
    return {
        accountId: account.accountId,
        name: account.name,
        enabled: account.enabled,
        configured: hasMessengerCredentials(account),
        tokenStatus: account.tokenSource === "none" ? "missing" : "available",
        tokenSource: account.tokenSource,
    };
}
