# Configuration and Dependencies

## Engine and project

project.godot uses config_version=5, config/name PA Fighter, run/main_scene res://main.tscn, feature string 4.7 and GL Compatibility. This specifies feature compatibility, not an exact engine patch. .vscode/settings.json points to Godot_v4.7.2-stable on D:, unavailable in this environment. No Godot binary was found on PATH, so exact compatibility is unknown.

Display: 540×960 viewport; canvas_items stretch; aspect expand; handheld orientation=1; no explicit window mode. Physics setting is 3d/physics_engine Jolt Physics. No client gameplay bodies/shapes were found. Rendering driver windows d3d12; renderer and mobile renderer gl_compatibility.

## Autoloads and plugins

No [autoload] section, addons directory, plugin.cfg, editor plugin, or Godot-side third-party dependency found. Main is root scene coordinator, not singleton.

## Input

Exact seven actions and bindings are listed in [INPUT_AND_USER_INTERFACE.md](06%20%E2%80%94%20INPUT_AND_USER_INTERFACE.md). All use deadzone 0.5. No gamepad mapping is configured.

## Server runtime and setup

server/package.json declares a private ES module package pa-fighter-server 0.1.0 with npm start -> node server.js and dependency ws ^8.18.0. package-lock resolves ws 8.22.0. Checked-in server/node_modules/ws is also present. Server uses Node built-in crypto randomUUID and process.env.PORT (default 8090). It binds on all interfaces (0.0.0.0) and speaks plain WebSocket. No environment file, credentials, external DB, or external service was found.

README setup: from server directory install dependencies with npm install, then npm start. In-game lobby uses ws://HOST:8090; README recommends TLS proxy and wss:// for public/HTTPS browser deployments. npm was not available as a shell command here; Node v24.22.1 was available. No dependency installation was attempted.

server/run_code.txt contains Set-ExecutionPolicy RemoteSigned -Scope CurrentUser, cd server, npm install, npm start. This is setup text only; this audit did not execute it.

## Export and platform requirements

No export_presets.cfg or build pipeline found. Project settings indicate handheld orientation and mobile renderer, but do not prove a tested mobile export. Server deployment needs reachable TCP port, configured PORT if nondefault, Node.js, and ws. No container, reverse proxy, TLS configuration, or platform-specific server config is included.

## Secret handling

No credential value was observed in inspected tracked configuration. Default endpoint is loopback and not a secret. Avoid committing live server credentials if future services are introduced.

