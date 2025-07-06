
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SolicitacoesScreen extends StatelessWidget {
  const SolicitacoesScreen({super.key});

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return 'Data desconhecida';
    final data = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos de Doação Enviados')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitacoes')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum pedido encontrado.'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return ListTile(
                leading: const Icon(Icons.bloodtype, color: Colors.red),
                title: Text(doc['doadorNome'] ?? 'Sem nome'),
                subtitle: Text(
                  'Tipo: ${doc['tipoSanguineo']} • Solicitado por: ${doc['solicitante']}\n${_formatarData(doc['timestamp'])}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
