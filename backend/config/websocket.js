const { WebSocketServer } = require('ws');

let wss = null;
let clientCount = 0;

function initWebSocket(server) {
  wss = new WebSocketServer({ noServer: true, clientTracking: true });

  server.on('upgrade', (request, socket, head) => {
    wss.handleUpgrade(request, socket, head, (ws) => {
      wss.emit('connection', ws, request);
    });
  });

  wss.on('connection', (ws, req) => {
    clientCount++;
    const clientId = `client-${clientCount}`;
    const origin = req.headers.origin || req.socket.remoteAddress || 'unknown';
    console.log(`⚡ [WS] ${clientId} connected from ${origin}. Active clients: ${wss.clients.size}`);

    // Send connection confirmation
    safeSend(ws, {
      type: 'CONNECTED',
      data: {
        clientId,
        status: 'Connected',
        message: 'VEXA Live Realtime Sync Active',
        activeClients: wss.clients.size,
      },
      timestamp: Date.now(),
    });

    ws.on('message', (raw) => {
      try {
        const parsed = JSON.parse(raw);
        const { type, data } = parsed;

        if (type === 'PING') {
          // Respond to keep-alive ping
          safeSend(ws, { type: 'PONG', timestamp: Date.now() });
          return;
        }

        if (type && data) {
          // Re-broadcast any client event (mobile ORDER_CREATED, web checkout, etc.) to ALL clients
          console.log(`⚡ [WS] Re-broadcasting "${type}" from ${clientId} to ${wss.clients.size - 1} other client(s).`);
          broadcastExcept(ws, type, data);
        }
      } catch (e) {
        // Ignore malformed messages
      }
    });

    ws.on('close', (code, reason) => {
      console.log(`🔌 [WS] ${clientId} disconnected (${code}). Active clients: ${wss.clients.size}`);
    });

    ws.on('error', (err) => {
      console.warn(`⚠️ [WS] ${clientId} error: ${err.message}`);
    });
  });

  wss.on('error', (err) => {
    console.error('[WS] Server error:', err.message);
  });

  console.log('✅ [WS] WebSocket server initialized and listening.');
  return wss;
}

/** Send payload safely to a single client */
function safeSend(ws, payload) {
  try {
    if (ws.readyState === 1) {
      ws.send(JSON.stringify(payload));
    }
  } catch (e) {
    // Ignore send errors
  }
}

/** Broadcast a typed event to ALL connected clients */
function broadcast(type, data) {
  if (!wss) return;
  const payload = JSON.stringify({ type, data, timestamp: Date.now() });
  let sent = 0;
  wss.clients.forEach((client) => {
    if (client.readyState === 1) {
      try {
        client.send(payload);
        sent++;
      } catch (e) {}
    }
  });
  if (sent > 0) {
    console.log(`📡 [WS] Broadcast "${type}" to ${sent} client(s).`);
  }
}

/** Broadcast to all clients EXCEPT the sender (for re-broadcasting mobile events) */
function broadcastExcept(sender, type, data) {
  if (!wss) return;
  const payload = JSON.stringify({ type, data, timestamp: Date.now() });
  let sent = 0;
  wss.clients.forEach((client) => {
    if (client !== sender && client.readyState === 1) {
      try {
        client.send(payload);
        sent++;
      } catch (e) {}
    }
  });
  if (sent > 0) {
    console.log(`📡 [WS] Re-broadcast "${type}" to ${sent} other client(s).`);
  }
}

module.exports = { initWebSocket, broadcast, broadcastExcept };
