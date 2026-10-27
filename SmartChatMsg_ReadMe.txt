SmartChatMsg 2.1.0

The full updated guide is SmartChatMsg_ReadMe_2.1.0.txt.
The Markdown version is docs/SmartChatMsg-2.1.0.md.
The standalone HTML guide is SmartChatMsg_Help_Guide_v2.1.0.html.

Peer-message spelling tolerance
-----------------------------
Incoming duplicate detection first tries the existing exact/normalized match. If that fails, a conservative spelling pass tolerates inserted, omitted, substituted or adjacent transposed English letters in fixed message text. Short notices with fewer than 40 fixed non-space/non-punctuation characters still require an exact match. The allowance is one letter edit for 40–159 such characters, two for 160–239, and three for longer messages. This is spelling tolerance, not a semantic similarity test.

Guild identity, guild links, numbers/prices, clocks/timezones and resolved event values remain protected. Punctuation and non-ASCII characters remain exact (normal capitalization, spacing and chat-color normalization still apply). Greeting, zone, event-when and countdown substitutions continue to use their existing validated matching rules. It still requires another sender and the correct channel/guild; accepted matches reset the same cooldowns with the existing 30–90 second randomized delay. No setting or SavedVariables migration is required.
