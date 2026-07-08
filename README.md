# Xp Track — WoW Classic TBC

Scalable XP bar with level progress, XP/min, ETA, quest turn-in preview, and rested XP tracking. Built for **WoW Classic TBC Anniversary** (2.5.6, interface **20506**).

Inspired by the [LOTRO TimeToLevel](https://github.com/RMFSonics/lotro-time-to-level) addon — rebuilt for WoW's native XP APIs.

## Features

- Live XP bar from `UnitXP` / `UnitXPMax`
- XP/min and ETA for the current level
- Quest turn-in preview on the bar and in the text line
- Rested XP tracking (`+Xk RXP`)
- Bar scale (50–150%) and opacity sliders
- Edit Mode placement and shift+drag free move
- Minimap button with options access
- Per-character session tracking across reloads
- Max level 70 (TBC)

## Install

1. Copy the **`XpTrack`** folder into your AddOns directory:

   **TBC Anniversary (2026):**
   ```
   World of Warcraft/_anniversary_/Interface/AddOns/XpTrack/
   ```

   **Legacy TBC Classic client (if applicable):**
   ```
   World of Warcraft/_classic_/Interface/AddOns/XpTrack/
   ```

2. Enable **Xp Track** on the character select AddOns screen.
3. In game: `/xptrack` or right-click the minimap button.

If upgrading from the old **TimeToLevel** folder, remove the old `TimeToLevel` AddOns folder after copying `XpTrack`. Your settings are preserved (`TimeToLevelDB` saved variables).

## Commands

| Command | Description |
|---------|-------------|
| `/xptrack` | Print stats to chat |
| `/xptrack show` / `hide` / `toggle` | XP bar |
| `/xptrack options` | Open options panel |
| `/xptrack reset` | Reset session stats for this level |
| `/xptrack sync` | Refresh from your XP bar |
| `/xptrack alpha <30-100>` | Set bar opacity |
| `/xptrack anchor bottom` | Reset to bottom center |
| `/xptrack minimap show` / `hide` / `toggle` | Minimap button |

Legacy aliases: `/ttl`, `/timetolevel`

## Requirements

- WoW Classic TBC Anniversary 2.5.6 (build 68502, interface 20506) or compatible TBC 2.5.x client
- No external dependencies

## Project layout

```
XpTrack/
  XpTrack.toc
  Core.lua
  Tracker.lua
  Window.lua
  MinimapButton.lua
  Options.lua
  Settings.lua
  Util.lua
```

## License

MIT — see [LICENSE](LICENSE).
