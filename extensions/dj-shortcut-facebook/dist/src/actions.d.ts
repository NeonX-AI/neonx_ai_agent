import type { ChannelMessageActionAdapter } from "openclaw/plugin-sdk/channel-contract";
/**
 * Channel-owned action surface for the shared `message` tool.
 *
 * The gateway routes `message(action="send", ...)` through
 * `plugin.actions.handleAction` - the durable `message` adapter
 * (`messengerMessageAdapter.send.media`) only covers agent-reply delivery.
 * Without this adapter the gateway rejects sends with
 * "Channel facebook does not support action send".
 */
export declare const messengerMessageActions: ChannelMessageActionAdapter;
