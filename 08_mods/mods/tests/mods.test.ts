import { describe, expect, test } from 'claude-code/testing'

// Stands for the engine beneath the mod; `state` holds what it wrote to $.state, by `plugin.key`.
function engine(on: any, store: Record<string, unknown> = {}) {
  const state: Record<string, unknown> = {}
  const versions: Record<string, number> = {}
  on('state.get', (_$: any, e: any) => ({ value: { value: state[`${e.plugin}.${e.key}`], version: versions[`${e.plugin}.${e.key}`] ?? 0 } }))
  on('state.set', (_$: any, e: any) => {
    const k = `${e.plugin}.${e.key}`
    state[k] = e.value
    return { value: { isSet: true, version: (versions[k] = (versions[k] ?? 0) + 1) } }
  })
  on('session.start', (_$: any, e: any) => ({ sessionId: 's', cwd: e.cwd }))
  on('command.register', () => ({ value: undefined }))
  on('store.get', (_$: any, e: any) => ({ value: store[e.key] }))
  on('store.set', (_$: any, e: any) => ((store[e.key] = e.value), { value: undefined }))
  return { store, state }
}

describe('mods', () => {
  test('/mods hide and /mods show set the switch and remember it', async ($, on) => {
    const { store, state } = engine(on)
    await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' } as any)
    expect((await $.command.run({ command: 'mods', args: 'hide' } as any)).text).toMatch(/hidden/)
    expect(state['mods.isHidden']).toBe(true)
    expect(store.isHidden).toBe(true)
    expect((await $.command.run({ command: 'mods', args: 'hide' } as any)).text).toMatch(/hidden/) // hide twice stays hidden
    expect((await $.command.run({ command: 'mods', args: 'show' } as any)).text).toBe('Mods shown')
    expect(state['mods.isHidden']).toBe(false)
    expect(store.isHidden).toBe(false)
  })

  test('/mods alone flips it; unknown words are refused', async ($, on) => {
    const { state } = engine(on)
    await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' } as any)
    await $.command.run({ command: 'mods', args: '' } as any)
    expect(state['mods.isHidden']).toBe(true)
    await $.command.run({ command: 'mods', args: '' } as any)
    expect(state['mods.isHidden']).toBe(false)
    expect((await $.command.run({ command: 'mods', args: 'off' } as any)).text).toMatch(/Unknown/)
  })

  test('a session that hid them starts hidden', async ($, on) => {
    const { state } = engine(on, { isHidden: true })
    await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' } as any)
    expect(state['mods.isHidden']).toBe(true)
  })
})
