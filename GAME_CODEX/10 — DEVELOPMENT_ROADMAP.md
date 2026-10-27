# Development Roadmap

Recommendations below are new, evidence-based proposals unless marked as existing. No implementation commitment is inferred from this list. Keep this document aligned with verified project changes.

## Preserve existing behavior

| Task | Rationale / dependencies | Acceptance criteria |
|---|---|---|
| Preserve server authority and packet contract | server/server.js owns simulation; client scripts depend on exact packet type and snapshot keys. | Existing room, input, attack, tower, rematch and return flow works for two clients after any change; documented packet names/fields match source. |
| Preserve current character and objective baseline | Character stats, 3/2/1 tower chunks and arena bounds are duplicated. | Any balance change updates server rules and client presentation where relevant; values remain explicitly documented. |

## Finish current systems

| Task | Relevant files | Rationale and result | Acceptance criteria |
|---|---|---|---|
| Validate/fix joystick class reference | MobileHUD.gd, VirtualJoystick.gd | Static mismatch may block parse. | Target Godot 4.7 imports project and starts; mobile HUD joystick works with scene and dynamic construction paths or unsupported path is removed. |
| Establish authoritative scene-loading strategy | Main.gd, GameWorld.gd, scenes/**/*.tscn | Wrappers are bypassed. | A chosen strategy is documented; runtime instance hierarchy matches intended editable scene content; all relevant scene edits affect runtime. |
| Decide ability component scope | AbilityComponent.gd, PlayerAvatar.gd, MobileHUD.gd, server.js | Current component is disconnected scaffold. | Either connect a fully specified ability end-to-end with HUD/protocol/server behavior, or document/remove scaffold as an explicit product decision. |
| Align prototype resource data strategy | resources/**/*.tres, CharacterCatalog.gd, server.js | Resources are empty labels and unreferenced; rules are hard-coded. | Decision is recorded; any adopted data source is loaded, validated and authoritative with client display consistency. |

## Stability and network validation

| Task | Relevant files | Rationale and dependencies | Acceptance criteria |
|---|---|---|---|
| Validate lifecycle edge cases | Main.gd, NetworkManager.gd, server.js | Disconnect and reconnect state handling is uncertain. | Test failed initial connection, mid-match disconnect, return, repeated join, rematch; no stale room/player state or silent errors. |
| Define protocol validation and versioning | NetworkManager.gd, GameWorld.gd, server.js | JSON dictionaries have no schema/version. | Malformed/unknown/missing fields are handled predictably; incompatible client/server is detected; protocol behavior is documented. |
| Gate match transitions by room phase | server.js handle(), startMatch() | start_match currently has no lobby-phase guard; a ready player can reset an active match. | start_match is accepted only in the intended phase; normal start succeeds and mid-match requests cannot reset game state. |
| Simulate tower defense boundary cases | server.js applyElectricDefense | Shared timer and tower iteration may affect overlapping zones. | Tests/documentation define expected damage cadence while entering/exiting overlapping towers and no order-dependent unintended damage remains. |
| Add repeatable baseline checks | project and server | No tests/CI found. | Target-engine import/parser check and server syntax/protocol checks run reproducibly; a two-client smoke checklist covers lifecycle and objective. |

## Core gameplay and product decisions

| Proposal | Rationale | Acceptance criteria |
|---|---|---|
| Decide whether flight is intended | Lobby text claims flying; mechanics are absent. | UI accurately describes shipped controls or a flight design is specified, implemented, and tested. |
| Tune combat using playtests | Values exist but are untested. | Sword/Boxer, dash, respawn and tower defense are tested with recorded baseline results before balance changes. |
| Define failure/feedback UX | No explicit defeat, timeout, latency or reconnect experience. | Expected user behavior and feedback for each state are specified and verified. |

## Optional future features

Possible additions such as more maps, characters, abilities, sound, persistence, AI practice, or matchmaking beyond room codes are not existing plans in inspected repository evidence. Consider only after project goals are confirmed. For each addition, define protocol impact, server authority, UI, compatibility and acceptance tests before development.

