# Action-button cooldown widget adapter

The remaining report is the ordinary shared dispatcher path:
`ActionBarButtonEventsFrame:OnEvent -> button:OnEvent ->
ActionButton_UpdateCooldown -> ActionButton_ApplyCooldown -> SetCooldown`.
The gamepad-only UpdateCooldown fix does not cover this stack. The available
taint log predates this reproduction, so the original taint source is not
established by this change.

`ActionCooldownWidgets.lua` adapts SetCooldown only on cooldown widgets owned
by registered action buttons. It leaves the shared updater, dispatcher,
metatable, active/charge/LoC selection and native Clear method unchanged.
Accessible arguments are forwarded verbatim, including their argument count
and native return value. Inaccessible arguments are not inspected: the
matching action/spell duration API supplies an opaque object for the native
SetCooldownFromDurationObject method. Normal, charge and LoC widgets each
use their own duration API; the current owning action/spell is read at the
time of the call, not cached at registration.

## Local validation

```sh
luajit tests/action-cooldown-widgets.lua
```

Tests reproduce rejection of secret timing arguments, check public-call
forwarding, each duration type, action-page changes, late registration,
idempotence, missing durations and the unchanged Clear/grid/global paths.
They do not emulate WoW's taint propagation or prove the absence of an
in-game visibility regression.

## In-game validation

1. Reload outside combat and check empty-slot visibility first.
2. Check normal GCD and cooldowns, charge recovery, expiry, changing action
   pages, placing/removing actions and LoC display where available.
3. Create/join a fresh party and cast on a raid frame using the interaction
   that produced the report; repeat in a dungeon/after membership changes.
4. If an error recurs, capture its complete stack and a fresh short taint log.
   Do not claim the taint origin is fixed merely because rendering succeeds.
