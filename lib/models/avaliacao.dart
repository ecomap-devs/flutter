import 'package:cloud_firestore/cloud_firestore.dart';

/// Avaliacao do site publicada por um usuario logado.
class Avaliacao {
  const Avaliacao({
    required this.id,
    required this.uid,
    required this.nome,
    required this.fotoUrl,
    required this.nota,
    required this.comentario,
    required this.criadoEm,
  });

  final String id;
  final String uid;
  final String nome;
  final String fotoUrl;
  final int nota;
  final String comentario;
  final DateTime criadoEm;

  factory Avaliacao.doFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final bruto = d['criadoEm'];
    return Avaliacao(
      id: doc.id,
      uid: (d['uid'] ?? '').toString(),
      nome: (d['nome'] ?? 'Usuário').toString(),
      fotoUrl: (d['photoURL'] ?? '').toString(),
      nota: (d['nota'] as num?)?.toInt() ?? 0,
      comentario: (d['comentario'] ?? '').toString(),
      criadoEm: bruto is Timestamp ? bruto.toDate() : DateTime.now(),
    );
  }

  /// "há 3 dias", "agora mesmo" — porte do `timeAgo()` do Reviews.jsx.
  String get tempoRelativo {
    final s = DateTime.now().difference(criadoEm).inSeconds;
    if (s < 60) return 'agora mesmo';
    final min = s ~/ 60;
    if (min < 60) return 'há $min min';
    final h = min ~/ 60;
    if (h < 24) return 'há ${h}h';
    final d = h ~/ 24;
    if (d < 7) return 'há $d dia${d > 1 ? 's' : ''}';
    final sem = d ~/ 7;
    if (sem < 4) return 'há $sem semana${sem > 1 ? 's' : ''}';
    final m = d ~/ 30;
    if (m < 12) return 'há $m ${m > 1 ? 'meses' : 'mês'}';
    final a = m ~/ 12;
    return 'há $a ano${a > 1 ? 's' : ''}';
  }
}
