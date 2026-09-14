export type LeaderbotAiAnswerQuotaReservation = {
    status: "not_applicable";
} | {
    status: "reserved";
    reservationId: string;
} | {
    status: "duplicate";
} | {
    status: "exhausted";
} | {
    status: "unavailable";
};
export declare function isLeaderbotAiAnswerEnforcementEnabled(): boolean;
export declare function createLeaderbotAiAnswerIdempotencyKey(input: {
    accountId: string;
    pageId: string;
    messageId?: string;
    traceRequestId: string;
    timestamp: number;
}): string;
export declare function reserveLeaderbotAiAnswerQuota(input: {
    pageId: string;
    idempotencyKey: string;
}): Promise<LeaderbotAiAnswerQuotaReservation>;
export declare function finalizeLeaderbotAiAnswerQuota(input: {
    pageId: string;
    reservationId: string;
    outcome: "committed" | "released";
}): Promise<boolean>;
