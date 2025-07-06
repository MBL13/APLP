import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool? disponivel;
  String nome = '';
  String tipo = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    if (user == null) return;

    // Tenta buscar primeiro em doadores
    var doc = await FirebaseFirestore.instance
        .collection('doadores')
        .doc(user!.uid)
        .get();

    // Se não encontrar, tenta em centros
    if (!doc.exists) {
      doc = await FirebaseFirestore.instance
          .collection('centros')
          .doc(user!.uid)
          .get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não encontrado.')),
        );
        return;
      }
    }

    setState(() {
      disponivel = doc.data()?['disponivel'] ?? true;
      nome = doc.data()?['nome'] ?? '';
      tipo = doc.data()?['tipo'] ?? '';
    });
  }

  Future<void> _alternarDisponibilidade() async {
    if (user == null) return;
    if (tipo == 'centro') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas doadores podem alterar disponibilidade.'),
        ),
      );
      return;
    }

    final novoEstado = !(disponivel ?? true);

    await FirebaseFirestore.instance
        .collection('doadores')
        .doc(user!.uid)
        .update({'disponivel': novoEstado});

    setState(() {
      disponivel = novoEstado;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          novoEstado
              ? 'Agora estás disponível para doação'
              : 'Agora estás indisponível',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página Inicial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bem-vindo, $nome', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/buscar'),
              icon: const Icon(Icons.search),
              label: const Text('Buscar Doadores'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/solicitacoes'),
              icon: const Icon(Icons.list_alt),
              label: const Text('Ver Pedidos Enviados'),
            ),
            const SizedBox(height: 12),
            if (tipo != 'centro')
              ElevatedButton.icon(
                onPressed: _alternarDisponibilidade,
                icon: Icon(
                  disponivel == true ? Icons.visibility : Icons.visibility_off,
                ),
                label: Text(
                  disponivel == true
                      ? 'Marcar como Indisponível'
                      : 'Marcar como Disponível',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: disponivel == true
                      ? Colors.green
                      : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
