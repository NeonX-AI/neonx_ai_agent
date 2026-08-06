import type { MessengerProbeResult } from "./types.js";
export declare function probeMessengerPage(params: {
    pageId: string;
    pageAccessToken: string;
    graphApiVersion?: string;
    timeoutMs?: number;
    fetch?: typeof fetch;
}): Promise<MessengerProbeResult>;
