# SmartChatMsg (v1.4.8)

ESO Add On for handling longer reusable chat messages through custom slash commands.

## What's New in 1.4.8
- Added **Populate Sound** at the **Command + Guild** level
- Added a **Preview** button next to the sound dropdown
- Limited the sound dropdown to a curated list of useful ESO sounds
- Includes **DUEL_START** by default and **None** for silent operation
- Sound plays when text is populated into chat by **Auto Populate on Zone** or **Repeat**

## Current Features
- Dynamic custom slash commands
- Parameters `1`-`5`, `g1`-`g5`, and `o1`-`o5` all resolve the same guild slot
- Multiple saved messages per command and guild
- Saved output channel selection for Zone, Guild, or Officer chat
- Chat channel auto-restore after send
- Timeout restore also clears the pending chat buffer
- Reminder minutes stored per Command + Guild
- Reminder retry minutes stored per Command + Guild
- Auto Populate Chat on Zone stored per Command + Guild
- Auto Populate cooldown stored per Command + Guild
- Populate sound stored per Command + Guild
- Global Auto-Remove Pending Chat timeout under General settings
- Import/export support for current settings
- Built-in substitutions for `%time%`, `%guild%`, and `%zone%`
