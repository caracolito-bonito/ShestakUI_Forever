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

## In-game validation

1. Reload outside combat. Check empty slots before proceeding, including
   toggling action-bar grid and switching action-bar pages if configured.
2. Create/join a fresh party and cast on a raid frame using the interaction
   that triggered the error. Repeat after membership changes/in a dungeon.
3. Check ordinary/GCD and charge cooldowns; test gamepad flyouts if used.
4. Preserve any new error's full stack. This change addresses the specific
   gamepad UpdateCooldown call path, not every possible shared-updater error.
