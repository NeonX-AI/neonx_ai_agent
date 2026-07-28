import type { PluginRuntime } from "openclaw/plugin-sdk/core";
type MessengerChannelRuntime = {
    monitorMessengerProvider?: typeof import("./monitor.js").monitorMessengerProvider;
    probeMessengerPage?: typeof import("./probe.js").probeMessengerPage;
    resolveMessengerAccount?: typeof import("./accounts.js").resolveMessengerAccount;
    sendMessengerSenderAction?: typeof import("./send.js").sendMessengerSenderAction;
    sendMessengerText?: typeof import("./send.js").sendMessengerText;
};
type MessengerRuntime = PluginRuntime & {
    channel: PluginRuntime["channel"] & {
        facebook?: MessengerChannelRuntime;
    };
};
declare const setMessengerRuntime: (next: MessengerRuntime) => void, clearMessengerRuntime: () => void, getMessengerRuntime: () => MessengerRuntime;
export { clearMessengerRuntime, getMessengerRuntime, setMessengerRuntime };
