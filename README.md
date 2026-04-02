# SmartChatMsg (v1.5.1)

ESO Add On for handling longer reusable chat messages through custom slash commands.

## What's New in 1.5.1
- Renamed **Repeat After** to **Repeat Every**
- Renamed **Try Again** to **Retry Delay**
- `0`, blank, and invalid retry values now disable retry and resume the normal repeat cycle after the populate timeout
- Retry delay now automatically clamps down to the repeat interval when it is set higher than repeat
- Updated documentation to explain the new repeat and retry behavior

## Current Features
- Dynamic custom slash commands
- Parameters `1`-`5`, `g1`-`g5`, and `o1`-`o5` all resolve the same guild slot
- Multiple saved messages per command and guild
- Saved output channel selection for Zone, Guild, or Officer chat
- Chat channel auto-restore after send
- Timeout restore also clears the pending chat buffer
- Repeat interval stored per Command + Guild
- Retry delay stored per Command + Guild
- Auto Populate Chat on Zone stored per Command + Guild
- Auto Populate cooldown stored per Command + Guild
- Populate sound stored per Command + Guild
- Global Auto-Remove Pending Chat timeout under General settings
- Import/export support for current settings
- Built-in substitutions for `%time%`, `%guild%`, and `%zone%`
