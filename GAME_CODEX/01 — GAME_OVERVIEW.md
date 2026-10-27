# Game Overview

## Evidence and intended design

The project title in project.godot is PA Fighter; the lobby labels the prototype “PA-Fighter” and “Two-player flying arena prototype.” The implementation supports a two-player online arena fighter. The word “flying” appears in UI copy only: no flight input, altitude, gravity, or flying state is present in the inspected scripts. Treat flight as unverified intended design.

The rendered game is 2D, top-down/omnidirectional, with a dark arena, team-colored zones and towers, geometric characters, health bars, and simple drawn melee effects. This style is established by GameWorld._draw(), PlayerAvatar._draw(), and TowerNode._draw(), not by external sprite art. No inspirations or narrative theme are documented.

## Implemented loop (source evidence; not runtime-tested)

1. A player enters a WebSocket server URL and creates a room or joins a five-character room code.
2. Server assigns the first player red and second blue. Each selects one of two characters and marks ready. The room can start when two players are ready.
3. Players move in a bounded arena, face movement direction, hold dash while energy remains, and issue melee attacks.
4. A knockout temporarily removes a player for 1.8 seconds. A kill grants the living attacker one tower-destruction charge.
5. The charged player requests destruction of the opponent's current active tower. Each team has three sequential towers with 3, 2, and 1 chunks; each charge removes one chunk.
6. Destroying the final opposing tower sets the winner and victory phase. Rematch resets the match and marks both ready; Return to Lobby changes phase and keeps the room connections.

The server is authoritative for all listed match state. Client input sampling is not a local simulation.

## Characters

| ID | Display name | HP | Speed | Dash speed / energy | Melee details |
|---|---|---:|---:|---:|---|
| sword | Sword Fighter | 120 | 330 | 700 / 100 | Range 128; width 74; combo damage 22/24/34; cooldown 0.42 s; active visual 0.20 s; combo timeout 0.85 s |
| boxer | Boxer | 135 | 360 | 650 / 100 | Range 82; width 58; combo damage 14/15/24; cooldown 0.24 s; active visual 0.14 s; combo timeout 0.70 s |

Values are duplicated in scripts/core/CharacterCatalog.gd and server/server.js. Server values govern gameplay; catalog values support client display and drawing. Damage resolution uses range + 24 and a facing dot threshold of 0.25. The displayed width is not part of the server hit test.

## Match, arena, and objectives

There is one code-defined arena: server bounds x [-2300, 2300], y [-1100, 1100], with player clamps 35 units inside those limits. Client GameWorld uses Rect2(-2300, -1100, 4600, 2200). Spawns are x=-2135 for red and x=2135 for blue, y=0. There is no map selector or additional map resource.

Tower coordinates are red [-1650, -1050, -470] and blue [1650, 1050, 470], y=0. Each team's tower chunk sequence is [3,2,1]; first is active. The server damages players entering enemy tower radius 235 on a 0.85-second cadence: base damage 7, or 13 when an advanced tower is inactive (7 × 1.9 rounded). The described current mechanic is based on code only; tower effects were not playtested.

## Win, loss, and absent modes

Server victory is awarded to the player whose team destroys all three enemy towers (six total chunks). Player death is not match loss: respawn occurs after 1.8 seconds while the phase remains playing. No timer, score screen, AI opponent, local single-player mode, ranked mode, or explicit defeat flow appears in the code. GameState declares unused phase enum values for defeat and player-dead states; these are not evidence of implemented modes.

## Present versus future

Present in inspected code: room lobby, two characters, keyboard and touch-oriented controls, client-drawn arena/avatars/towers/HUD, server-driven movement/combat/respawn/tower objective, victory, rematch, return to lobby.

Incomplete, unverified, or not found: target Godot parse/start, live multiplayer, ability behavior, flight, collision physics, sound, sprite animation, persistence, more maps or characters, matchmaking beyond room codes, server deployment/TLS automation. See [KNOWN_ISSUES_AND_TECHNICAL_DEBT.md](09%20%E2%80%94%20KNOWN_ISSUES_AND_TECHNICAL_DEBT.md) and [DEVELOPMENT_ROADMAP.md](10%20%E2%80%94%20DEVELOPMENT_ROADMAP.md).

