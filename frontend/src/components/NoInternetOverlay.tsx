import React, { useState, useEffect } from "react";
import { WifiOff, RefreshCw, CheckCircle2, AlertCircle } from "lucide-react";

export const NoInternetOverlay: React.FC = () => {
  const [isOffline, setIsOffline] = useState(false);
  const [isChecking, setIsChecking] = useState(false);
  const [toastMessage, setToastMessage] = useState<{ text: string; type: "success" | "error" } | null>(null);

  useEffect(() => {
    const handleOffline = () => setIsOffline(true);
    const handleOnline = () => {
      setIsOffline(false);
      showToast("Internet connection restored!", "success");
    };

    if (typeof window !== "undefined") {
      setIsOffline(!navigator.onLine);
      window.addEventListener("offline", handleOffline);
      window.addEventListener("online", handleOnline);
    }

    return () => {
      if (typeof window !== "undefined") {
        window.removeEventListener("offline", handleOffline);
        window.removeEventListener("online", handleOnline);
      }
    };
  }, []);

  const showToast = (text: string, type: "success" | "error") => {
    setToastMessage({ text, type });
    setTimeout(() => setToastMessage(null), 3000);
  };

  const checkConnection = async () => {
    setIsChecking(true);
    await new Promise((resolve) => setTimeout(resolve, 1000));

    if (navigator.onLine) {
      setIsOffline(false);
      setIsChecking(false);
      showToast("Internet connection restored!", "success");
    } else {
      setIsChecking(false);
      showToast("Still offline. Please check your network connection.", "error");
    }
  };

  if (!isOffline && !toastMessage) return null;

  return (
    <>
      {/* Toast Notification when online status changes */}
      {toastMessage && (
        <div className="fixed top-5 left-1/2 -translate-x-1/2 z-100 flex items-center gap-2.5 px-4 py-2.5 rounded-full bg-slate-900 text-white text-xs font-semibold shadow-2xl animate-in fade-in slide-in-from-top duration-300">
          {toastMessage.type === "success" ? (
            <CheckCircle2 className="size-4 text-emerald-400 shrink-0" />
          ) : (
            <AlertCircle className="size-4 text-rose-400 shrink-0" />
          )}
          <span>{toastMessage.text}</span>
        </div>
      )}

      {/* Full No Internet Modal Screen when Offline */}
      {isOffline && (
        <div className="fixed inset-0 z-99 flex items-center justify-center bg-white/95 backdrop-blur-md p-6 animate-in fade-in duration-200">
          <div className="w-full max-w-sm text-center space-y-6">
            {/* Animated Pulsing Icon Badge */}
            <div className="relative mx-auto size-28 rounded-full bg-slate-100 border-2 border-slate-200 flex items-center justify-center shadow-lg">
              <div className="size-20 rounded-full bg-rose-50 flex items-center justify-center">
                <WifiOff className="size-10 text-rose-500 animate-pulse" />
              </div>
            </div>

            {/* Title & Description */}
            <div className="space-y-2">
              <h2 className="text-2xl font-bold tracking-tight text-slate-900">
                No Internet Connection
              </h2>
              <p className="text-xs text-slate-500 leading-relaxed max-w-xs mx-auto">
                Your device is currently offline. Please check your Wi-Fi or mobile network settings and try again.
              </p>
            </div>

            {/* Try Again Action Button */}
            <button
              onClick={checkConnection}
              disabled={isChecking}
              className="w-full py-3.5 px-6 rounded-2xl bg-slate-900 hover:bg-slate-800 active:scale-98 text-white text-xs font-bold uppercase tracking-wider transition-all flex items-center justify-center gap-2.5 shadow-md cursor-pointer disabled:opacity-60"
            >
              <RefreshCw className={`size-4 ${isChecking ? "animate-spin" : ""}`} />
              <span>{isChecking ? "Checking Connection..." : "Try Again"}</span>
            </button>
          </div>
        </div>
      )}
    </>
  );
};
