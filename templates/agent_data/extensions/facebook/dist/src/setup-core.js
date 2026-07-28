import { createSetupInputPresenceValidator } from "openclaw/plugin-sdk/setup";
import { DEFAULT_ACCOUNT_ID, listMessengerAccountIds, normalizeAccountId, resolveMessengerAccount, } from "./channel-api.js";
import { hasMessengerCredentials } from "./utils.js";
import { FACEBOOK_CHANNEL_ID, resolveFacebookConfig, stripFacebookTargetPrefix } from "./naming.js";
export function patchMessengerAccountConfig(params) {
    const accountId = normalizeAccountId(params.accountId);
    const { config: messengerConfig = {} } = resolveFacebookConfig(params.cfg);
    const clearFields = params.clearFields ?? [];
    if (accountId === DEFAULT_ACCOUNT_ID) {
        const nextMessenger = { ...messengerConfig };
        for (const field of clearFields) {
            delete nextMessenger[field];
        }
        return {
            ...params.cfg,
            channels: {
                ...params.cfg.channels,
                [FACEBOOK_CHANNEL_ID]: {
                    ...nextMessenger,
                    ...(params.enabled ? { enabled: true } : {}),
                    ...params.patch,
                },
            },
        };
    }
    const nextAccount = { ...messengerConfig.accounts?.[accountId] };
    for (const field of clearFields) {
        delete nextAccount[field];
    }
    return {
        ...params.cfg,
        channels: {
            ...params.cfg.channels,
            [FACEBOOK_CHANNEL_ID]: {
                ...messengerConfig,
                ...(params.enabled ? { enabled: true } : {}),
                accounts: {
                    ...messengerConfig.accounts,
                    [accountId]: {
                        ...nextAccount,
                        ...(params.enabled ? { enabled: true } : {}),
                        ...params.patch,
                    },
                },
            },
        },
    };
}
export function isMessengerConfigured(cfg, accountId) {
    return hasMessengerCredentials(resolveMessengerAccount({ cfg, accountId }));
}
export function parseMessengerAllowFromId(value) {
    const normalized = stripFacebookTargetPrefix(value);
    return normalized || null;
}
export const messengerSetupAdapter = {
    resolveAccountId: ({ accountId }) => normalizeAccountId(accountId),
    applyAccountName: ({ cfg, accountId, name }) => patchMessengerAccountConfig({
        cfg,
        accountId,
        patch: name?.trim() ? { name: name.trim() } : {},
    }),
    validateInput: createSetupInputPresenceValidator({
        defaultAccountOnlyEnvError: "FACEBOOK_* env vars can only be used for the default Facebook account.",
        whenNotUseEnv: [
            {
                someOf: ["pageId"],
                message: "Facebook requires pageId (or --use-env).",
            },
            {
                someOf: ["pageAccessToken", "tokenFile"],
                message: "Facebook requires pageAccessToken or --token-file (or --use-env).",
            },
            {
                someOf: ["appSecret", "appSecretFile"],
                message: "Facebook requires appSecret or --app-secret-file (or --use-env).",
            },
            {
                someOf: ["verifyToken", "verifyTokenFile"],
                message: "Facebook requires verifyToken or --verify-token-file (or --use-env).",
            },
        ],
    }),
    applyAccountConfig: ({ cfg, accountId, input }) => {
        const typedInput = input;
        return patchMessengerAccountConfig({
            cfg,
            accountId,
            enabled: true,
            clearFields: typedInput.useEnv
                ? [
                    "pageId",
                    "pageAccessToken",
                    "tokenFile",
                    "appSecret",
                    "appSecretFile",
                    "verifyToken",
                    "verifyTokenFile",
                ]
                : undefined,
            patch: typedInput.useEnv
                ? {}
                : {
                    ...(typedInput.pageId ? { pageId: typedInput.pageId } : {}),
                    ...(typedInput.tokenFile
                        ? { tokenFile: typedInput.tokenFile }
                        : typedInput.pageAccessToken
                            ? { pageAccessToken: typedInput.pageAccessToken }
                            : {}),
                    ...(typedInput.appSecretFile
                        ? { appSecretFile: typedInput.appSecretFile }
                        : typedInput.appSecret
                            ? { appSecret: typedInput.appSecret }
                            : {}),
                    ...(typedInput.verifyTokenFile
                        ? { verifyTokenFile: typedInput.verifyTokenFile }
                        : typedInput.verifyToken
                            ? { verifyToken: typedInput.verifyToken }
                            : {}),
                },
        });
    },
};
export { listMessengerAccountIds };
