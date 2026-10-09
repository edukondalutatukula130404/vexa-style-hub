import { initializeApp, getApps, getApp } from 'firebase/app';
import { getMessaging, getToken, onMessage, isSupported } from 'firebase/messaging';

export const firebaseConfig = {
  apiKey: "AIzaSyAYcJD2bB-2M8Hsk8DgL_MswLbvoPouRBU",
  authDomain: "vexa-c0fc4.firebaseapp.com",
  projectId: "vexa-c0fc4",
  storageBucket: "vexa-c0fc4.firebasestorage.app",
  messagingSenderId: "141733607007",
  appId: "1:141733607007:web:75805444471b582a3e0dea"
};

// Initialize Firebase App singleton
export const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();

export const requestWebNotificationPermission = async (): Promise<string | null> => {
  try {
    const supported = await isSupported();
    if (!supported) {
      console.warn('Firebase Messaging is not supported in this browser environment.');
      return null;
    }

    if (typeof window === 'undefined' || !('Notification' in window)) {
      console.warn('Notifications not supported in environment.');
      return null;
    }

    const permission = await Notification.requestPermission();
    if (permission === 'granted') {
      const messagingInstance = getMessaging(app);

      // Register service worker if supported
      if ('serviceWorker' in navigator) {
        const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js');
        const token = await getToken(messagingInstance, {
          serviceWorkerRegistration: registration,
        }).catch((err) => {
          console.warn('FCM Token generation warning:', err);
          return null;
        });
        
        if (token) {
          console.log('Web FCM Token generated:', token);
          return token;
        }
      }
    } else {
      console.warn('Notification permission denied by user.');
    }
  } catch (error) {
    console.error('Error requesting notification permission:', error);
  }
  return null;
};

export const onForegroundMessage = async (callback: (payload: any) => void) => {
  try {
    const supported = await isSupported();
    if (!supported) return;
    const messaging = getMessaging(app);
    return onMessage(messaging, (payload) => {
      callback(payload);
    });
  } catch (error) {
    console.error('Error setting up foreground message listener:', error);
  }
};

export const triggerWebTestPushNotification = (
  title = "⚡ VEXA Push Notification",
  body = "Push notifications are working perfectly on your web browser!"
) => {
  if (typeof window === "undefined") return;

  // Synthesize notification chime audio
  try {
    const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
    if (AudioCtx) {
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sine";
      osc.frequency.setValueAtTime(587.33, ctx.currentTime); // D5
      osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.15); // A5
      gain.gain.setValueAtTime(0.35, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.35);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.35);
    }
  } catch (_) {}

  if (!("Notification" in window)) return;

  const notifOptions: NotificationOptions = {
    body,
    icon: "/vexa_logo.png",
    badge: "/vexa_logo.png",
    tag: `vexa-notif-${Date.now()}`,
    requireInteraction: true,
    silent: false,
  };

  const fireNotification = () => {
    try {
      if ("serviceWorker" in navigator) {
        navigator.serviceWorker.getRegistration().then((reg) => {
          if (reg && reg.showNotification) {
            reg.showNotification(title, notifOptions).catch(() => {
              try { new Notification(title, notifOptions); } catch (_) {}
            });
          } else {
            try { new Notification(title, notifOptions); } catch (_) {}
          }
        }).catch(() => {
          try { new Notification(title, notifOptions); } catch (_) {}
        });
      } else {
        try { new Notification(title, notifOptions); } catch (_) {}
      }
    } catch (e) {
      console.warn("Native browser notification warning:", e);
    }
  };

  if (Notification.permission === "granted") {
    fireNotification();
  } else if (Notification.permission !== "denied") {
    try {
      Notification.requestPermission().then((permission) => {
        if (permission === "granted") {
          fireNotification();
        }
      });
    } catch (_) {}
  }
};
