# Shared action/gamepad cooldown regression

Reported stack: `GamepadActionBarStandardButtonMixin:OnEvent` ->
`GamepadActionBarButtonFlyoutMixin:UpdateCooldown` ->
`ActionButton_UpdateCooldown` -> `ActionButton_ApplyCooldown` ->
`SetCooldown(secret start, secret duration, secret modRate)`.

The earlier removal of the shared SetCooldown styling hook did not resolve
this path. The separate summon/recall duration-object fix does not cover it.

`Modules/ActionBars/DurationCooldowns.lua` replaces the shared action-button
updater only when all required duration APIs are present. It preserves the
normal, charge and loss-of-control selection rules, using only info fields
that Forever documents as `NeverSecret`: `isActive` and
`shouldReplaceNormalCooldown`. Numeric cooldown fields are not accessed.
Action IDs, click-casting handlers, event subscriptions and the Cooldown
metatable are left unchanged.

## Local check

```sh
luajit tests/action-button-duration-cooldowns.lua
```

Tests reject numeric cooldown calls and reads of numeric info fields. They
cover action slots, spell-based flyouts, GCD/normal and charge cooldowns,
LoC replacement, disabled LoC, missing data/frames, and repeated delegation
from the gamepad path. They do not emulate WoW's secure execution or a real
group/click-cast interaction.

## In-game check

1. Reload outside combat.
2. Join or create a fresh group; cast a heal on a party/raid frame using the
   same click-cast/keybinding interaction that triggered the reported error.
3. Repeat after changing group membership and after entering a dungeon.
4. Check the visible cooldown spirals/countdowns: ordinary cooldown, GCD,
   charge recovery, expiry, and loss of control where available.
5. If a gamepad is used, also check normal and spell-flyout gamepad buttons.
6. If an error returns, preserve its complete stack and capture a short
   taint log (`/console taintLog 2`, reload, reproduce, then
   `/console taintLog 0`). Do not assume a new stack has the same cause.
