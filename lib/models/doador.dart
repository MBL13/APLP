
import 'package:cloud_firestore/cloud_firestore.dart';

class Doador {
  final String uid;
  final String nome;
  final String tipoSanguineo;
  final GeoPoint localizacao;
  final bool disponivel;

  Doador({
    required this.uid,
    required this.nome,
    required this.tipoSanguineo,
    required this.localizacao,
    required this.disponivel,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nome': nome,
        'tipoSanguineo': tipoSanguineo,
        'localizacao': localizacao,
        'disponivel': disponivel,
      };

  factory Doador.fromMap(Map<String, dynamic> map) => Doador(
        uid: map['uid'],
        nome: map['nome'],
        tipoSanguineo: map['tipoSanguineo'],
        localizacao: map['localizacao'],
        disponivel: map['disponivel'],
      );
}
