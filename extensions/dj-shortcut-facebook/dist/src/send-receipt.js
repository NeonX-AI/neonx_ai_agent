export function createMessengerSendReceipt(params) {
    return {
        primaryPlatformMessageId: params.messageId,
        platformMessageIds: [params.messageId],
        parts: [
            {
                kind: "text",
                platformMessageId: params.messageId,
                index: 0,
            },
        ],
        sentAt: Date.now(),
    };
}
