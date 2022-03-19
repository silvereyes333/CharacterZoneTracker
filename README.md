# Character Zone Tracker

Elder Scrolls Online addon that tracks zone completion for delves, world bosses and world events per-character.



## FEATURES

- Backed up zone completion for delves, world bosses and world events (dolmens, geysers, etc.) in the previous release, Update 32.
- Tracks character zone completion for delves, world bosses and world events once Update 33 is released.
- Shows completion popup announcements for delves, world bosses and world events on individual characters once Update 33 is released.
- Adds tools to reset delves, world bosses or world events. (Keyboard only)
- Adds tools to set a character to load delve, world boss and world event completion from the account (Keyboard only)



## DEPENDENCIES

- [LibSavedVars](https://www.esoui.com/downloads/info2161-LibSavedVars.html)



## KNOWN ISSUES / PLANNED FIXES

- Compass shows account-wide icons. This is not intended, and will be fixed in a future update.
- No text localization for non-English languages, yet.
- For non-English languages, any kills of a dangerous monster (e.g. Dwarven Centurion, Storm Atronach, Troll, etc.) inside of a delve released before Clockwork City will cause the delve to be reported as complete. This is not indented, and will be fixed in a future update.
- Multi-boss delves in Cyrodiil, Craglorn and Hew's Bane report delve completion after only a single boss kill. This is not intended, and will be fixed in a future update.
- Delves with quests that include bosses inside the delve (e.g. Vessel of Worms in the Traitor's Vault quest Half-Formed Understandings, in Artaeum) will be marked complete when the quest boss is killed. This is not intended, and will be fixed in a future update.



## LIMITATIONS

- A game client crash will wipe your progress. To ensure your progress is saved, either relog, or do a /reloadui periodically.
- Progress is tracked in the local SavedVariables folder. Back up your files, preferably to the cloud, to prevent data loss if your storage device fails.



## RELEASE NOTES

### Version 1.2.1
- Bugfix: fix error thrown when a world event ends and you are not in range.
- Bugfix: fix errors thrown when hovering over map pins in gamepad mode

### Version 1.2.0
- Replace achievement tooltips in zone guide / map completion with character-specific zone guide tooltips
- Remove code for Update 32 support
- Performance optimizations
- Compatibility patch for addons that mute center screen announcements
- Moved API overrides to EVENT_ADD_ON_LOADED for compatibility with other addons.
- Bugfix: Fix dolmens being marked complete just for being in range of the compass pin when it they are defeated by someone else.
- Bugfix: Fix Traitor's Vault delve in Artaeum not being marked complete
- Bugfix: Fix map POI menus not appearing
- Bugfix: Fix the Murkmire Echoing Hollow world boss not being marked complete when Walks-Like-Thunder is killed.

### Version 1.1.0
- Added support for backing up Craglorn group delve progress. Note: you will need to log in to each character again to add this to your Update 32 backup. Sorry for missing this initially. :(
- Bugfix: Killing a non-boss dangerous monster in a delve with German as the selected language no longer marks the delve complete prematurely.
- Bugfix: Fixes exception thrown when killing a Patrolling Horror in Imperial City
- Bugfix: Fixes exception thrown when killing a dangerous monster in a delve while playing with a language other than English

### Version 1.0.0
- Initial release
- Backs up zone completion for delves, world bosses and world events (dolmens, geysers, etc.) on live (Update 32).
- Tracks character zone completion for delves, world bosses and world events once Update 33 is released.
- Shows completion popup announcements for delves, world bosses and world events on individual characters once Update 33 is released.
- Adds tools to reset delves, world bosses or world events. (Keyboard only)
- Adds tools to set a character to load delve, world boss and world event completion from the account (Keyboard only)
