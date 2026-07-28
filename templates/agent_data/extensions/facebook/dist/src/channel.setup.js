import { messengerChannelPluginCommon } from "./channel-shared.js";
import { messengerSetupAdapter } from "./setup-core.js";
import { messengerSetupWizard } from "./setup-surface.js";
export const messengerSetupPlugin = {
    id: "facebook",
    ...messengerChannelPluginCommon,
    setupWizard: messengerSetupWizard,
    setup: messengerSetupAdapter,
};
