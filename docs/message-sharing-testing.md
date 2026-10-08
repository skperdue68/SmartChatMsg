# Trying message-only sharing

Install every file in the current addon manifest, including `SCM_MessageSharing.lua`.
Keep LibAddonMenu-2.0 installed. Open `/scm` and select a command, guild and output
channel in Messages settings on both players' clients.

## Export and merge

1. Player A saves two message templates, then opens **Share Messages** and clicks
   **Export Messages**. Copy the generated `SCM_MESSAGES_V1` text.
2. Player B selects a destination command and the same guild/output channel.
   The command name and the guild's slot number may differ.
3. Paste into **Shared message text** and click **Import Messages (merge)**.
4. Verify both templates appear. Existing messages, settings and usage should
   remain intact; no automation should start merely because templates were added.
5. Import again: the messages should not duplicate. The result reports how many
   templates were added and how many exact duplicates were skipped.

Try text with `%guild%`, colors/guild links containing `|`, punctuation, and
substitution tokens. They should survive export/import as the original templates.

## Validate failures and coordination

- Select a different guild or output channel: import must fail without adding
  any messages or changing settings.
- Remove the final END or damage a record: import must fail transactionally.
- Paste a message share into full settings Import: it must reject the different
  format rather than replacing settings.
- Player A sends an expanded shared template on the correct channel. Player B's
  matching command/guild should record usage and add 30–90 seconds of cooldown.
- Send identical text on the wrong guild/channel: Player B's combination must
  remain unchanged. Their own sends must not receive the peer delay.

Sharing copies raw templates only. It does not include event dates/times, phase
assignments or schedules. For event tokens, configure the matching event on the
recipient. Newly imported scheduled messages default to ANY until assigned.

Full settings export includes schedules and phases, but its import replaces all
settings. After full import, dates/times, intervals and message-phase choices can
be edited independently on the recipient and saved.

The automated sharing checks run with Lua 5.1 from the repository root:

```
lua tests/message_sharing_spec.lua
```

That suite also runs the incoming-chat regression checks. The real ESO multiline
copy/paste control and two-player behavior still need in-game testing.
