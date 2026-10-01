import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/avaliacao.dart';

/// Os limites das Firestore Rules, repetidos aqui para o formulário avisar
/// antes de o servidor recusar.
const maxComentario = 2000;
const maxNome = 200;

/// Total e média de todas as avaliações, calculados no servidor.
class ResumoAvaliacoes {
  const ResumoAvaliacoes({required this.total, required this.media});

  final int total;
  final double? media;
}

/// Avaliacoes em tempo real — porte do `onSnapshot` do Reviews.jsx.
class ReviewsService {
  ReviewsService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('avaliacoes');

  /// As `limite` avaliações mais recentes.
  ///
  /// Até 01/10/2026 o app assinava a coleção inteira para mostrar seis, e a
  /// média era calculada somando a lista baixada.
  Stream<List<Avaliacao>> observar({required int limite}) => _col
      .orderBy('criadoEm', descending: true)
      .limit(limite)
      .snapshots()
      .map((s) => s.docs.map(Avaliacao.doFirestore).nonNulls.toList());

  /// Total e média de todas, por agregação no servidor: não baixa os
  /// documentos. Agregação não é tempo real, então quem exibe chama de novo
  /// quando a lista muda.
  Future<ResumoAvaliacoes> resumo() async {
    final r = await _col.aggregate(count(), average('nota')).get();
    return ResumoAvaliacoes(total: r.count ?? 0, media: r.getAverage('nota'));
  }

  /// Uma avaliação por pessoa: o id da avaliação é o uid de quem avalia. Se a
  /// pessoa já avaliou — inclusive numa avaliação antiga, de antes dessa
  /// regra —, a existente é atualizada em vez de criar outra.
  Future<void> publicar({
    required User usuario,
    required int nota,
    required String comentario,
  }) async {
    final nomeBruto = (usuario.displayName ?? '').trim();
    final nome = nomeBruto.isEmpty
        ? 'Usuário'
        : nomeBruto.substring(0, nomeBruto.length.clamp(0, maxNome));
    final dados = <String, Object>{
      'nome': nome,
      'photoURL': fotoConfiavel(usuario.photoURL),
      'nota': nota,
      'comentario': comentario.trim(),
    };

    final existente = await _col
        .where('uid', isEqualTo: usuario.uid)
        .limit(1)
        .get();
    if (existente.docs.isNotEmpty) {
      await existente.docs.first.reference.update({
        ...dados,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      return;
    }
    await _col.doc(usuario.uid).set({
      ...dados,
      'uid': usuario.uid,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }
}
