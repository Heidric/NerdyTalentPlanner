# Nerdy Talent Planner

Nerdy Talent Planner is an in-game talent calculator and build planner. It lets you plan talents for any class, save builds, import and export them, and share clickable build links through chat.

Brought to the community by the Nerds of a Feather guild.

## Features

- Allows planning talents for any class
- Displays the full leveling plan
- Allows saving builds for later use
- Supports loading, exporting, renaming, and deleting saved builds
- Exports builds using a compact `NTP4` format
- Imports builds from pasted export strings
- Converts shared `NTP4` strings in chat into clickable import links

## Commands

- `/ntp` - open or close the talent planner
- `/ntp resetpos` - reset the launcher button position

## Build Sharing

Use the **Export** button to copy the current build as an `NTP4` string.

When another player posts an `NTP4` build string in chat, Nerdy Talent Planner turns it into a clickable link, for example:

`[NTP Build: Hunter]`

Clicking the link opens the import window with the build string already inserted. Press **Import** to load the build and open it in the planner.

## Saved Builds

Use the **Builds** window to manage saved builds.

Saved builds can be:

- loaded
- renamed
- exported
- deleted

The saved build list is stored locally.
