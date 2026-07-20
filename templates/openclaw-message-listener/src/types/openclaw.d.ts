declare module "openclaw/plugin-sdk/plugin-entry" {
  export interface PluginDefinition {
    id: string;
    name: string;
    description: string;
    register: (api: any) => void;
  }

  export function definePluginEntry(plugin: PluginDefinition): PluginDefinition;
}