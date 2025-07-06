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
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<GeoPoint?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return null;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return GeoPoint(position.latitude, position.longitude);
  }

  void _register() async {
    // Validação simples dos campos
    if (_nomeController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        (_tipoConta == 'doador' &&
            _tipoSanguineoController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      GeoPoint? location = await _getLocation();
      if (location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permita o acesso à localização para continuar.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final geo = GeoFlutterFire();
      final point = geo.point(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      String collection = _tipoConta == 'centro' ? 'centros' : 'doadores';

      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'email': _emailController.text.trim(),
        'nome': _nomeController.text.trim(),
        'disponivel': true,
        'position': point.data,
        'fcmToken': fcmToken,
        'tipo': _tipoConta,
      };

      if (_tipoConta == 'doador') {
        userData['tipoSanguineo'] = _tipoSanguineoController.text.trim();
      }

      await _firestore
          .collection(collection)
          .doc(userCredential.user!.uid)
          .set(userData);

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro ao criar conta.';
      if (e.code == 'email-already-in-use') {
        msg = 'Este e-mail já está em uso.';
      } else if (e.code == 'weak-password') {
        msg = 'A senha deve ter pelo menos 6 caracteres.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar conta: $e')));
    } finally {
      setState(() => _isLoading = false);
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
            if (_tipoConta == 'doador')
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
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Tipo de conta:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _tipoConta,
                  items: [
                    DropdownMenuItem(value: 'doador', child: Text('Doador')),
                    DropdownMenuItem(
                      value: 'centro',
                      child: Text('Centro de Saúde'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _tipoConta = val!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Criar Conta"),
            ),
          ],
        ),
      ),
    );
  }
}
