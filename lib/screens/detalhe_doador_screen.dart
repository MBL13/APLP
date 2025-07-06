import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetalheDoadorScreen extends StatelessWidget {
  final Map<String, dynamic> doador;

  const DetalheDoadorScreen({super.key, required this.doador});

  void _solicitarDoacao(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    try {
      // Buscar dados do doador para pegar o token
      final doadorDoc = await firestore
          .collection('doadores')
          .doc(doador['uid'])
          .get();
      final String? token = doadorDoc['fcmToken'];

      // Criar solicitação no Firestore
      await firestore.collection('solicitacoes').add({
        'doadorId': doador['uid'],
        'doadorNome': doador['nome'],
        'tipoSanguineo': doador['tipo'],
        'solicitante': user?.email ?? 'desconhecido',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Enviar notificação push (RECOMENDAÇÃO: NÃO DEIXE A SERVER KEY NO APP)
      if (token != null) {
        // ATENÇÃO: Nunca exponha sua serverKey em apps de produção!
        // O ideal é enviar a solicitação para um backend seguro que faz o envio da notificação.
        const String serverKey = 'AIzaSyAI2_AVuLoY23kIe1cWgkGIjFJ-3TSumrI';

        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': token,
            'notification': {
              'title': 'Pedido de Doação',
              'body': 'Precisa-se de sangue ${doador['tipo']}!',
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
            },
          }),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pedido enviado e notificação disparada."),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Doador')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nome: ${doador['nome']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Tipo Sanguíneo: ${doador['tipo']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Distância: ${doador['distancia']} km',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bloodtype),
                label: const Text('Solicitar Doação'),
                onPressed: () => _solicitarDoacao(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
