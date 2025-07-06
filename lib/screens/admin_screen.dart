import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  // Busca apenas doadores na coleção 'doadores'
  Stream<QuerySnapshot> _getDoadores() {
    return FirebaseFirestore.instance
        .collection('doadores')
        .where('tipo', isEqualTo: 'doador')
        .snapshots();
  }

  // Busca centros na coleção 'centros'
  Stream<QuerySnapshot> _getCentros() {
    return FirebaseFirestore.instance
        .collection('centros')
        .snapshots();
  }

  // Busca solicitações
  Stream<QuerySnapshot> _getSolicitacoes() {
    return FirebaseFirestore.instance
        .collection('solicitacoes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Administrativo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Doadores'),
              Tab(text: 'Centros'),
              Tab(text: 'Solicitações'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Doadores
            StreamBuilder<QuerySnapshot>(
              stream: _getDoadores(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(doc['nome'] ?? 'Sem nome'),
                      subtitle: Text(doc['email'] ?? ''),
                    );
                  },
                );
              },
            ),
            // Tab 2: Centros
            StreamBuilder<QuerySnapshot>(
              stream: _getCentros(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return ListTile(
                      leading: const Icon(Icons.local_hospital),
                      title: Text(doc['nome'] ?? 'Sem nome'),
                      subtitle: Text(doc['email'] ?? ''),
                    );
                  },
                );
              },
            ),
            // Tab 3: Solicitações
            StreamBuilder<QuerySnapshot>(
              stream: _getSolicitacoes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return ListTile(
                      leading: const Icon(Icons.bloodtype),
                      title: Text(doc['doadorNome'] ?? 'Sem nome'),
                      subtitle: Text(
                        'Tipo: ${doc['tipoSanguineo']} • Solicitante: ${doc['solicitante']}',
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}