importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAYcJD2bB-2M8Hsk8DgL_MswLbvoPouRBU",
  authDomain: "vexa-c0fc4.firebaseapp.com",
  projectId: "vexa-c0fc4",
  storageBucket: "vexa-c0fc4.firebasestorage.app",
  messagingSenderId: "141733607007",
  appId: "1:141733607007:web:75805444471b582a3e0dea"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || 'VEXA Style Hub';
  const notificationOptions = {
    body: payload.notification?.body || 'New updates available!',
    icon: '/vexa_logo.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
