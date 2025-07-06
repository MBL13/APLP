import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'detalhe_doador_screen.dart';

class BuscarDoadoresScreen extends StatefulWidget {
  const BuscarDoadoresScreen({super.key});

  @override
  State<BuscarDoadoresScreen> createState() => _BuscarDoadoresScreenState();
}

class _BuscarDoadoresScreenState extends State<BuscarDoadoresScreen> {
  final geo = GeoFlutterFire();
  final _firestore = FirebaseFirestore.instance;
  String _tipoSelecionado = 'A+';
  List<String> tipos = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  List<Map<String, dynamic>> resultados = [];
  bool _isLoading = false;

  Future<GeoFirePoint?> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return null;
      }
    }

    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return geo.point(latitude: pos.latitude, longitude: pos.longitude);
  }

  void _buscarDoadores() async {
    setState(() => _isLoading = true);
    final userLocation = await _getUserLocation();
    if (userLocation == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permita o acesso à localização para buscar doadores.')),
      );
      return;
    }

    const double raioKm = 20.0;

    final collectionRef = _firestore.collection('doadores');
    final stream = geo
        .collection(collectionRef: collectionRef)
        .within(center: userLocation, radius: raioKm, field: 'position', strictMode: true);

    stream.listen((List<DocumentSnapshot> documentList) {
      final filtrados = documentList.where((doc) =>
        doc['tipoSanguineo'] == _tipoSelecionado && doc['disponivel'] == true
      );

      final dados = filtrados.map((doc) {
        final pos = doc['position']['geopoint'];
        final double distance = _calcularDistancia(
          userLocation.latitude, userLocation.longitude,
          pos.latitude, pos.longitude,
        );
        return {
          'uid': doc.id,
          'nome': doc['nome'],
          'tipo': doc['tipoSanguineo'],
          'distancia': distance.toStringAsFixed(2),
          'fcmToken': (doc.data() as Map<String, dynamic>).containsKey('fcmToken') ? doc['fcmToken'] : null,
        };
      }).toList();

      setState(() {
        resultados = dados;
        _isLoading = false;
      });
    });
  }

  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p)/2 +
      cos(lat1 * p) * cos(lat2 * p) *
      (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Doadores')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _tipoSelecionado,
              items: tipos.map((tipo) => DropdownMenuItem(
                value: tipo,
                child: Text(tipo),
              )).toList(),
              onChanged: (val) => setState(() => _tipoSelecionado = val!),
            ),
            ElevatedButton(onPressed: _buscarDoadores, child: const Text("Buscar")),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: resultados.length,
                itemBuilder: (context, index) {
                  final item = resultados[index];
                  return ListTile(
                    title: Text(item['nome']),
                    subtitle: Text('Tipo: ${item['tipo']} • ${item['distancia']} km'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetalheDoadorScreen(doador: item),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}