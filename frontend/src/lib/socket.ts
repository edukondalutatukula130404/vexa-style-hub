// Real-time WebSocket Client Manager for VEXA Frontend Web Application
// Permanent hardened implementation with auto-reconnect, queuing, and heartbeat

class VexaSocketClient {
  private socket: WebSocket | null = null;
  private reconnectTimer: any = null;
  private pingTimer: any = null;
  private url: string;
  private sendQueue: Array<{ type: string; data: any }> = [];
  private isConnecting = false;

  constructor() {
    const isHttps = typeof window !== "undefined" && window.location.protocol === "https:";
    const wsProtocol = isHttps ? "wss:" : "ws:";
    const host = typeof window !== "undefined" ? (window.location.hostname || "localhost") : "localhost";
    this.url = `${wsProtocol}//${host}:5000`;
  }

  get isOpen(): boolean {
    return this.socket !== null && this.socket.readyState === WebSocket.OPEN;
  }

  public connect() {
    if (typeof window === "undefined") return;
    if (this.isConnecting || this.isOpen) return;

    this.isConnecting = true;

    try {
      this.socket = new WebSocket(this.url);

      this.socket.onopen = () => {
        console.log("⚡ [VexaWS] Connected to VEXA Realtime WebSocket Server");
        this.isConnecting = false;

        // Clear any pending reconnect
        if (this.reconnectTimer) {
          clearTimeout(this.reconnectTimer);
          this.reconnectTimer = null;
        }

        // Flush queued messages
        this.flushQueue();

        // Heartbeat ping every 25 seconds to keep connection alive through proxies/firewalls
        if (this.pingTimer) clearInterval(this.pingTimer);
        this.pingTimer = setInterval(() => {
          if (this.isOpen) {
            this.socket!.send(JSON.stringify({ type: "PING", timestamp: Date.now() }));
          }
        }, 25000);
      };

      this.socket.onmessage = (event) => {
        try {
          const payload = JSON.parse(event.data);
          const { type, data } = payload;

          // Dispatch global custom events so admin.tsx & dashboard.tsx update in real-time
          window.dispatchEvent(new CustomEvent("vexa_ws_message", { detail: payload }));

          if (
            type === "ORDER_CREATED" ||
            type === "ORDER_STATUS_UPDATED" ||
            type === "ORDER_DELETED" ||
            type === "ORDERS_UPDATED"
          ) {
            window.dispatchEvent(new CustomEvent("vexa_orders_updated", { detail: data }));
          }

          if (
            type === "ITEM_CREATED" ||
            type === "ITEM_UPDATED" ||
            type === "ITEM_DELETED" ||
            type === "ITEMS_UPDATED"
          ) {
            window.dispatchEvent(new CustomEvent("vexa_items_updated", { detail: data }));
            window.dispatchEvent(new CustomEvent("vexa_inventory_updated", { detail: data }));
          }

          if (type === "USER_CREATED" || type === "USERS_UPDATED") {
            window.dispatchEvent(new CustomEvent("vexa_users_updated", { detail: data }));
          }
        } catch (e) {
          console.warn("[VexaWS] Message parse error:", e);
        }
      };

      this.socket.onclose = (event) => {
        console.log(`[VexaWS] Disconnected (code ${event.code}). Reconnecting...`);
        this.isConnecting = false;
        this.socket = null;
        if (this.pingTimer) {
          clearInterval(this.pingTimer);
          this.pingTimer = null;
        }
        this.scheduleReconnect();
      };

      this.socket.onerror = () => {
        this.isConnecting = false;
        this.socket = null;
        this.scheduleReconnect();
      };
    } catch (e) {
      this.isConnecting = false;
      this.scheduleReconnect();
    }
  }

  private flushQueue() {
    const pending = [...this.sendQueue];
    this.sendQueue = [];
    pending.forEach(({ type, data }) => {
      if (this.isOpen) {
        this.socket!.send(JSON.stringify({ type, data, timestamp: Date.now() }));
      }
    });
  }

  private scheduleReconnect() {
    if (this.reconnectTimer) return;
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, 3000);
  }

  /** Send a typed event; queues automatically if not yet connected */
  public send(type: string, data: any) {
    if (this.isOpen) {
      this.socket!.send(JSON.stringify({ type, data, timestamp: Date.now() }));
    } else {
      this.sendQueue.push({ type, data });
      this.connect(); // Ensure we're connecting
    }
  }
}

export const vexaSocket = new VexaSocketClient();
