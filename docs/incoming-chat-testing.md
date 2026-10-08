# Trying incoming duplicate-message coordination

This feature is built on `Add-Countdown-Substitution`, including that branch's
existing countdown formatting, status panel, and startup behavior.

## Install the current version

1. Back up your installed SmartChatMsg addon and its SavedVariables file.
2. Download the current feature release/branch using GitHub's **Code → Download ZIP**.
3. Install the complete addon, including every Lua file in `SmartChatMsg.txt`.
   The current version also includes scheduling and message-sharing modules;
   copying only the original incoming-chat files is insufficient. Keep
   LibAddonMenu-2.0 installed.
4. Run `/reloadui`. Optionally enable `/scmdebug on` to see matching command,
   guild, channel, and selected random delay in chat/debug logs.

## Two-player checks

Channel/guild routing is mandatory before text matching: Guild output for your
guild slot 1 only matches that guild's incoming Guild chat; slot 2 requires its
own guild. Officer output requires Officer chat for the same guild. Zone output
requires Zone chat. Identical text on the wrong channel/guild must not reset usage.
Guild names are resolved from each player's local slots, which can differ.

Use another player/account; your own messages are intentionally excluded. The
other player does not have to run SmartChatMsg.

1. Configure a Zone command for a guild with two different advertisements and a
   one-minute cooldown. Include `%guild%` in one advertisement. Have the other
   player send its expanded wording. The whole command/guild should cool down
   for 90–150 seconds, including its other variant. `/scm status` shows the timer.
2. Send the same wording yourself. It should follow the existing self-send flow,
   with no extra peer delay.
3. Configure matching Guild messages for two guilds. Have the other player post
   in one guild. Only that guild's combination should change. Repeat for Officer
   output; Guild and Officer routing must remain separate.
4. Try a template such as `Good %time%! %guild% trial Friday at 8 PM EDT.`
   Have the other player send the same guild/event wording with another valid
   greeting and `(about 2h)` or `(about 1h 55m)` beside the time. Both should
   match. A different guild, date, event time, explicit timezone, or fixed wording
   must not match.
5. Run a Repeat command, then receive its matching message. The next repeat
   populate should occur after the configured interval plus 30–90 seconds.
   Stop it using `off`; further matches should update usage without restarting it.
6. Leave an unchanged addon-populated message in chat, then receive a matching
   combination from another player. The pending duplicate should disappear and
   restore your previous channel. Repeat after editing your pending message;
   the edited text should stay, and the addon's old timeout should be canceled.
7. `/reloadui` during an observed Zone cooldown. The status timer should retain
   the extra delay. Changing to another zone should preserve independent Zone
   cooldowns; Guild/Officer observations should apply across zones.

An identical generic template assigned to several Zone command/guild
combinations updates all of them. Including a guild name/link distinguishes
advertisements. Matching is intentionally conservative: edits to fixed wording
and incomplete pasted fragments do not count.

## Automated regression tests

From the repository root, run:

```sh
lua tests/incoming_chat_spec.lua
```

Use Lua 5.1, matching ESO's Lua language version. The suite executes the real
addon matching, usage, timer, and SavedVariables logic with ESO event/UI APIs
represented by a small fixture. It does not require a live game or send chat.
In-game event/UI behavior still needs the two-player checks above.
