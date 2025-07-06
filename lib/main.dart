import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; 

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/buscar_doadores_screen.dart';
import 'screens/solicitacoes_screen.dart';
import 'screens/admin_screen.dart';


import 'services/local_notifications.dart';
// ignore: unused_import
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Mensagem em background: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initializeLocalNotifications();


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.notification != null) {
    showLocalNotification(message);
  }
  });


    return MaterialApp(
      title: 'Doadores de Sangue',
      theme: ThemeData(primarySwatch: Colors.red),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/buscar': (context) => const BuscarDoadoresScreen(),
        '/solicitacoes': (context) => const SolicitacoesScreen(),
        '/admin': (context) => const AdminScreen(),
        

      },
    );
  }
}
