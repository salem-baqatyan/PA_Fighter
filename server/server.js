import { WebSocketServer } from "ws";
import { randomUUID } from "crypto";

const PORT = Number(process.env.PORT || 8090);
const TICK_HZ = 30;
const SNAPSHOT_HZ = 15;
const ARENA = { minX: -2300, maxX: 2300, minY: -1100, maxY: 1100 };
const RESPAWN_SECONDS = 1.8;

const CHARACTERS = {
  sword: {
    max_hp: 120,
    move_speed: 330,
    acceleration: 1450,
    deceleration: 1750,
    dash_speed: 700,
    dash_energy: 100,
    dash_drain: 48,
    dash_regen: 30,
    attack_range: 128,
    attack_width: 74,
    attack_damage: [22, 24, 34],
    attack_cooldown: 0.42,
    attack_duration: 0.20,
    combo_timeout: 0.85
  },
  boxer: {
    max_hp: 135,
    move_speed: 360,
    acceleration: 1650,
    deceleration: 1900,
    dash_speed: 650,
    dash_energy: 100,
    dash_drain: 42,
    dash_regen: 36,
    attack_range: 82,
    attack_width: 58,
    attack_damage: [14, 15, 24],
    attack_cooldown: 0.24,
    attack_duration: 0.14,
    combo_timeout: 0.70
  }
};

const TOWER_RULES = {
  electric_radius: 235,
  electric_damage: 7,
  electric_tick_interval: 0.85,
  inactive_damage_multiplier: 1.9
};

const rooms = new Map();
const sockets = new Map();

function code() {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let value = "";
  for (let i = 0; i < 5; i++) value += alphabet[Math.floor(Math.random() * alphabet.length)];
  return rooms.has(value) ? code() : value;
}

function send(ws, type, payload = {}) {
  if (ws.readyState === ws.OPEN) ws.send(JSON.stringify({ type, ...payload }));
}

function broadcast(room, type, payload = {}) {
  for (const player of room.players.values()) send(player.ws, type, payload);
}

function makeTowers(team) {
  const sign = team === "red" ? -1 : 1;
  const order = team === "red" ? [1, 2, 3] : [1, 2, 3];
  const xs = team === "red" ? [-1650, -1050, -470] : [1650, 1050, 470];
  const chunks = [3, 2, 1];
  return order.map((n, i) => ({
    id: `${team}_t${n}`,
    team,
    index: i,
    x: xs[i],
    y: 0,
    chunks: chunks[i],
    max_chunks: chunks[i],
    active: i === 0,
    electric_radius: TOWER_RULES.electric_radius,
    tick: 0,
    sign
  }));
}

function makeRoom() {
  const room = {
    code: code(),
    phase: "lobby",
    players: new Map(),
    towers: { red: makeTowers("red"), blue: makeTowers("blue") },
    winner: "",
    snapshotAccum: 0
  };
  rooms.set(room.code, room);
  return room;
}

function publicLobby(room) {
  const players = [...room.players.values()].map((p) => ({
    id: p.id,
    team: p.team,
    character: p.character,
    ready: p.ready
  }));
  return { players, can_start: room.players.size === 2 && players.every((p) => p.ready) };
}

function lobbyState(room) {
  broadcast(room, "lobby_state", publicLobby(room));
}

function spawnFor(team) {
  return team === "red" ? { x: ARENA.minX + 165, y: 0 } : { x: ARENA.maxX - 165, y: 0 };
}

function resetPlayerForMatch(p) {
  const cfg = CHARACTERS[p.character] || CHARACTERS.sword;
  const spawn = spawnFor(p.team);
  Object.assign(p, {
    x: spawn.x,
    y: spawn.y,
    vx: 0,
    vy: 0,
    facingX: p.team === "red" ? 1 : -1,
    facingY: 0,
    hp: cfg.max_hp,
    maxHp: cfg.max_hp,
    alive: true,
    respawnTimer: 0,
    dashEnergy: cfg.dash_energy,
    dashing: false,
    destroyCharge: false,
    attackCooldown: 0,
    attackTimer: 0,
    comboIndex: 0,
    comboTimer: 0,
    hitThisSwing: false,
    input: { mx: 0, my: 0, dash: false },
    electricTick: 0
  });
}

function resetRoom(room) {
  room.phase = "playing";
  room.winner = "";
  room.towers = { red: makeTowers("red"), blue: makeTowers("blue") };
  for (const p of room.players.values()) resetPlayerForMatch(p);
}

function startMatch(room) {
  if (room.players.size !== 2) return;
  if ([...room.players.values()].some((p) => !p.ready)) return;
  resetRoom(room);
  broadcast(room, "match_started");
}

function activeTower(room, defendingTeam) {
  return room.towers[defendingTeam].find((tower) => tower.chunks > 0) || null;
}

function opponentOf(room, player) {
  return [...room.players.values()].find((p) => p.id !== player.id) || null;
}

function damagePlayer(room, victim, amount, killer) {
  if (room.phase !== "playing" || !victim.alive) return;
  victim.hp = Math.max(0, victim.hp - amount);
  if (victim.hp > 0) return;
  victim.alive = false;
  victim.destroyCharge = false;
  victim.respawnTimer = RESPAWN_SECONDS;
  victim.vx = 0;
  victim.vy = 0;
  if (killer && killer.id !== victim.id && killer.alive) killer.destroyCharge = true;
}

function tryAttack(room, player) {
  if (room.phase !== "playing" || !player.alive || player.attackCooldown > 0) return;
  const cfg = CHARACTERS[player.character] || CHARACTERS.sword;
  player.comboIndex = player.comboTimer > 0 ? (player.comboIndex + 1) % 3 : 0;
  player.comboTimer = cfg.combo_timeout;
  player.attackCooldown = cfg.attack_cooldown;
  player.attackTimer = cfg.attack_duration;
  player.hitThisSwing = false;
}

function resolveAttack(room, attacker) {
  if (attacker.hitThisSwing || attacker.attackTimer <= 0 || !attacker.alive) return;
  const target = opponentOf(room, attacker);
  if (!target || !target.alive) return;
  const cfg = CHARACTERS[attacker.character] || CHARACTERS.sword;
  const dx = target.x - attacker.x;
  const dy = target.y - attacker.y;
  const dist = Math.hypot(dx, dy);
  if (dist > cfg.attack_range + 24) return;
  const fx = attacker.facingX || 1;
  const fy = attacker.facingY || 0;
  const dot = dist > 0 ? (dx / dist) * fx + (dy / dist) * fy : 1;
  if (dot < 0.25) return;
  attacker.hitThisSwing = true;
  damagePlayer(room, target, cfg.attack_damage[attacker.comboIndex], attacker);
}

function destroyTower(room, player) {
  if (room.phase !== "playing" || !player.alive || !player.destroyCharge) return false;
  const defending = player.team === "red" ? "blue" : "red";
  const tower = activeTower(room, defending);
  if (!tower) return false;
  tower.chunks = Math.max(0, tower.chunks - 1);
  player.destroyCharge = false;
  for (const t of room.towers[defending]) t.active = false;
  const next = activeTower(room, defending);
  if (next) {
    next.active = true;
  } else {
    room.phase = "victory";
    room.winner = player.team;
  }
  return true;
}

function updatePlayer(room, p, dt) {
  const cfg = CHARACTERS[p.character] || CHARACTERS.sword;
  p.attackCooldown = Math.max(0, p.attackCooldown - dt);
  p.attackTimer = Math.max(0, p.attackTimer - dt);
  p.comboTimer = Math.max(0, p.comboTimer - dt);
  if (p.comboTimer <= 0) p.comboIndex = 0;
  if (!p.alive) {
    p.respawnTimer -= dt;
    if (p.respawnTimer <= 0 && room.phase === "playing") resetPlayerForMatch(p);
    return;
  }
  const mx = Math.max(-1, Math.min(1, Number(p.input.mx) || 0));
  const my = Math.max(-1, Math.min(1, Number(p.input.my) || 0));
  const mag = Math.hypot(mx, my);
  const nx = mag > 1 ? mx / mag : mx;
  const ny = mag > 1 ? my / mag : my;
  if (mag > 0.08) {
    p.facingX = nx;
    p.facingY = ny;
  }
  const wantsDash = Boolean(p.input.dash) && p.dashEnergy > 0;
  p.dashing = wantsDash;
  if (wantsDash) p.dashEnergy = Math.max(0, p.dashEnergy - cfg.dash_drain * dt);
  else p.dashEnergy = Math.min(cfg.dash_energy, p.dashEnergy + cfg.dash_regen * dt);
  const targetSpeed = wantsDash ? cfg.dash_speed : cfg.move_speed;
  const desiredVx = nx * targetSpeed;
  const desiredVy = ny * targetSpeed;
  const accel = mag > 0.05 ? cfg.acceleration : cfg.deceleration;
  const step = Math.min(1, (accel * dt) / Math.max(1, Math.hypot(desiredVx - p.vx, desiredVy - p.vy)));
  p.vx += (desiredVx - p.vx) * step;
  p.vy += (desiredVy - p.vy) * step;
  p.x = Math.max(ARENA.minX + 35, Math.min(ARENA.maxX - 35, p.x + p.vx * dt));
  p.y = Math.max(ARENA.minY + 35, Math.min(ARENA.maxY - 35, p.y + p.vy * dt));
  resolveAttack(room, p);
  applyElectricDefense(room, p, dt);
}

function applyElectricDefense(room, p, dt) {
  const enemyTeam = p.team === "red" ? "blue" : "red";
  const enemy = opponentOf(room, p);
  for (const tower of room.towers[enemyTeam]) {
    if (tower.chunks <= 0) continue;
    const dist = Math.hypot(p.x - tower.x, p.y - tower.y);
    if (dist > tower.electric_radius) continue;
    p.electricTick -= dt;
    if (p.electricTick > 0) return;
    p.electricTick = TOWER_RULES.electric_tick_interval;
    const protectedAdvanced = activeTower(room, enemyTeam)?.id !== tower.id;
    const defenderAlive = enemy && enemy.alive;
    if (protectedAdvanced || defenderAlive) {
      const mult = protectedAdvanced ? TOWER_RULES.inactive_damage_multiplier : 1;
      damagePlayer(room, p, Math.round(TOWER_RULES.electric_damage * mult), null);
    }
    return;
  }
}

function snapshot(room) {
  const players = {};
  for (const p of room.players.values()) {
    players[p.id] = {
      team: p.team,
      character: p.character,
      x: p.x,
      y: p.y,
      facing_x: p.facingX,
      facing_y: p.facingY,
      hp: p.hp,
      max_hp: p.maxHp,
      alive: p.alive,
      dash_energy: p.dashEnergy,
      dashing: p.dashing,
      destroy_charge: p.destroyCharge,
      attack_timer: p.attackTimer,
      combo_index: p.comboIndex
    };
  }
  const towers = {
    red: room.towers.red.map((t) => ({ ...t, active: activeTower(room, "red")?.id === t.id })),
    blue: room.towers.blue.map((t) => ({ ...t, active: activeTower(room, "blue")?.id === t.id }))
  };
  return {
    phase: room.phase,
    winner: room.winner,
    players,
    towers,
    active_tower: {
      red: activeTower(room, "red")?.id || "",
      blue: activeTower(room, "blue")?.id || ""
    }
  };
}

function tick(dt) {
  for (const room of rooms.values()) {
    if (room.phase === "playing") {
      for (const p of room.players.values()) updatePlayer(room, p, dt);
    }
    room.snapshotAccum += dt;
    if (room.snapshotAccum >= 1 / SNAPSHOT_HZ) {
      room.snapshotAccum = 0;
      broadcast(room, "snapshot", snapshot(room));
    }
  }
}

function joinRoom(ws, room, character) {
  if (!room) return send(ws, "error", { message: "Invalid room ID." });
  if (room.players.size >= 2) return send(ws, "error", { message: "Room is full." });
  const id = randomUUID();
  const team = room.players.size === 0 ? "red" : "blue";
  const p = {
    id,
    ws,
    room,
    team,
    character: CHARACTERS[character] ? character : "sword",
    ready: false
  };
  resetPlayerForMatch(p);
  room.players.set(id, p);
  sockets.set(ws, p);
  send(ws, "joined", { room: room.code, player_id: id, team });
  lobbyState(room);
}

function handle(ws, msg) {
  let data;
  try {
    data = JSON.parse(msg.toString());
  } catch {
    return send(ws, "error", { message: "Invalid network packet." });
  }
  const type = String(data.type || "");
  const player = sockets.get(ws);
  if (type === "create_room") {
    const room = makeRoom();
    joinRoom(ws, room, String(data.character || "sword"));
    return;
  }
  if (type === "join_room") {
    joinRoom(ws, rooms.get(String(data.room || "").toUpperCase()), String(data.character || "sword"));
    return;
  }
  if (!player) return send(ws, "error", { message: "Create or join a room first." });
  const room = player.room;
  if (type === "select_character" && room.phase === "lobby") {
    player.character = CHARACTERS[data.character] ? data.character : player.character;
    resetPlayerForMatch(player);
    lobbyState(room);
  } else if (type === "set_ready" && room.phase === "lobby") {
    player.ready = Boolean(data.ready);
    lobbyState(room);
  } else if (type === "start_match") {
    startMatch(room);
  } else if (type === "input") {
    player.input = { mx: Number(data.mx) || 0, my: Number(data.my) || 0, dash: Boolean(data.dash) };
  } else if (type === "attack") {
    tryAttack(room, player);
  } else if (type === "destroy_tower") {
    if (!destroyTower(room, player)) send(ws, "error", { message: "Destroy Tower is not available." });
  } else if (type === "rematch" && room.phase === "victory") {
    for (const p of room.players.values()) p.ready = true;
    resetRoom(room);
    broadcast(room, "match_started");
  } else if (type === "return_lobby") {
    room.phase = "lobby";
    room.winner = "";
    for (const p of room.players.values()) p.ready = false;
    broadcast(room, "return_lobby");
    lobbyState(room);
  }
}

function leave(ws) {
  const player = sockets.get(ws);
  if (!player) return;
  sockets.delete(ws);
  const room = player.room;
  room.players.delete(player.id);
  broadcast(room, "error", { message: "The other player disconnected." });
  room.phase = "lobby";
  if (room.players.size === 0) rooms.delete(room.code);
  else lobbyState(room);
}

const wss = new WebSocketServer({ port: PORT });
wss.on("connection", (ws) => {
  ws.on("message", (msg) => handle(ws, msg));
  ws.on("close", () => leave(ws));
  ws.on("error", () => leave(ws));
});

setInterval(() => tick(1 / TICK_HZ), 1000 / TICK_HZ);
console.log(`PA-Fighter WebSocket server listening on ws://0.0.0.0:${PORT}`);
