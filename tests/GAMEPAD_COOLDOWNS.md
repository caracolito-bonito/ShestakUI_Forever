# Narrow gamepad cooldown fix

The reported stack enters through the gamepad button's own OnEvent and
`GamepadActionBarButtonFlyoutMixin:UpdateCooldown` for SPELL_UPDATE_COOLDOWN.
That method calls the old numeric shared updater.

The previous global `ActionButton_UpdateCooldown` replacement was rolled back
after an in-game empty-slot regression. Do not restore it.

`GamepadCooldowns.lua` only replaces `UpdateCooldown` on instances that expose
both `GetGamepadPageUnitSlotID` and `GetSingleSpellID`. It uses duration
objects and documented NeverSecret active/LoC flags, preserving flyout spell
matching and normal/charge/loss-of-control selection. The existing button
registry covers current and late-created instances. The shared updater,
keyboard buttons, OnEvent methods, bindings and grid visibility are untouched.

## Local checks

```sh
luajit tests/gamepad-cooldowns.lua
```

Tests verify that numeric cooldown APIs are not called on this path, ordinary
and empty keyboard button handlers are not changed, and their Show/Hide,
alpha, attributes, scripts and bindings are not touched. They also cover
late registration, flyout event matching, charges, LoC and clearing.
Mocks do not prove the absence of taint in the client.

## Class flyout active-state regression

A separate Druid report enters `GetActiveSpellID -> IsActiveSpell(5487)` from
`UpdateFlyoutActionIcon`, where the result can be a secret boolean.
`GamepadClassFlyout.lua` patches only the LeftClassAction instance's icon
selection query. Accessible active flags keep the native spell selection;
an inaccessible flag returns nil so Blizzard's unchanged icon renderer uses
its generic flyout texture. It does not infer the protected form, replace the
global spell API, or change cast/cancel handlers.

Run `luajit tests/gamepad-class-flyout.lua`. To execute the real native icon
updater as well, use `luajit tests/gamepad-class-flyout.lua /path/to/ActionButton.lua`.
In game, reload outside combat, switch Druid forms, and repeat the triggering
interaction in combat/in a group. A generic class-menu icon while the active
state is restricted is intentional; keyboard action bars and the player
energy/rage/mana display must remain unchanged.

## In-game validation

1. Reload outside combat. Check empty slots before proceeding, including
   toggling action-bar grid and switching action-bar pages if configured.
2. Create/join a fresh party and cast on a raid frame using the interaction
   that triggered the error. Repeat after membership changes/in a dungeon.
3. Check ordinary/GCD and charge cooldowns; test gamepad flyouts if used.
4. Preserve any new error's full stack. This change addresses the specific
   gamepad UpdateCooldown call path, not every possible shared-updater error.
