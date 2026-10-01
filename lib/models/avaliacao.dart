import 'package:cloud_firestore/cloud_firestore.dart';

/// Prefixo das fotos aceitas: o bucket de avatares do projeto no Supabase.
///
/// Uma foto fora daqui não é carregada (cai na inicial do nome): com URL livre,
/// uma avaliação podia apontar para um servidor de terceiros e registrar o IP
/// de quem abrisse a lista. As Firestore Rules recusam a gravação; este filtro
/// cobre o que já estava gravado antes delas.
const prefixoAvatares =
    'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/avatars/';

/// A foto, se vier do bucket de avatares; senão, vazia.
String fotoConfiavel(Object? url) =>
    url is String && url.startsWith(prefixoAvatares) && url.length <= 300
    ? url
    : '';

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

  /// Converte o documento, ou devolve `null` se ele não tiver o formato certo.
  ///
  /// Até 01/10/2026 isto fazia `d['nota'] as num?`: uma avaliação editada para
  /// `nota: "5"` estourava o cast e derrubava a lista inteira. Agora o
  /// documento ruim é pulado e os outros aparecem.
  static Avaliacao? doFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    // Escrita pendente chega sem `criadoEm` (a hora é do servidor); cai no
    // "agora" logo abaixo.
    final d = doc.data();
    if (d == null) return null;

    final nota = d['nota'];
    if (nota is! int || nota < 1 || nota > 5) return null;
    final uid = d['uid'];
    final comentario = d['comentario'];
    if (uid is! String || comentario is! String) return null;

    final nome = d['nome'];
    final bruto = d['criadoEm'];
    return Avaliacao(
      id: doc.id,
      uid: uid,
      nome: nome is String && nome.trim().isNotEmpty ? nome : 'Usuário',
      fotoUrl: fotoConfiavel(d['photoURL']),
      nota: nota,
      comentario: comentario,
      criadoEm: bruto is Timestamp ? bruto.toDate() : DateTime.now(),
    );
  }

  /// "há 3 dias", "agora mesmo" — porte do `timeAgo()` do Reviews.jsx.
  String get tempoRelativo => tempoRelativoDesde(criadoEm, DateTime.now());
}

/// Separado de `Avaliacao` para dar para testar com um "agora" fixo.
String tempoRelativoDesde(DateTime quando, DateTime agora) {
  final s = agora.difference(quando).inSeconds;
  if (s < 60) return 'agora mesmo';
  final min = s ~/ 60;
  if (min < 60) return 'há $min min';
  final h = min ~/ 60;
  if (h < 24) return 'há ${h}h';
  final d = h ~/ 24;
  if (d < 7) return 'há $d dia${d > 1 ? 's' : ''}';
  final sem = d ~/ 7;
  // Entre 28 e 29 dias, `d ~/ 30` dava zero e aparecia "há 0 mês".
  if (sem < 4 || d < 30) return 'há $sem semana${sem > 1 ? 's' : ''}';
  final m = d ~/ 30;
  if (m < 12) return 'há $m ${m > 1 ? 'meses' : 'mês'}';
  final a = m ~/ 12;
  return 'há $a ano${a > 1 ? 's' : ''}';
}
