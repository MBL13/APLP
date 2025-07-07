// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAL8yt7AcZX-HOw4nAaJ9QB7dNTgnHZtYk",
  authDomain: "doadores-app.firebaseapp.com",
  projectId: "doadores-app",
  messagingSenderId: "888058212243",
  appId: "1:888058212243:web:72d6ba30da878787658266"
});

const messaging = firebase.messaging();
