import type { ChannelPlugin } from "openclaw/plugin-sdk/core";
import { z } from "zod";
import type { ResolvedMessengerAccount } from "./types.js";
export declare const MessengerConfigSchema: z.ZodObject<{
    enabled: z.ZodOptional<z.ZodBoolean>;
    pageId: z.ZodOptional<z.ZodString>;
    pageAccessToken: z.ZodOptional<z.ZodString>;
    tokenFile: z.ZodOptional<z.ZodString>;
    appSecret: z.ZodOptional<z.ZodString>;
    appSecretFile: z.ZodOptional<z.ZodString>;
    verifyToken: z.ZodOptional<z.ZodString>;
    verifyTokenFile: z.ZodOptional<z.ZodString>;
    name: z.ZodOptional<z.ZodString>;
    allowFrom: z.ZodOptional<z.ZodArray<z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>>>;
    dmPolicy: z.ZodDefault<z.ZodOptional<z.ZodEnum<{
        allowlist: "allowlist";
        disabled: "disabled";
        open: "open";
        pairing: "pairing";
    }>>>;
    unknownSenderMode: z.ZodOptional<z.ZodEnum<{
        leaderbot_free_tier: "leaderbot_free_tier";
        pairing: "pairing";
    }>>;
    leaderbotBridgeEnabled: z.ZodDefault<z.ZodOptional<z.ZodBoolean>>;
    responsePrefix: z.ZodOptional<z.ZodString>;
    webhookPath: z.ZodOptional<z.ZodString>;
    defaultTo: z.ZodOptional<z.ZodString>;
    graphApiVersion: z.ZodOptional<z.ZodString>;
    accounts: z.ZodOptional<z.ZodRecord<z.ZodString, z.ZodOptional<z.ZodObject<{
        enabled: z.ZodOptional<z.ZodBoolean>;
        pageId: z.ZodOptional<z.ZodString>;
        pageAccessToken: z.ZodOptional<z.ZodString>;
        tokenFile: z.ZodOptional<z.ZodString>;
        appSecret: z.ZodOptional<z.ZodString>;
        appSecretFile: z.ZodOptional<z.ZodString>;
        verifyToken: z.ZodOptional<z.ZodString>;
        verifyTokenFile: z.ZodOptional<z.ZodString>;
        name: z.ZodOptional<z.ZodString>;
        allowFrom: z.ZodOptional<z.ZodArray<z.ZodUnion<readonly [z.ZodString, z.ZodNumber]>>>;
        dmPolicy: z.ZodDefault<z.ZodOptional<z.ZodEnum<{
            allowlist: "allowlist";
            disabled: "disabled";
            open: "open";
            pairing: "pairing";
        }>>>;
        unknownSenderMode: z.ZodOptional<z.ZodEnum<{
            leaderbot_free_tier: "leaderbot_free_tier";
            pairing: "pairing";
        }>>;
        responsePrefix: z.ZodOptional<z.ZodString>;
        webhookPath: z.ZodOptional<z.ZodString>;
        defaultTo: z.ZodOptional<z.ZodString>;
        graphApiVersion: z.ZodOptional<z.ZodString>;
        leaderbotBridgeEnabled: z.ZodOptional<z.ZodBoolean>;
    }, z.core.$strict>>>>;
    defaultAccount: z.ZodOptional<z.ZodString>;
}, z.core.$strict>;
export declare const MessengerChannelConfigSchema: NonNullable<ChannelPlugin<ResolvedMessengerAccount>["configSchema"]>;
export type MessengerConfigSchemaType = z.infer<typeof MessengerConfigSchema>;
