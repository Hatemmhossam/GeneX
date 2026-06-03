importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAIIJFg2DPbE6LaQiJ5GUpcsbNEwpakGuw",
  authDomain: "genex-aa039.firebaseapp.com",
  projectId: "genex-aa039",
  storageBucket: "genex-aa039.firebasestorage.app",
  messagingSenderId: "Y614852656255",
  appId: "1:614852656255:web:9b4ee4fb0c39a5edfed34a",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);

  const notificationTitle = payload.notification?.title || "GeneX";
  const notificationOptions = {
    body: payload.notification?.body || "You have a new notification.",
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});