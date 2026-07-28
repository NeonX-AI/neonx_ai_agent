import { hasFacebookConfiguredEnv } from "./src/naming.js";
export function hasFacebookConfiguredState(params) {
    return hasFacebookConfiguredEnv(params.env);
}
export function hasMessengerConfiguredState(params) {
    return hasFacebookConfiguredState(params);
}
