# Forever shaman totem action bar

Implementation reference: `Gethe/wow-ui-source`, branch `forever`,
`Blizzard_ActionBar/Shared/MultiCastActionBarFrame.lua` and `.xml`.
This is the spell/action bar, not the unit-frame totem duration indicator.

## Local checks

From the repository root:

```sh
luajit tests/totem-bar.lua
luajit tests/totem-cooldowns.lua
git diff --check
```

The mock test checks class/config guards, all three pages, layout with and
without summon/recall spells, Edit Mode reanchoring, deferred combat updates,
and initialization after a combat reload. It does not simulate WoW's secure
execution or prove the absence of taint. Combat set-switch regression coverage
also checks that restoring Blizzard art cannot leave it visible, and that the
page layout matches Blizzard's own 8px gaps and 3px padding. These internal
spacings intentionally remain native so Blizzard's combat reanchoring does
not move the styled buttons; button size still follows ShestakUI settings.

## Summon/recall cooldown regression

The 2026-11-13 taint log captured repeated failures along
`MultiCastSpellButton_UpdateCooldown -> CooldownFrame_Set` at the legacy
helper's numeric comparisons. Summon/recall now use
`C_Spell.GetSpellCooldownDuration` and `SetCooldownFromDurationObject` without
reading numeric cooldown values. The test rejects the legacy numeric APIs
and checks both buttons and the no-duration case. This is not proof that the
separately reported `ActionButton_ApplyCooldown -> SetCooldown` error on
ordinary action bars has the same cause or is fixed.

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
   Repeatedly switch between two learned sets while in combat: icons and
   frames must stay aligned, without Blizzard borders returning. Check for
   blocked-action/taint errors. In a dungeon, use a learned Call of the...
   summon spell during combat, then recall the totems. Check both buttons'
   cooldown spirals/countdowns, including the global cooldown and clearing
   when complete. Also reload while in combat and verify the bar is integrated
   after combat ends.
8. Check a low-level shaman without summon/recall spells, another class, and
   ShestakUI with action bars disabled. Default bars should remain unchanged
   in the latter two cases.
9. Check vehicle/possess transitions and pet battles where available: the
   totem bar should not remain visible over the replacement UI.

For a bug report, include client build (`/dump GetBuildInfo()`), a screenshot,
actions to reproduce, and the complete first Lua error (if any).
