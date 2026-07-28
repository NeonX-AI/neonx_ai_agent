import { type ConversationAction } from "./messengerPresentationTypes.js";
export declare function extractNumberedChoicesFromText(text: string | undefined): ConversationAction[];
export declare function stripNumberedChoicesFromText(text: string): string;
