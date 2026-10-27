# Gameplay Systems

All mechanics below are source-established. Godot runtime and live server behavior were not tested.

## Network room and match lifecycle

Two clients per room. Creator and joiner get red then blue by insertion order. Room code is five characters, uppercased for joins. Character selection accepts sword/boxer or preserves/defaults sword. Start requires exactly two players and both ready. Rematch in victory marks both ready and resets immediately. Return-to-lobby resets phase and readiness. Disconnect removes player, emits “The other player disconnected.” to remaining room members, and returns room to lobby; an empty room is deleted. State is RAM-only.

Protocol: client-to-server messages create_room(character), join_room(room), select_character(character), set_ready(ready), start_match, input(mx,my,dash), attack, destroy_tower, rematch, return_lobby. Server-to-client messages joined(room,player_id,team), lobby_state(players,can_start), match_started, snapshot(...), return_lobby, error(message). There is no protocol version or validation schema.

## Movement and dash

GameWorld computes keyboard vector with Input.get_vector and joystick Vector2. If both exist, it chooses whichever has the greater squared magnitude; it does not add them. Input packet nominally sent at 20 Hz. Server clamps each component to [-1,1], normalizes magnitude above 1, updates facing when magnitude >0.08, and accelerates velocity toward target movement vector. Acceleration applies when magnitude >0.05, otherwise deceleration. Server clamps positions 35 units inside arena.

| Character | Move speed | Accel / decel | Dash speed | Energy | Drain / regen per second |
|---|---:|---:|---:|---:|---:|
| Sword | 330 | 1450 / 1750 | 700 | 100 | 48 / 30 |
| Boxer | 360 | 1650 / 1900 | 650 | 100 | 42 / 36 |

Dash is a held state while input dash is true and energy remains; energy is clamped to [0,100]. It is not a one-shot impulse. No gravity, jumping, collision body, or obstacle response is implemented. Client avatar position interpolates snapshots with factor min(1,delta*14), not predictive movement.

## Melee, health, death, respawn

Client attack input sends attack. Server permits attack only in playing phase, while alive, and after cooldown. Combo index cycles through 0,1,2 while combo timer is positive; otherwise resets to index 0. A swing has configured active visual duration. On server ticks resolveAttack hits the only opponent at most once when attack timer >0, distance <= configured range + 24, and facing dot >=0.25. Direction is last nontrivial movement direction, defaulted by team at spawn. There is no separate aim.

| Character | Damage combo | Cooldown | Attack timer |
|---|---|---:|---:|
| sword | 22, 24, 34 | 0.42 s | 0.20 s |
| boxer | 14, 15, 24 | 0.24 s | 0.14 s |

HP reaches zero -> alive=false, destroy charge cleared, velocity zero, respawn timer 1.8 s. A living opposing attacker is granted destroyCharge. A player respawns at team spawn with full HP/dash and cleared action state if room remains playing. No score or death counter. Tower electric defense can kill, but passes no killer, so it grants no charge. If match leaves playing, dead player is not restored until match reset.

## Tower objective and defense

Each team has three towers at y=0 and mirrored x positions. IDs red_t1..t3 and blue_t1..t3; index 0..2. Initial chunks [3,2,1], active first tower. destroy_tower only works if playing, alive and destroyCharge true; server attacks the active tower belonging to the opposing team, reduces one chunk, consumes charge. It clears the active flag then advances to next surviving tower. No remaining tower -> phase victory and winner is attacker team. HUD only shows destroy button when local snapshot says destroy_charge and phase is playing.

Enemy tower radius 235; electric damage 7 every 0.85 seconds while a target qualifies. If the hit tower is not the currently active one, damage multiplier 1.9, rounded to integer (13). Defense also damages in active zone while opposing defender is alive; inactive advanced zones damage regardless of defender. applyElectricDefense iterates towers, checks first matching range, and uses one per-player electricTick timer. This ordering/shared timer behavior is a potential balance edge case, not runtime-confirmed.

## Arena and rendering

Client draws Rect2(-2300,-1100,4600,2200), center line/area, team strips, and grid every 240 units. Server bounds match and clamp player centers with 35-unit margin. Spawns at ±2135. No collision/physics shapes, tilemaps or obstacles. Tower and avatar illustrations are custom _draw() shapes; no imported animation or particles.

## Camera

CameraController follows local PlayerAvatar with facing-sign look-ahead up to (180,130), ignores an axis under 0.1 facing magnitude, clamps viewport center to arena, and lerps with factor min(1,delta*5). Viewport size is scaled by zoom. Camera is dynamically created and assigned local avatar when snapshot arrives.

## HUD and feedback

MobileHUD reads full snapshots: team HP, local dash energy/dashing, local destroy_charge, tower chunks/active ID, phase and winner. It has touch controls and keyboard remains in GameWorld. Victory panel has Rematch and Return to Lobby. No ammo, timer, score, pause, audio, haptics, or damage numbers. Tower redraw creates random electric line geometry every 0.18 seconds while drawing. No performance profile is available.

## Abilities, AI, physics, persistence

AbilityComponent only validates slots and emits ability_requested, defaults to zero slots, and has no listener in inspected project. No AI/enemy beyond the second network player, ranged weapon/projectile, jump/flight, collision-based world, persistence, matchmaking service, or audio implementation was found. Jolt is selected in project settings but client scenes contain no physics bodies.

