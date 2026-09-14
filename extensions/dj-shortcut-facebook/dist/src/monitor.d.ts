import { type ChannelInboundMediaInput } from "openclaw/plugin-sdk/channel-inbound";
import type { OpenClawConfig } from "openclaw/plugin-sdk/config-contracts";
import type { ReplyPayload } from "openclaw/plugin-sdk/reply-payload";
import { type RuntimeEnv } from "openclaw/plugin-sdk/runtime-env";
import { type LeaderbotBridgeTrace } from "./leaderbot-bridge.js";
import type { MessengerWebhookMessaging, ResolvedMessengerAccount } from "./types.js";
import { type MessengerAttachmentUrl } from "./webhook.js";
export { DEFAULT_IMAGE_GEN_URL, IMAGE_GEN_REQUEST_TIMEOUT_MS, forwardLeaderbotMessengerEvent, requestLeaderbotImageGeneration, resolveImageGenRequestConfig, type LeaderbotBridgeTrace, } from "./leaderbot-bridge.js";
export { classifyMessengerFastLaneIntent, hasMessengerImageGenerationIntent, hasMessengerSourceImageEditIntent, resolveMessengerConversationIntent, resolveMessengerFastLaneReply, resolveMessengerSourceImageGenerationPrompt, shouldForwardMessengerImageOnlyEventToImageGen, shouldForwardMessengerTextToImageGen, type MessengerConversationIntent, } from "./messenger-product-intents.js";
export interface MonitorMessengerProviderOptions {
    account: ResolvedMessengerAccount;
    config: OpenClawConfig;
    runtime: RuntimeEnv;
    abortSignal?: AbortSignal;
    webhookPath?: string;
}
export type MessengerWebhookTarget = {
    account: ResolvedMessengerAccount;
    path: string;
    runtime: RuntimeEnv;
};
type MessengerTrace = LeaderbotBridgeTrace;
export type FacebookInboundToolPolicy = {
    source: "facebook_untrusted_default";
    tools: {
        deny: string[];
    };
};
export type MessengerAudioTranscript = {
    mediaIndex: number;
    text: string;
};
export declare function redactMessengerIdentifier(value: string | undefined): string;
export declare function formatUnmatchedMessengerPageLog(event: MessengerWebhookMessaging): string;
export declare function resetMessengerGatewayDailyImageForwardBudgetForTests(): void;
export declare function reserveMessengerGatewayDailyImageForwardBudget(params: {
    accountId: string;
    now?: number;
}): {
    ok: true;
    count: number;
    cap: number | null;
} | {
    ok: false;
    count: number;
    cap: number;
};
export declare function reserveMessengerGatewayDailyAudioTranscriptionBudget(params: {
    accountId: string;
    now?: number;
}): {
    ok: true;
    count: number;
    cap: number | null;
} | {
    ok: false;
    count: number;
    cap: number;
};
export declare function reserveMessengerGatewayDailyLeaderbotEventForwardBudget(params: {
    accountId: string;
    now?: number;
}): {
    ok: true;
    count: number;
    cap: number | null;
} | {
    ok: false;
    count: number;
    cap: number;
};
export declare function sanitizeMessengerSourceImageUrl(url: string): string | null;
export declare function downloadMessengerMediaAttachment(params: {
    attachment: MessengerAttachmentUrl;
    reqId: string;
    index: number;
}): Promise<ChannelInboundMediaInput | null>;
export declare function buildMessengerAgentTextForAttachments(params: {
    text: string;
    attachments: MessengerAttachmentUrl[];
    audioTranscripts?: MessengerAudioTranscript[];
}): string;
export declare function extractImagePromptFromAssistantReply(text: string): string | null;
type MessengerPromptMemoryScope = {
    accountId: string;
    pageId: string;
    senderId: string;
};
export declare function rememberMessengerAssistantPrompt(params: MessengerPromptMemoryScope & {
    text: string;
    now?: number;
    messageId?: string;
}): void;
export declare function resolveMessengerImagePromptFromUserText(params: MessengerPromptMemoryScope & {
    text: string;
    now?: number;
    replyToMessageId?: string;
}): string | null;
export declare function shouldDeliverMessengerReplyPayload(payload: ReplyPayload): payload is ReplyPayload & {
    text: string;
};
export declare function resolveFacebookInboundToolPolicy(params: {
    commandAuthorized: boolean;
}): FacebookInboundToolPolicy | null;
export declare function applyFacebookInboundToolPolicyToConfig(cfg: OpenClawConfig, policy: FacebookInboundToolPolicy | null): OpenClawConfig;
export declare function normalizeMessengerReplyPayloadForDelivery(payload: ReplyPayload): (ReplyPayload & {
    text: string;
}) | null;
export declare function getOpenClawActionText(event: MessengerWebhookMessaging): string | null;
export declare function shouldProcessMessengerMessageOnce(params: {
    accountId: string;
    senderId: string;
    messageId?: string;
    timestamp?: number;
    now?: number;
}): boolean;
export declare function resolveMessengerEventTarget(targets: MessengerWebhookTarget[], event: MessengerWebhookMessaging): MessengerWebhookTarget | null;
export declare function resolveMessengerVerificationTarget(targets: MessengerWebhookTarget[], url: URL): MessengerWebhookTarget | null;
export declare function processMessengerEvent(params: {
    event: MessengerWebhookMessaging;
    cfg: OpenClawConfig;
    account: ResolvedMessengerAccount;
    runtime: RuntimeEnv;
    trace: MessengerTrace;
}): Promise<void>;
export declare function monitorMessengerProvider(opts: MonitorMessengerProviderOptions): Promise<{
    stop: () => void;
}>;
