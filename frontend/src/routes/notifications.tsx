import { Link, useNavigate } from "react-router-dom";
import {
  Bell,
  CheckCheck,
  Trash2,
  Package,
  Truck,
  Check,
  Award,
  ChevronRight,
  ArrowRight,
  X,
} from "lucide-react";
import { useNotifications, NotificationItem } from "@/lib/notifications";

function formatRelativeTime(dateString: string): string {
  try {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / (1000 * 60));
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffMins < 5) return "Just now";
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays === 1) return "Yesterday";
    return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
  } catch (e) {
    return "Just now";
  }
}

export function NotificationsPage() {
  const navigate = useNavigate();
  const {
    notifications,
    unreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    clearAll,
  } = useNotifications();

  const hasUnread = unreadCount > 0;
  const hasNotifications = notifications.length > 0;

  // Icon and color mapping for notification types
  const getNotificationIconConfig = (notif: NotificationItem) => {
    const title = notif.title.toLowerCase();
    const type = (notif.type || "").toLowerCase();

    // 1. Order Confirmed 🎉
    if (title.includes("confirmed") || type.includes("confirmed")) {
      return {
        bg: "bg-[#FEF3C7] dark:bg-amber-950/30",
        border: "border-[#FDE68A] dark:border-amber-800/40",
        icon: <Award className="size-5 text-[#B8860B]" />,
      };
    }

    // 2. Order Delivered ✅
    if (title.includes("delivered") || type.includes("delivered")) {
      return {
        bg: "bg-[#D1FAE5] dark:bg-emerald-950/30",
        border: "border-[#A7F3D0] dark:border-emerald-800/40",
        icon: <Check className="size-5 stroke-[2.8] text-[#059669]" />,
      };
    }

    // 3. Out for Delivery 🚚 or Order Shipped 📦
    if (
      title.includes("delivery") ||
      title.includes("shipped") ||
      type.includes("shipped") ||
      type.includes("delivery")
    ) {
      return {
        bg: "bg-[#DBEAFE] dark:bg-blue-950/30",
        border: "border-[#BFDBFE] dark:border-blue-800/40",
        icon: <Truck className="size-5 text-[#2563EB]" />,
      };
    }

    // 4. Order Placed 📦 or Order Processing
    if (
      title.includes("placed") ||
      title.includes("processing") ||
      type.includes("placed") ||
      type.includes("processing")
    ) {
      return {
        bg: "bg-[#FEF3C7] dark:bg-amber-950/30",
        border: "border-[#FDE68A] dark:border-amber-800/40",
        icon: <Package className="size-5 text-[#D97706]" />,
      };
    }

    // Default VEXA Notification
    return {
      bg: "bg-[#FEF3C7] dark:bg-amber-950/30",
      border: "border-[#FDE68A] dark:border-amber-800/40",
      icon: <Bell className="size-5 text-[#B8860B]" />,
    };
  };

  const handleCardTap = (notif: NotificationItem) => {
    if (!notif.read) {
      markAsRead(notif.id);
    }
    if (notif.actionUrl) {
      navigate(notif.actionUrl);
    } else if (notif.orderId) {
      navigate("/dashboard?tab=orders");
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF8F5] text-foreground font-sans pt-24 sm:pt-28 pb-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto w-full">
        {/* Breadcrumb Navigation */}
        <div className="flex items-center gap-2 text-xs font-semibold text-muted-foreground uppercase tracking-widest mb-4">
          <Link to="/" className="hover:text-gold transition-colors">
            Home
          </Link>
          <ChevronRight className="size-3 text-muted-foreground/60" />
          <span className="text-gold font-bold">Notifications</span>
        </div>

        {/* Page Header Banner */}
        <div className="bg-white rounded-2xl border border-[#EADBBE]/80 shadow-[0_4px_20px_rgba(0,0,0,0.03)] p-5 sm:p-7 mb-6">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-3">
                <div className="flex size-10 items-center justify-center rounded-xl bg-[#FAF8F5] border border-[#EADBBE] text-gold shadow-xs">
                  <Bell className="size-5 text-[#965B0A]" />
                </div>
                <div>
                  <h1 className="font-display text-2xl sm:text-3xl font-extrabold tracking-wide text-[#1E1E1E] uppercase">
                    NOTIFICATIONS
                  </h1>
                  <p className="text-xs sm:text-sm text-muted-foreground mt-0.5">
                    Stay updated on your orders, luxury drops, and system activity.
                  </p>
                </div>
              </div>
            </div>

            {/* Action Bar */}
            <div className="flex items-center gap-3 self-end sm:self-center border-t sm:border-t-0 pt-3 sm:pt-0 w-full sm:w-auto justify-between sm:justify-end">
              <span className="text-xs sm:text-[13px] font-bold text-muted-foreground">
                {notifications.length} {notifications.length === 1 ? "Notification" : "Notifications"}
              </span>

              <div className="flex items-center gap-2">
                {hasUnread && (
                  <button
                    type="button"
                    onClick={() => markAllAsRead()}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-[#965B0A]/40 bg-[#FAF8F5] px-3 py-1.5 text-xs font-bold text-[#965B0A] hover:bg-[#965B0A] hover:text-white transition-all shadow-xs cursor-pointer active:scale-95"
                  >
                    <CheckCheck className="size-3.5" />
                    <span>Read All</span>
                  </button>
                )}

                {hasNotifications && (
                  <button
                    type="button"
                    onClick={() => {
                      if (window.confirm("Are you sure you want to delete all notifications?")) {
                        clearAll();
                      }
                    }}
                    className="inline-flex items-center gap-1.5 rounded-lg border border-destructive/30 bg-destructive/5 px-3 py-1.5 text-xs font-bold text-destructive hover:bg-destructive hover:text-destructive-foreground transition-all shadow-xs cursor-pointer active:scale-95"
                  >
                    <Trash2 className="size-3.5" />
                    <span>Delete All</span>
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Notifications List */}
        {!hasNotifications ? (
          /* Empty State */
          <div className="bg-white rounded-2xl border border-[#EADBBE]/80 shadow-[0_4px_20px_rgba(0,0,0,0.03)] py-20 px-6 flex flex-col items-center justify-center text-center">
            <div className="flex size-20 items-center justify-center rounded-full bg-[#FAF8F5] border border-[#EADBBE] mb-4 text-[#965B0A]">
              <Bell className="size-10 stroke-[1.5]" />
            </div>
            <h3 className="font-display text-xl font-bold text-[#1E1E1E] uppercase tracking-wide">
              No Notifications Yet
            </h3>
            <p className="mt-1.5 text-xs sm:text-sm text-muted-foreground max-w-sm leading-relaxed">
              You are completely caught up! We will notify you here when your orders update or new luxury drops arrive.
            </p>
            <Link
              to="/products"
              className="mt-6 inline-flex items-center gap-2 rounded-md bg-[#965B0A] hover:bg-[#834E06] px-6 py-2.5 text-xs font-bold uppercase tracking-wider text-white shadow-sm transition-all"
            >
              <span>Explore Products</span>
              <ArrowRight className="size-4" />
            </Link>
          </div>
        ) : (
          <div className="space-y-3 sm:space-y-3.5">
            {notifications.map((notif) => {
              const isUnread = !notif.read;
              const config = getNotificationIconConfig(notif);

              return (
                <div
                  key={notif.id}
                  onClick={() => handleCardTap(notif)}
                  className={`group relative rounded-2xl p-4 sm:p-5 transition-all duration-200 cursor-pointer active:scale-[0.995] ${
                    isUnread
                      ? "bg-white border-[1.5px] border-[#965B0A]/70 shadow-[0_6px_20px_rgba(150,91,10,0.08)]"
                      : "bg-white border border-[#E2E8F0] hover:border-[#965B0A]/50 shadow-xs"
                  }`}
                >
                  <div className="flex items-start gap-3.5 sm:gap-4">
                    {/* Left Icon Badge */}
                    <div className="relative shrink-0 mt-0.5">
                      <div
                        className={`flex size-11 sm:size-12 items-center justify-center rounded-2xl border ${config.border} ${config.bg} shadow-xs transition-transform group-hover:scale-105`}
                      >
                        {config.icon}
                      </div>

                      {/* Golden unread dot */}
                      {isUnread && (
                        <span className="absolute -top-1 -right-1 flex size-3 items-center justify-center">
                          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#965B0A] opacity-60" />
                          <span className="relative inline-flex rounded-full size-2.5 bg-[#965B0A] border-2 border-white" />
                        </span>
                      )}
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start justify-between gap-3">
                        <div className="flex items-center gap-2">
                          <h3
                            className={`text-sm sm:text-[15px] leading-snug text-[#1E1E1E] ${
                              isUnread ? "font-extrabold" : "font-bold"
                            }`}
                          >
                            {notif.title}
                          </h3>
                          {isUnread && (
                            <span className="rounded-full bg-[#FAF8F5] border border-[#965B0A]/30 px-2 py-0.5 text-[9.5px] font-black text-[#965B0A] uppercase tracking-wider">
                              New
                            </span>
                          )}
                        </div>

                        <div className="flex items-center gap-2 shrink-0">
                          <span
                            className={`text-[11px] sm:text-xs font-semibold ${
                              isUnread ? "text-[#965B0A]" : "text-muted-foreground"
                            }`}
                          >
                            {formatRelativeTime(notif.createdAt)}
                          </span>

                          {/* Quick Delete Single Notification Button */}
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              deleteNotification(notif.id);
                            }}
                            className="opacity-0 group-hover:opacity-100 transition-opacity p-1 text-muted-foreground hover:text-destructive rounded-full hover:bg-slate-100"
                            title="Delete notification"
                            aria-label="Delete notification"
                          >
                            <X className="size-3.5" />
                          </button>
                        </div>
                      </div>

                      <p className="mt-1.5 text-xs sm:text-[13px] text-muted-foreground leading-relaxed">
                        {notif.message || notif.body}
                      </p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

export default NotificationsPage;
