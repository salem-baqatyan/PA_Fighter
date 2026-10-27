# Input and User Interface

## Godot Input Map

All listed actions have deadzone 0.5.

| Action | Configured events | Consumer |
|---|---|---|
| move_left | A and Left Arrow | GameWorld._process via Input.get_vector |
| move_right | D and Right Arrow | GameWorld._process |
| move_up | W and Up Arrow | GameWorld._process |
| move_down | S and Down Arrow | GameWorld._process |
| attack | J and Space | GameWorld._process just-pressed |
| dash | Shift | GameWorld._process held / just-released |
| destroy_tower | E | GameWorld._process just-pressed |

No controller or touch InputMap bindings are present. Touch and mouse pointer control comes from VirtualJoystickControl GUI events and HUD buttons. No pause, confirm, or menu-navigation action is declared. Controller behavior is unverified.

## Routing

Movement reads keyboard vector and joystick state; the vector with greater squared magnitude wins. GameWorld transmits mx/my/dash every 0.05 s. Keyboard attack and destroy are sent on press. HUD Attack/Destroy buttons send the same messages; Dash button_down/up toggles dash_down. Joystick direction_changed -> HUD joystick_changed -> GameWorld.local_input. Lobby signals route through Main to NetworkManager. Server snapshots route back through NetworkManager to Main/GameWorld and then display.

## Lobby UI

LobbyUI builds a full-screen VBox with title, subtitle, server URL, room code, character selector, Create Room, Join Room, Ready, Start Match, status, two-slot roster and message label. URL defaults to ws://127.0.0.1:8090. Room field max length 8; server code generated length is 5. Character choice metadata is sword or boxer. Server controls Start eligibility through lobby_state.can_start. Create/join button has no client input validation or loading/disabled state shown in source. Errors appear in message label; connection status appears separately.

## Match HUD

MobileHUD constructs:
- Red and blue HP bars (each starts with max 100, overwritten by snapshot max_hp).
- Centered tower/chunk text with active tower marker.
- Dash bar (max 100) and energy/dashing button tint feedback.
- Lower-left virtual joystick.
- Attack and Dash buttons on lower-right.
- Conditional Destroy Tower button.
- Victory panel showing TEAM WINS with Rematch and Return to Lobby.

Snapshot is the data source for health, dash, tower state and victory. No local interpolation for HP UI, no settings/accessibility controls, no localization, no explicit focus-navigation logic. UI uses default theme/fonts; no custom font files. Mobile layout derives from 540x960 configured viewport and anchors/offsets; other aspect ratios have not been checked.

## Joystick behavior and risk

VirtualJoystickControl exports radius 74 and knob_radius 28. It captures one touch index at a time and also supports mouse drag, clamps input to radius, emits normalized values. MobileHUD tries node path VirtualJoystick and constructs a fallback if missing. However MobileHUD's variable type is VirtualJoystick, while the script declares class_name VirtualJoystickControl; target-engine parse behavior is unknown. See issue CODEX-001.

