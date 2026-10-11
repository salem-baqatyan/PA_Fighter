# PA-Fighter Prototype Server

This is the authoritative WebSocket server for the Godot Web/mobile prototype.

Run it on a machine both browsers can reach:

```powershell
cd server
npm install
npm start
```

Then use `ws://YOUR_SERVER_IP:8090` in the in-game lobby.

For Internet play outside your LAN, host this process on a public server and use `wss://` behind a TLS reverse proxy. Browser Web exports served over HTTPS generally require secure WebSockets.
