# Forever shaman totem action bar

Implementation reference: `Gethe/wow-ui-source`, branch `forever`,
`Blizzard_ActionBar/Shared/MultiCastActionBarFrame.lua` and `.xml`.
This is the spell/action bar, not the unit-frame totem duration indicator.

## Local checks

From the repository root:

```sh
luajit tests/totem-bar.lua
git diff --check
```

The mock test checks class/config guards, all three pages, layout with and
without summon/recall spells, Edit Mode reanchoring, deferred combat updates,
and initialization after a combat reload. It does not simulate WoW's secure
execution or prove the absence of taint.

## In-game checklist

1. Copy the updated `ShestakUI` directory to `_forever_/Interface/AddOns/`.
   Restart the client if it is already running (the XML loads a new Lua file).
2. On a shaman with the totem bar unlocked, enable Lua errors:
   `/console scriptErrors 1`.
3. Check the bar above the main action bars: summon, available elemental
   slots, recall. Empty slots should retain their elemental backgrounds.
4. Open each elemental flyout, select a different totem, cast it, and check
   icons, tooltips, cooldowns and existing keybindings.
5. Switch among all learned summon sets using the summon flyout. Check that
   each set retains its own totems; summon a set and recall its totems.
6. Use `/moveui` to move `TotemBar`; leave move mode, `/reload`, and verify
   the position is retained. Enter/exit Blizzard Edit Mode if available.
7. Enter combat and test casting, bindings, summon/recall, and flyout behavior.
   Check for blocked-action/taint errors. Also reload while in combat and
   verify the bar is integrated after combat ends.
8. Check a low-level shaman without summon/recall spells, another class, and
   ShestakUI with action bars disabled. Default bars should remain unchanged
   in the latter two cases.
9. Check vehicle/possess transitions and pet battles where available: the
   totem bar should not remain visible over the replacement UI.

For a bug report, include client build (`/dump GetBuildInfo()`), a screenshot,
actions to reproduce, and the complete first Lua error (if any).
