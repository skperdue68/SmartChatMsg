SmartChatMsg is an ESO addon for players who regularly post recurring messages such as guild recruitment, trial announcements, officer notices, and other repeated chat content.

Create your own slash commands, save multiple message variants under each command, and organize those messages by guild. When a command is used, SmartChatMsg resolves the intended guild, retrieves a matching saved message, applies substitutions, and places the completed text into the proper chat channel.

Main capabilities:
- Dynamic custom slash commands
- Supports parameters 1-5, g1-g5, and o1-o5
- Optional Default Guild when commands are run without parameters
- Multiple saved messages per command and guild
- Saved output channel selection for Zone, Guild, or Officer chat
- Chat channel auto-restore after message send
- 60-second fallback restore timeout
- Reminder minutes stored per Command + Guild
- Auto Populate On Zone stored per Command + Guild
- Auto-Remove Pending Chat stored globally under General
- Auto populate limited to parent zones
- Import/export with confirmation and success feedback
- Copy button for exported settings text
- Any guild message groups for reusable Guild/Officer messaging
- Case-insensitive substitutions for %time%, %guild%, and %zone%

The Any guild option is designed for reusable guild-facing content. Messages saved under Any can be used for any guild, but only when the output is Guild or Officer chat. Zone is intentionally blocked for Any.

Built-in substitutions:
- %time% -> morning, afternoon, or evening
- %guild% -> the resolved guild name for the current command context
- %zone% -> the player's current zone name

Tokens are case-insensitive, so %TIME%, %Guild%, and %Zone% also work.