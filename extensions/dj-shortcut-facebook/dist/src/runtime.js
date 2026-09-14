import { createPluginRuntimeStore } from "openclaw/plugin-sdk/runtime-store";
const { setRuntime: setMessengerRuntime, clearRuntime: clearMessengerRuntime, getRuntime: getMessengerRuntime, } = createPluginRuntimeStore({
    pluginId: "facebook",
    errorMessage: "Facebook runtime not initialized - plugin not registered",
});
export { clearMessengerRuntime, getMessengerRuntime, setMessengerRuntime };
