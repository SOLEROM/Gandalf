// Mods: one switch for every mod in the gandalf-mods marketplace.
//   /mods hide   hides them all
//   /mods show   shows them again
//   /mods        flips between the two
//   The choice is kept across sessions. Each mod reads the switch, the `mods.isHidden`
//   value in $.state, and draws nothing while it is on; its own show/hide still applies.
import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

const isHidden = atom({ plugin: 'mods', key: 'isHidden' } as const, false)

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const r = await next(e)
    await $.command.register({ name: 'mods', description: 'Hide or show all gandalf mods', argumentHint: 'hide|show' }).catch(() => {})
    const hidden = (await $.store.get('isHidden').catch(() => undefined)) === true
    if (hidden !== (await read($, isHidden))) await update($, isHidden, () => hidden)
    return r
  })

  on('command.run', { command: 'mods' }, async ($, e) => {
    const asked = e.args.trim().toLowerCase()
    if (asked !== '' && asked !== 'hide' && asked !== 'show') return { text: `Unknown "${asked}". Use /mods hide or /mods show` }
    const hidden = await update($, isHidden, h => (asked === '' ? !h : asked === 'hide'))
    await $.store.set('isHidden', hidden).catch(() => {})
    return { text: hidden ? 'Mods hidden. /mods show brings them back' : 'Mods shown' }
  })
}
