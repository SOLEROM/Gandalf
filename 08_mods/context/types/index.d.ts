export type Slice = { name: string; tokens: number; color: string; kind: 'used' | 'free' | 'buffer' }

export type Reading = {
  slices: Slice[]
  total: number // tokens in use
  window: number // the window measured against
  percent: number
  compactsAt?: number // where auto-compaction runs, when it is on
}

// Where the bar is drawn: the band above the prompt, the line under it, or a pane.
export type Position = 'above' | 'below' | 'pane'

declare module 'claude-code' {
  interface PluginState {
    'context-bar': { reading: Reading | null; isHidden: boolean; position: Position; hasLegend: boolean }
  }
}
