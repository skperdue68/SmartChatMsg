SmartChatMsg is an ESO addon for players who regularly post recurring messages such as guild recruitment, trial announcements, officer notices, and other repeated chat content.

Create your own slash commands, save multiple message variants under each command, and organize those messages by guild. When a command is used, SmartChatMsg resolves the intended guild, retrieves a matching saved message, applies substitutions, and places the completed text into the proper chat channel.

Main capabilities:
- Dynamic custom slash commands
- Supports parameters 1-5, g1-g5, and o1-o5, with g# and o# treated the same as the matching number
- Multiple saved messages per command and guild
- Saved output channel selection for Zone, Guild, or Officer chat
- Chat channel auto-restore after message send
- Timeout restore clears the pending chat buffer
- Reminder minutes stored per Command + Guild
- Reminder retry minutes stored per Command + Guild
- Auto Populate On Zone stored per Command + Guild
- Auto populate cooldown stored per Command + Guild
- Populate sound stored per Command + Guild
- Populate sound dropdown includes None plus a curated list of useful ESO sounds
- Preview button for the selected populate sound
- Global Auto-Remove Pending Chat stored under General
- Import/export with confirmation and success feedback
- Case-insensitive substitutions for %time%, %guild%, and %zone%

Populate Sound:
- Default value is DUEL_START
- Set to None to disable sound entirely
- Plays when a message is automatically populated into chat by Auto Populate On Zone or Repeat
- Preview lets you test the selected sound immediately from settings

Built-in substitutions:
- %time% -> morning, afternoon, or evening
- %guild% -> the resolved guild name for the current command context
- %zone% -> the player's current zone name

Tokens are case-insensitive, so %TIME%, %Guild%, and %Zone% also work.


Slash command control:
- Use the command normally to start or restart it: `/command`, `/command 1`, `/command g1`, `/command o1`
- Add `off` to stop repeat and/or auto populate for that command and guild: `/command off`, `/command 1 off`, `/command g1 off`, `/command o1 off`
- If `Retry Delay (mins)` is 0, blank, or invalid, SmartChatMsg skips retry and immediately resumes the normal repeat cycle after the populate attempt times out
- `Retry Delay (mins)` is automatically capped to `Repeat Every (mins)` when Repeat Every is set
