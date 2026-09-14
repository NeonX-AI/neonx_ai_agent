import { type ChannelPlugin, type OpenClawPluginApi, type PluginRuntime } from "openclaw/plugin-sdk/core";
import type { ResolvedMessengerAccount } from "./src/types.js";
type FacebookPluginEntry = {
    id: string;
    name: string;
    description: string;
    register: (api: OpenClawPluginApi) => void;
    channelPlugin: ChannelPlugin<ResolvedMessengerAccount>;
    setChannelRuntime?: (runtime: PluginRuntime) => void;
};
declare const facebookPluginEntry: FacebookPluginEntry;
export default facebookPluginEntry;
