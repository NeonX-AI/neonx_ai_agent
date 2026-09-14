export type MessengerFastLaneIntent = "greeting" | "help" | "status" | "image" | "delete_data";
export declare function normalizeFastLaneText(text: string): string;
export declare function classifyMessengerFastLaneIntent(text: string): MessengerFastLaneIntent | null;
export declare function hasMessengerImageGenerationIntent(text: string): boolean;
export declare function shouldForwardMessengerTextToImageGen(text: string): boolean;
type MessengerConversationIntentKind = "greeting" | "help" | "status" | "generate_image" | "edit_source_image" | "analyze_image" | "write_prompt" | "unknown";
export type MessengerConversationIntent = {
    kind: MessengerConversationIntentKind;
    confidence: number;
    prompt?: string;
};
export declare function hasMessengerSourceImageEditIntent(text: string): boolean;
export declare function resolveMessengerConversationIntent(params: {
    text: string;
    hasSourceImage?: boolean;
}): MessengerConversationIntent;
export declare function resolveMessengerSourceImageGenerationPrompt(params: {
    hasSourceImage: boolean;
    text: string;
}): string | null;
export declare function shouldForwardMessengerImageOnlyEventToImageGen(params: {
    hasSourceImage: boolean;
    text: string;
}): boolean;
export declare function resolveMessengerFastLaneReply(text: string): {
    intent: MessengerFastLaneIntent;
    reply: string;
} | null;
export {};
