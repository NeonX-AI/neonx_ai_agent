import { type ChannelMessageSendResult } from "openclaw/plugin-sdk/channel-message";
import { type ChannelPlugin, type ResolvedMessengerAccount } from "./channel-api.js";
export declare const messengerOutboundAdapter: NonNullable<ChannelPlugin<ResolvedMessengerAccount>["outbound"]>;
export declare const messengerMessageAdapter: {
    readonly id: "facebook";
    readonly durableFinal: {
        readonly capabilities: {
            readonly text: true;
            readonly media: true;
            readonly messageSendingHooks: true;
        };
    };
    readonly send: {
        readonly text: ({ cfg, to, text, accountId }: import("openclaw/plugin-sdk/channel-message").ChannelMessageSendTextContext<import("openclaw/plugin-sdk/channel-core").OpenClawConfig>) => Promise<ChannelMessageSendResult>;
        readonly media: ({ cfg, to, mediaUrl, accountId }: import("openclaw/plugin-sdk/channel-message").ChannelMessageSendMediaContext<import("openclaw/plugin-sdk/channel-core").OpenClawConfig>) => Promise<{
            messageId: string;
            receipt: import("openclaw/plugin-sdk/channel-message").MessageReceipt;
        }>;
    };
    readonly receive: {
        readonly defaultAckPolicy: "after_agent_dispatch";
        readonly supportedAckPolicies: readonly ["after_receive_record", "after_agent_dispatch"];
    };
} & {
    receive: {
        readonly defaultAckPolicy: "after_agent_dispatch";
        readonly supportedAckPolicies: readonly ["after_receive_record", "after_agent_dispatch"];
    };
};
