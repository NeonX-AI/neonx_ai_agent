import { defineChannelPluginEntry } from "openclaw/plugin-sdk/channel-core";
import { messengerPlugin } from "./src/channel.js";
import { setMessengerRuntime } from "./src/runtime.js";
const facebookPluginEntry = defineChannelPluginEntry({
    id: "facebook",
    name: "Facebook",
    description: "Facebook Page Messenger channel plugin",
    plugin: messengerPlugin,
    setRuntime: setMessengerRuntime,
});
export default facebookPluginEntry;
