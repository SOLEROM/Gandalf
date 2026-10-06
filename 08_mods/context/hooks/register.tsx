// Context Bar: what is filling my context window?
//   The window as one stacked bar, a color per category as /context draws them (system
//   prompt, tools, MCP tools, memory files, skills, messages, free), with a legend of tokens
//   and shares and where auto-compaction runs. It refreshes after each turn.
//   Where it is drawn is the plugin option `position` (claude plugin configure):
//     above  the boxed bar and legend above the prompt (the default)
//     below  one plain-text line pinned under the prompt
//     pane   the boxed bar in a pane: a sidebar in fullscreen mode, a full view otherwise
//   Claude Code has no site at the top of the window; the pane is the nearest.
//   /context-bar shows or hides it, and the choice is kept across sessions.
//   /context-bar above|below|pane moves it for this session.
//   /mods hide (the mods plugin) hides it with every other gandalf mod.
import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Position, Reading, Slice } from '../types'

const POSITIONS: readonly Position[] = ['above', 'below', 'pane']
const PANE = 'context-bar' // the pane's id
const LINE_WIDTH = 24 // cells of the bar in the one-line form under the prompt
const MIN_WIDTH = 20 // narrower than this, the bar is not drawn
const SPLIT = '   '
// /context's theme gives several rows the same grey, so each used row gets its own color, in order.
const PALETTE = ['#7aa2f7', '#7dcfff', '#bb9af7', '#9ece6a', '#e0af68', '#f7768e', '#73daca', '#ff9e64', '#c0caf5']
const MESSAGES = '#d97757' // the row that grows, in the accent color
const FREE = '#808080' // a mid grey thin line reads as empty on dark and light themes alike
const BUFFER = '#808080'
const GLYPH = { used: '█', free: '─', buffer: '░' } as const

// Held by the host, so the bar survives a hot reload of this file.
const reading = atom({ plugin: 'context-bar', key: 'reading' } as const, null as Reading | null)
const isHidden = atom({ plugin: 'context-bar', key: 'isHidden' } as const, false)
const position = atom({ plugin: 'context-bar', key: 'position' } as const, 'above' as Position)
const hasLegend = atom({ plugin: 'context-bar', key: 'hasLegend' } as const, true)
const modsHidden = atom({ plugin: 'mods', key: 'isHidden' } as const, false) // /mods hide, owned by the mods plugin

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const r = await next(e)
    await $.command.register({ name: 'context-bar', description: 'Show or hide the context window bar above the prompt' }).catch(() => {}) // a name Claude Code already has is refused: start anyway
    const hidden = (await $.store.get('isHidden').catch(() => undefined)) === true
    await update($, isHidden, () => hidden)
    const o = await options($).catch(() => ({}) as Partial<Options>)
    if (o.position) await update($, position, () => o.position!)
    if (o.legend !== undefined) await update($, hasLegend, () => o.legend!)
    void refresh($).catch(() => {})
    return r
  })

  on('turn.complete', async ($, e, next) => {
    const r = await next(e)
    if (!e.agentId) await refresh($).catch(() => {}) // a subagent's turn fills its own window, not this one
    return r
  })

  on('session.compact', async ($, e, next) => {
    const r = await next(e)
    if (!e.agentId && 'messages' in r) void refresh($).catch(() => {}) // a /compact empties the window without a turn ending
    return r
  })

  on('command.run', { command: 'context-bar' }, async ($, e) => {
    const asked = e.args.trim().toLowerCase()
    if (asked !== '') {
      if (!isPosition(asked)) return { text: `Unknown position "${asked}". Use /context-bar ${POSITIONS.join('|')}` }
      await update($, position, () => asked)
      await update($, isHidden, () => false)
      await $.store.set('isHidden', false).catch(() => {})
      await refresh($).catch(() => {})
      return { text: `Context bar ${asked === 'pane' ? 'in a pane' : `${asked} the prompt`} for this session. Set it for good with: claude plugin configure context-bar@gandalf-mods` }
    }
    const hidden = await update($, isHidden, h => !h)
    await $.store.set('isHidden', hidden).catch(() => {})
    await refresh($).catch(() => {})
    return { text: hidden ? 'Context bar hidden. /context-bar shows it again' : 'Context bar on' }
  })

  on('state.set', { plugin: 'mods', key: 'isHidden' }, async ($, e, next) => {
    const r = await next(e)
    void refresh($).catch(() => {}) // the line under the prompt and the pane are not redrawn by a read
    return r
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const rest = await next(e) // what other mods and Claude Code draw here stays
    const r = await read($, reading)
    if (e.props.hasSurvey || (await hidden($)) || (await read($, position)) !== 'above' || !r) return rest
    const box = await drawBox($, e, r, e.props.bodyColumns)
    if (!box) return rest
    const { Box } = $.ui.resolve(e)
    return (
      <Box flexDirection="column">
        {box}
        {rest}
      </Box>
    )
  })

  on('ui.render', { component: 'Pane' }, async ($, e, next) => {
    if (e.requestId !== PANE) return next(e) // another plugin's pane
    const r = await read($, reading)
    const { Text } = $.ui.resolve(e)
    if (await hidden($)) return <Text dimColor>hidden: /mods show</Text>
    if (!r) return <Text dimColor>measuring the context window…</Text>
    return (await drawBox($, e, r, e.props.bodyColumns ?? e.viewport?.columns ?? 80)) ?? <Text dimColor>too narrow for the context bar</Text>
  })
}

// The boxed bar, its legend under it when the option is on; undefined when `columns` is too narrow.
async function drawBox($: EngineInterface, e: any, r: Reading, columns: number) {
  const { Box, Text } = $.ui.resolve(e)
  const inner = columns - 4 // the border and padding take 4 cells
  if (inner < MIN_WIDTH) return undefined
  const withLegend = await read($, hasLegend)
  const head = `${tokens(r.total)} of ${tokens(r.window)}${r.compactsAt ? ` · compacts at ${tokens(r.compactsAt)}` : ''}`
  const pct = ` ${r.percent}% `
  const level = r.compactsAt ? r.total / r.compactsAt : r.total / r.window
  return (
    <Box flexDirection="column" borderStyle="round" borderColor="inactive" paddingX={1}>
      <Box flexDirection="row" justifyContent="space-between">
        <Text wrap="truncate-end">
          <Text color="#d97757">{'◆ '}</Text>
          <Text bold>context</Text>
        </Text>
        <Text wrap="truncate-start">
          <Text dimColor>{`${head} `}</Text>
          <Text bold color="black" backgroundColor={level >= 0.9 ? 'red' : level >= 0.7 ? 'yellow' : 'green'}>{pct}</Text>
        </Text>
      </Box>
      <Text>
        {cells(r, inner).map(c => (
          <Text color={c.color}>{c.text}</Text>
        ))}
      </Text>
      {(withLegend ? legend(r, inner) : []).map(line => (
        <Text wrap="truncate-end">
          {line.map((s, i) => (
            <Text>
              {i > 0 && <Text>{SPLIT}</Text>}
              <Text color={s.color}>{s.kind === 'used' ? '■ ' : `${GLYPH[s.kind]} `}</Text>
              <Text dimColor={s.kind !== 'used'}>{`${s.name} `}</Text>
              <Text bold={s.kind === 'used'}>{tokens(s.tokens)}</Text>
              {s.kind === 'used' && <Text dimColor>{` ${share(s.tokens, r.window)}`}</Text>}
            </Text>
          ))}
        </Text>
      ))}
    </Box>
  )
}

// Asks the engine for /context's breakdown, estimated locally (no token-count calls), then
// puts the bar where `position` says and takes it away from the other places.
async function refresh($: EngineInterface) {
  const isOff = await hidden($)
  const where = await read($, position)
  if (!isOff) {
    const usage = await $.session.usage({ breakdown: 'summary' })
    const b = usage.context.breakdown
    if (b && b.rawMaxTokens > 0) await update($, reading, () => toReading(b)) // else no window to measure against
  }
  const r = await read($, reading)
  // Each place on its own, so one that fails does not keep the others stale.
  await $.ui.status(!isOff && where === 'below' && r ? line(r) : undefined).catch(() => {})
  if (!isOff && where === 'pane') await $.ui.open({ id: PANE, title: 'context', focus: false }).catch(() => {})
  else await $.ui.close({ id: PANE }).catch(() => {}) // not open: nothing to close
  await $.ui.invalidate('ui.render').catch(() => {})
}

// Hidden by /context-bar or by /mods hide.
const hidden = async ($: EngineInterface) => (await read($, isHidden)) || (await read($, modsHidden))

type Options = { position: Position; legend: boolean }

// The plugin options the person set (claude plugin configure), from settings.json's pluginConfigs.
async function options($: EngineInterface): Promise<Partial<Options>> {
  const settings = (await $.settings.read()) as { pluginConfigs?: Record<string, { options?: Record<string, unknown> }> }
  const configs = settings.pluginConfigs ?? {}
  const id = Object.keys(configs).find(k => k === $.plugin.name || k.startsWith('context-bar@'))
  return parseOptions(id ? configs[id]?.options : undefined)
}

export function parseOptions(o: Record<string, unknown> | undefined): Partial<Options> {
  const p = String(o?.position ?? '').trim().toLowerCase()
  const l = o?.legend
  return {
    ...(isPosition(p) && { position: p }),
    ...(l !== undefined && { legend: l === true || ['true', '1', 'yes', 'on'].includes(String(l).toLowerCase()) }),
  }
}

const isPosition = (p: string): p is Position => (POSITIONS as readonly string[]).includes(p)

// The bar as one plain-text line, for the line under the prompt (it takes no colors).
export function line(r: Reading) {
  const bar = cells(r, LINE_WIDTH).map(c => c.text).join('')
  return `◆ context ${bar} ${r.percent}% · ${tokens(r.total)} of ${tokens(r.window)}${r.compactsAt ? ` · compacts at ${tokens(r.compactsAt)}` : ''}`
}

export function toReading(b: {
  categories: { name: string; tokens: number; color: string; kind: string }[]
  totalTokens: number
  rawMaxTokens: number
  percentage: number
  autoCompactThreshold?: number
  isAutoCompactEnabled: boolean
}): Reading {
  const slices: Slice[] = b.categories
    .filter(c => c.kind !== 'deferred' && c.tokens > 0)
    .map(c => ({ name: c.name.toLowerCase(), tokens: c.tokens, color: c.color, kind: c.kind as Slice['kind'] }))
  const order = { used: 0, free: 1, buffer: 2 }
  slices.sort((x, y) => order[x.kind] - order[y.kind]) // stable: used rows keep /context's order
  let next = 0
  for (const s of slices) {
    s.color = s.kind === 'free' ? FREE : s.kind === 'buffer' ? BUFFER : s.name === 'messages' ? MESSAGES : PALETTE[next++ % PALETTE.length]!
  }
  return {
    slices,
    total: b.totalTokens,
    window: b.rawMaxTokens,
    percent: b.percentage,
    compactsAt: b.isAutoCompactEnabled ? b.autoCompactThreshold : undefined,
  }
}

// The bar as runs of cells: each slice gets its share of `width`, a used one at least one cell.
export function cells(r: Reading, width: number) {
  const sizes = r.slices.map(s => Math.max(s.kind === 'used' ? 1 : 0, Math.round((s.tokens / r.window) * width)))
  // Rounding leaves the sum a few cells off: free space takes the difference first, then the largest slices.
  let diff = width - sizes.reduce((a, n) => a + n, 0)
  const isUsed = (i: number) => r.slices[i]!.kind === 'used'
  const order = r.slices.map((_, i) => i).sort((a, b) => Number(isUsed(a)) - Number(isUsed(b)) || sizes[b]! - sizes[a]!)
  for (const i of order) {
    if (diff === 0) break
    const size = Math.max(isUsed(i) ? 1 : 0, sizes[i]! + diff)
    diff -= size - sizes[i]!
    sizes[i] = size
  }
  return r.slices.map((s, i) => ({ color: s.color, kind: s.kind, text: GLYPH[s.kind].repeat(sizes[i]!) })).filter(c => c.text !== '')
}

// The legend, packed into lines no wider than `width`.
export function legend(r: Reading, width: number) {
  const lines: Slice[][] = [[]]
  let used = 0
  for (const s of r.slices) {
    const size = 2 + s.name.length + 1 + tokens(s.tokens).length + (s.kind === 'used' ? 1 + share(s.tokens, r.window).length : 0)
    const line = lines.at(-1)!
    if (line.length > 0 && used + SPLIT.length + size > width) {
      lines.push([s])
      used = size
    } else {
      used += (line.length > 0 ? SPLIT.length : 0) + size
      line.push(s)
    }
  }
  return lines.filter(l => l.length > 0)
}

export function tokens(n: number) {
  if (n >= 1_000_000) return `${+(n / 1_000_000).toFixed(n % 1_000_000 === 0 ? 0 : 1)}M`
  if (n >= 10_000) return `${Math.round(n / 1000)}k`
  if (n >= 1000) return `${+(n / 1000).toFixed(1)}k`
  return String(n)
}

export function share(n: number, window: number) {
  const p = (n / window) * 100
  if (p > 0 && p < 0.1) return '<0.1%'
  return `${p >= 10 ? Math.round(p) : +p.toFixed(1)}%`
}
