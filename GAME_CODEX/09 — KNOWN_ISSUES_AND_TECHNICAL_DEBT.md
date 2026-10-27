# Known Issues and Technical Debt

Severity describes potential project impact, not certainty. No runtime bug is claimed from static inspection alone.

## CODEX-001 — Joystick type name differs from declared class

- Severity: High (potential parse blocker); confidence: High that names differ, medium about runtime failure.
- Status: Suspected, requires target Godot verification.
- Paths: scripts/ui/MobileHUD.gd variable declaration and fallback construction; scripts/ui/VirtualJoystick.gd class_name.
- Evidence: MobileHUD declares joystick: VirtualJoystick and calls VirtualJoystick.new(). The joystick script declares class_name VirtualJoystickControl. No other class definition named VirtualJoystick was found.
- Impact: If the unresolved identifier prevents GDScript parsing, MobileHUD, game world and project launch may fail.
- Next: run Godot 4.7 editor/import or headless parse, capture exact error, then align type/constructor or provide compatibility class if needed. Do not assume failure until engine confirms.

## CODEX-002 — Scene wrappers do not describe most runtime-created instances

- Severity: Medium; confidence: High.
- Status: Confirmed architecture; consequences depend on intended workflow.
- Paths: scripts/core/Main.gd, scripts/game/GameWorld.gd; all scenes/* wrappers.
- Evidence: Main uses LobbyUI.new() and GameWorld.new(); GameWorld uses CameraController.new(), MobileHUD.new(), PlayerAvatar.new(), TowerNode.new(). No preload/load/instantiate path to corresponding .tscn was found. Mobile HUD's serialized joystick child therefore is absent on current construction path and fallback is intended.
- Impact: Changes made only to wrapper node properties/children do not affect those dynamically-created runtime nodes. Wrapper may be stale.
- Next: Decide whether wrappers are intentional editor scaffolds or should become authoritative; update docs and test after a deliberate architecture change.

## CODEX-003 — Client and server duplicate gameplay constants/protocol fields

- Severity: Medium; confidence: High.
- Status: Confirmed maintenance risk.
- Paths: scripts/core/CharacterCatalog.gd, scripts/game/GameWorld.gd, scripts/players/PlayerAvatar.gd, scripts/towers/TowerNode.gd, server/server.js.
- Evidence: Character data repeated client/server; arena dimensions repeated; server snapshot key names are consumed directly by GDScript.
- Impact: Balance, display, bounds or serialization drift can create incorrect visuals or inconsistent play. Current inspected values for main character stats and arena match, but tower visual default electric_radius is 210 until server snapshot updates it from 235.
- Next: Add a protocol/constant consistency check or generate shared data only after choosing a safe cross-language source of truth.

## CODEX-004 — Connection lifecycle and lobby state reset are lightly managed

- Severity: Medium; confidence: Medium.
- Status: Suspected robustness gap.
- Paths: scripts/core/Main.gd; scripts/networking/NetworkManager.gd.
- Evidence: disconnect handler shows lobby but does not clear local_id or pending_action. Main does not call close() during return_lobby. connect_to_server replaces socket; server cleans up on close. Failed connection behavior differs from established connection close handling because _process() emits disconnected only after _connected was true.
- Impact: Stale local state or inconsistent user messaging may appear after failed/repeated connections. Exact UX depends on WebSocketPeer state transitions.
- Next: Exercise unreachable URL, server loss, return and rejoin; define expected state reset and verify it.

## CODEX-005 — Tower defense zone overlap/order deserves simulation

- Severity: Low to Medium; confidence: Medium.
- Status: Suspected balance/edge-case issue, not established bug.
- Paths: server/server.js applyElectricDefense(), updatePlayer().
- Evidence: One per-player electricTick is decremented within the loop over enemy towers; first matching in-range tower controls that tick and returns. Tower order is fixed in arrays.
- Impact: Overlapping radii or moving between zones may make which tower supplies damage dependent on array order and timer history.
- Next: Map radius overlap and simulate boundary transitions; define desired rule before changing behavior.

## CODEX-006 — No runtime validation or automated project tests

- Severity: Medium; confidence: High.
- Status: Confirmed repository gap.
- Paths: whole repository; no test/CI files found.
- Evidence: tracked inventory contains no test harness or CI workflow; Godot binary unavailable in this environment.
- Impact: GDScript parse, scene load, client-server protocol, mobile layout and multiplayer regressions are currently difficult to catch automatically.
- Next: First validate target Godot parse/start and the two-client loop manually; introduce focused checks after baseline works.

## CODEX-007 — start_match handler is not phase-gated

- Severity: Medium; confidence: High.
- Status: Confirmed server-side state-transition gap; exploitability assumes a connected client can send protocol messages directly.
- Path: server/server.js handle(), startMatch().
- Evidence: handle() calls startMatch(room) for every start_match packet without checking room.phase. startMatch() checks player count and readiness only. Both ready flags remain true after resetRoom() starts play.
- Impact: Either connected player can send start_match during an active game and reset positions, health, towers, dash and combat state without a return-to-lobby transition.
- Next: Define valid phase transitions; reject start_match outside lobby and verify both normal start and mid-match request behavior with two clients.

## Additional observations

- Lobby subtitle mentions flying, while inspected gameplay has no flight system (documentation mismatch; whether a design defect is intended is unknown).
- .tres character/tower resources only carry resource_name and have no call-site references.
- Server is plain ws; README describes TLS proxy for public deployments, but no deployment configuration exists.
- Server rooms are in-memory and lost on process restart; no persistence is evidenced.
- PlayerAvatar interpolation and tower redraw use per-frame/periodic draw calls. No profiling shows a performance problem.

