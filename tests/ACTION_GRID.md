# Persistent empty action slots

Run from the repository root:

```sh
luajit tests/action-grid.lua
# Also exercise Blizzard's actual GetShowGrid/SetShowGrid implementation:
luajit tests/action-grid.lua /path/to/Blizzard_ActionBar/Shared/ActionButton.lua
```

## Cause and scope

`Core.lua` initializes `showgrid` only on pet buttons. With ShestakUI's
`show_grid = true`, regular buttons otherwise retain Blizzard Edit Mode's
per-bar preference. Native `UpdateShownButtons` hides empty buttons when
`GetShowGrid()` is false, even though the ShestakUI option is enabled.

`ActionGrid.lua` applies an independent reason bit (`1048576`) to the named
ordinary action buttons. It preserves native CVAR/drag/spellbook reasons
(`1/2/4`) and other bits. Native cleanup of those temporary reasons cannot
remove the ShestakUI preference. No global function, mixin or button method
is replaced or hooked, and no Blizzard Edit Mode layout is saved/modified.

Protected attributes and initial visibility are applied through an ordinary
`SecureHandlerBaseTemplate` snippet, outside combat only. The snippet reads
public grid/statehidden attributes, not action contents, spell activity or
cooldowns. `Show(true)` preserves `statehidden`; no parent is shown, moved
or faded. Editor button counts and optional bar enable flags are respected;
pet/gamepad/stance/totem/extra-action buttons are not included.

Login/world-entry requests are coalesced into a next-frame pass. A request
in combat waits for `PLAYER_REGEN_ENABLED`, without polling. With custom
action bars or `show_grid` disabled the module does nothing. Button attributes
are recreated on reload, so disabling the option does not leave this reason
bit in SavedVariables, CVars or a native layout.

Tests cover native reason cleanup, preservation of existing flags, repeat
application, hidden state/parents, forbidden/missing/late buttons, editor
limits, disabled optional bars and combat deferral. They do not simulate
WoW taint propagation or fully validate the client rendering lifecycle.

## In-game checks

- Enable Show empty action bar buttons; reload outside combat several times
  with some empty slots on each configured bar. Empty slots should remain.
- Drag/drop/remove a spell, open/close the spellbook, change action pages and
  enter combat. Empty slots should not disappear when the temporary grid ends.
- Confirm mouseover fades, toggled-off bars and editor-hidden buttons remain
  hidden as configured. Check vehicle/possess/pet-battle behavior separately.
- Disable the option and reload: existing hide-empty behavior should return.
- Cooldowns, pet/totem/gamepad bars and other addons should be unchanged.

Rollback only this fix by reverting its merge or restoring the previous
`ShestakUI.xml` and removing `Modules/ActionBars/ActionGrid.lua`, then reload.
