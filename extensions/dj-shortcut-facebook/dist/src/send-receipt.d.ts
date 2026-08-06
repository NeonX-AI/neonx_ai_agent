import type { MessageReceipt } from "openclaw/plugin-sdk/channel-message";
export declare function createMessengerSendReceipt(params: {
    messageId: string;
    recipientId: string;
}): MessageReceipt;
