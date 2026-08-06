import type { PluginRuntime } from "openclaw/plugin-sdk/core";
type MessengerChannelRuntime = {
    monitorMessengerProvider?: typeof import("./monitor.js").monitorMessengerProvider;
    probeMessengerPage?: typeof import("./probe.js").probeMessengerPage;
    resolveMessengerAccount?: typeof import("./accounts.js").resolveMessengerAccount;
    sendMessengerImage?: typeof import("./send.js").sendMessengerImage;
    sendMessengerSenderAction?: typeof import("./send.js").sendMessengerSenderAction;
    sendMessengerText?: typeof import("./send.js").sendMessengerText;
    sendMessengerTextAndImage?: typeof import("./send.js").sendMessengerTextAndImage;
};
type MessengerRuntime = PluginRuntime & {
    channel: PluginRuntime["channel"] & {
        facebook?: MessengerChannelRuntime;
    };
};
declare const setMessengerRuntime: (next: MessengerRuntime) => void, clearMessengerRuntime: () => void, getMessengerRuntime: () => MessengerRuntime;
export { clearMessengerRuntime, getMessengerRuntime, setMessengerRuntime };
