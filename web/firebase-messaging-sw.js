// Service worker exigido por Firebase Cloud Messaging para recibir push en
// segundo plano en la web (ver lib/services/push_notification_service.dart).
// Sin este archivo, getToken() en web fallaba en silencio -- el registro de
// token nunca llegaba a completarse para la variante web de la app.
//
// Mismos valores que lib/firebase_options.dart (FirebaseOptions.web): son
// identificadores públicos del proyecto (instriq-53015), no secretos.
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDi3Rr5yn45e76fPx6aRucIbjgM4mnaICY',
  appId: '1:234791930437:web:aded041e856ee32ac0f12c',
  messagingSenderId: '234791930437',
  projectId: 'instriq-53015',
  authDomain: 'instriq-53015.firebaseapp.com',
  storageBucket: 'instriq-53015.firebasestorage.app',
});

firebase.messaging();
