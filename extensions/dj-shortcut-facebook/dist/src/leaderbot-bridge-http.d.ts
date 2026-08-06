import type { MessengerWebhookMessaging } from "./types.js";
export type LeaderbotBridgeTrace = {
    reqId: string;
    psidHash: string;
    accountId: string;
    startedAt: number;
};
export type LeaderbotBridgeStageLogger = (trace: LeaderbotBridgeTrace, stage: string, fields?: Record<string, string | number | boolean | undefined>) => void;
export declare function requestLeaderbotImageGeneration(params: {
    psid: string;
    pageId: string;
    prompt: string;
    reqId: string;
    timestamp: number;
    trace: LeaderbotBridgeTrace;
    leaderbotBridgeEnabled?: boolean;
    sourceImageUrl?: string;
    logStage?: LeaderbotBridgeStageLogger;
}): Promise<boolean>;
export declare function forwardLeaderbotMessengerEvent(params: {
    event: MessengerWebhookMessaging;
    trace: LeaderbotBridgeTrace;
    leaderbotBridgeEnabled?: boolean;
    logStage?: LeaderbotBridgeStageLogger;
}): Promise<boolean>;
