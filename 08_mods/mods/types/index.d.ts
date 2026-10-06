// The switch every gandalf mod reads: true while /mods hide is in force.
// A mod reads it with `read($, atom({ plugin: 'mods', key: 'isHidden' } as const, false))`
// and lists "mods" under "dependencies" in its plugin.json.
export type ModsHidden = boolean

declare module 'claude-code' {
  interface PluginState {
    mods: { isHidden: ModsHidden }
  }
}
