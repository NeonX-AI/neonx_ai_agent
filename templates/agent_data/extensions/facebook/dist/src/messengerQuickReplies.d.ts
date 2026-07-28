import type { MessagePresentationBlock } from "openclaw/plugin-sdk/interactive-runtime";
import type { ReplyPayload } from "openclaw/plugin-sdk/reply-runtime";
import { type ConversationAction, type MessengerQuickReply } from "./messengerPresentationTypes.js";
export declare function decodeOpenClawActionPayload(payload: string | undefined): string | null;
export declare function extractQuickReplies(blocks: readonly MessagePresentationBlock[]): MessengerQuickReply[];
export declare function extractActionQuickReplies(actions: readonly ConversationAction[] | undefined): MessengerQuickReply[];
export declare function shouldRenderQuickReplies(quickReplies: readonly MessengerQuickReply[]): boolean;
export declare function getMessengerQuickReplies(payload: ReplyPayload): MessengerQuickReply[] | undefined;
