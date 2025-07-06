import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomeController = TextEditingController();
  final _tipoSanguineoController = TextEditingController();

  String _tipoConta = 'doador';

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Localização
  Future<GeoPoint?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return GeoPoint(pos.latitude, pos.longitude);
  }

  void _register() async {
    try {
      // Criação do usuário no Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // Captura localização
      GeoPoint? location = await _getLocation();
      final geo = GeoFlutterFire();
      final point = geo.point(latitude: location!.latitude, longitude: location.longitude);

      // Token de notificação
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Salvando no Firestore
      await _firestore.collection('doadores').doc(uid).set({
        'uid': uid,
        'email': _emailController.text.trim(),
        'nome': _nomeController.text.trim(),
        'tipoSanguineo': _tipoSanguineoController.text.trim(),
        'disponivel': true,
        'position': point.data,
        'fcmToken': fcmToken,
        'tipo': _tipoConta,
      });

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar conta: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _tipoSanguineoController,
              decoration: const InputDecoration(labelText: 'Tipo Sanguíneo'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Tipo de conta:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _tipoConta,
                  items: const [
                    DropdownMenuItem(value: 'doador', child: Text('Doador')),
                    DropdownMenuItem(value: 'centro', child: Text('Centro de Saúde')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoConta = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text("Criar Conta"),
            ),
          ],
        ),
      ),
    );
  }
}
