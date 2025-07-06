import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

void _login() async {
  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final uid = userCredential.user!.uid;

    // Tenta buscar primeiro em doadores
    var doc = await _firestore.collection('doadores').doc(uid).get();

    // Se não encontrar, tenta em centros
    if (!doc.exists) {
      doc = await _firestore.collection('centros').doc(uid).get();
      if (!doc.exists) {
        throw Exception("Usuário não encontrado no Firestore.");
      }
    }

    final tipo = doc['tipo'] ?? 'doador';

    if (tipo == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else if (tipo == 'centro') {
      Navigator.pushReplacementNamed(context, '/home'); // ajuste se tiver rota específica para centro
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } on FirebaseAuthException catch (e) {
    String msg = 'Erro ao fazer login.';
    if (e.code == 'user-not-found') {
      msg = 'Usuário não encontrado.';
    } else if (e.code == 'wrong-password') {
      msg = 'Senha incorreta.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao fazer login: ${e.toString()}')),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entrar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text("Entrar"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text("Criar conta"),
            ),
          ],
        ),
      ),
    );
  }
}
