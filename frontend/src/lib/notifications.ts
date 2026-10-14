import { useState, useEffect, useCallback } from "react";
import { API_URL, getAuthUser } from "./auth";

export interface NotificationItem {
  id: string;
  _id?: string;
  title: string;
  message: string;
  body?: string;
  type?: "order_status_update" | "promo" | "support" | "admin" | "system" | "drop" | string;
  orderId?: string;
  ticketId?: string;
  category?: string;
  createdAt: string;
  read: boolean;
  actionUrl?: string;
}

const STORAGE_KEY = "vexa_user_notifications";
const NOTIFICATIONS_CHANGED_EVENT = "vexa_notifications_updated";

const INITIAL_SAMPLES: NotificationItem[] = [
  {
    id: "notif-order-1",
    title: "Order Confirmed 🎉",
    message: "Your order #VX-1806 has been confirmed.",
    type: "order_confirmed",
    orderId: "VX-1806",
    read: false,
    createdAt: new Date().toISOString(),
    actionUrl: "/dashboard?tab=orders",
  },
  {
    id: "notif-order-2",
    title: "Order Delivered ✅",
    message: "Your order #VX-1806 has been delivered successfully.",
    type: "order_delivered",
    orderId: "VX-1806",
    read: false,
    createdAt: new Date(Date.now() - 1000 * 60 * 2).toISOString(),
    actionUrl: "/dashboard?tab=orders",
  },
  {
    id: "notif-order-3",
    title: "Out for Delivery 🚚",
    message: "Your order #VX-1806 is out for delivery.",
    type: "out_for_delivery",
    orderId: "VX-1806",
    read: false,
    createdAt: new Date(Date.now() - 1000 * 60 * 15).toISOString(),
    actionUrl: "/dashboard?tab=orders",
  },
  {
    id: "notif-order-4",
    title: "Order Placed 📦",
    message: "Your order #VX-1086 has been placed successfully.",
    type: "order_placed",
    orderId: "VX-1086",
    read: false,
    createdAt: new Date(Date.now() - 1000 * 60 * 45).toISOString(),
    actionUrl: "/dashboard?tab=orders",
  },
  {
    id: "notif-order-5",
    title: "Order Placed 📦",
    message: "Your order #VX-1993 has been placed successfully.",
    type: "order_placed",
    orderId: "VX-1993",
    read: false,
    createdAt: new Date(Date.now() - 1000 * 60 * 120).toISOString(),
    actionUrl: "/dashboard?tab=orders",
  },
  {
    id: "notif-order-6",
    title: "Order Processing",
    message: "Your order #VX-1993 is now being prepared.",
    type: "order_processing",
    orderId: "VX-1993",
    read: false,
    createdAt: new Date(Date.now() - 1000 * 60 * 240).toISOString(),
    actionUrl: "/dashboard?tab=orders",
  },
  {
    id: "notif-order-7",
    title: "Order Placed 📦",
    message: "Your order #VX-1279 has been placed successfully.",
    type: "order_placed",
    orderId: "VX-1279",
    read: false,
    createdAt: new Date(Date.now() - 1000 * 60 * 360).toISOString(),
    actionUrl: "/dashboard?tab=orders",
  },
  {
    id: "notif-order-8",
    title: "Order Shipped 📦",
    message: "Your order #VX-1993 has been shipped.",
    type: "order_shipped",
    orderId: "VX-1993",
    read: false,
    createdAt: new Date(Date.now() - 1000 * 60 * 480).toISOString(),
    actionUrl: "/dashboard?tab=orders",
  },
];

export function getStoredNotifications(): NotificationItem[] {
  if (typeof window === "undefined") return INITIAL_SAMPLES;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(INITIAL_SAMPLES));
      return INITIAL_SAMPLES;
    }
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : INITIAL_SAMPLES;
  } catch (e) {
    return INITIAL_SAMPLES;
  }
}

export function saveStoredNotifications(items: NotificationItem[]) {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(items));
    window.dispatchEvent(new CustomEvent(NOTIFICATIONS_CHANGED_EVENT, { detail: items }));
  } catch (e) {
    console.warn("Could not save notifications to storage", e);
  }
}

export function getUnreadNotificationCount(): number {
  const items = getStoredNotifications();
  return items.filter((n) => !n.read).length;
}

export function addNotificationItem(notif: Partial<NotificationItem>) {
  const items = getStoredNotifications();
  const newItem: NotificationItem = {
    id: notif.id || notif._id || `notif-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
    title: notif.title || "Notification",
    message: notif.message || notif.body || "",
    body: notif.body || notif.message || "",
    type: notif.type || "system",
    orderId: notif.orderId,
    ticketId: notif.ticketId,
    category: notif.category,
    createdAt: notif.createdAt || new Date().toISOString(),
    read: false,
    actionUrl: notif.actionUrl,
  };

  // Avoid identical duplicate within latest items
  const exists = items.some(
    (existing) =>
      existing.id === newItem.id ||
      (existing.title === newItem.title && existing.message === newItem.message)
  );

  if (!exists) {
    const updated = [newItem, ...items];
    saveStoredNotifications(updated);
  }
}

export function useNotifications() {
  const [notifications, setNotifications] = useState<NotificationItem[]>(() => getStoredNotifications());
  const [loading, setLoading] = useState(false);

  const syncRemote = useCallback(async () => {
    const user = getAuthUser();
    if (!user?.email) return;

    try {
      setLoading(true);
      const res = await fetch(`${API_URL}/notifications?email=${encodeURIComponent(user.email)}`);
      if (res.ok) {
        const data = await res.json();
        if (data?.success && Array.isArray(data.data) && data.data.length > 0) {
          const remoteMapped: NotificationItem[] = data.data.map((item: any) => ({
            id: item._id || item.id,
            _id: item._id,
            title: item.title,
            message: item.message || item.body || "",
            body: item.message || item.body || "",
            type: item.type || "order_status_update",
            orderId: item.orderId || item.associatedOrderId,
            ticketId: item.ticketId,
            category: item.category,
            createdAt: item.createdAt || new Date().toISOString(),
            read: Boolean(item.read),
            actionUrl: item.orderId ? "/dashboard?tab=orders" : item.ticketId ? "/dashboard?tab=support" : undefined,
          }));

          setNotifications((prev) => {
            // Merge remote with local items keeping order by date
            const mergedMap = new Map<string, NotificationItem>();
            remoteMapped.forEach((r) => mergedMap.set(r.id, r));
            prev.forEach((p) => {
              if (!mergedMap.has(p.id)) {
                mergedMap.set(p.id, p);
              }
            });
            const mergedList = Array.from(mergedMap.values()).sort(
              (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
            );
            localStorage.setItem(STORAGE_KEY, JSON.stringify(mergedList));
            return mergedList;
          });
        }
      }
    } catch (err) {
      console.warn("Failed to fetch remote notifications", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    syncRemote();

    const handleUpdate = () => {
      setNotifications(getStoredNotifications());
    };

    window.addEventListener(NOTIFICATIONS_CHANGED_EVENT, handleUpdate);
    window.addEventListener("storage", handleUpdate);

    return () => {
      window.removeEventListener(NOTIFICATIONS_CHANGED_EVENT, handleUpdate);
      window.removeEventListener("storage", handleUpdate);
    };
  }, [syncRemote]);

  const markAsRead = async (id: string) => {
    const updated = notifications.map((n) => (n.id === id ? { ...n, read: true } : n));
    setNotifications(updated);
    saveStoredNotifications(updated);

    try {
      await fetch(`${API_URL}/notifications/${id}/read`, { method: "PUT" });
    } catch (e) {
      // offline or silent
    }
  };

  const markAllAsRead = async () => {
    const updated = notifications.map((n) => ({ ...n, read: true }));
    setNotifications(updated);
    saveStoredNotifications(updated);

    const user = getAuthUser();
    if (user?.email) {
      try {
        await fetch(`${API_URL}/notifications/read-all`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: user.email }),
        });
      } catch (e) {
        // offline or silent
      }
    }
  };

  const deleteNotification = async (id: string) => {
    const updated = notifications.filter((n) => n.id !== id);
    setNotifications(updated);
    saveStoredNotifications(updated);

    try {
      await fetch(`${API_URL}/notifications/${id}`, { method: "DELETE" });
    } catch (e) {
      // offline or silent
    }
  };

  const clearAll = async () => {
    setNotifications([]);
    saveStoredNotifications([]);

    const user = getAuthUser();
    if (user?.email) {
      try {
        await fetch(`${API_URL}/notifications?email=${encodeURIComponent(user.email)}`, {
          method: "DELETE",
        });
      } catch (e) {
        // offline or silent
      }
    }
  };

  const unreadCount = notifications.filter((n) => !n.read).length;

  return {
    notifications,
    unreadCount,
    loading,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    clearAll,
    refreshNotifications: syncRemote,
  };
}
