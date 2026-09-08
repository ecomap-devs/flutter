import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/avaliacao.dart';

/// Avaliacoes em tempo real — porte do `onSnapshot` do Reviews.jsx.
class ReviewsService {
  ReviewsService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('avaliacoes');

  Stream<List<Avaliacao>> observar() => _col
      .orderBy('criadoEm', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Avaliacao.doFirestore).toList());

  Future<void> publicar({
    required User usuario,
    required int nota,
    required String comentario,
  }) async {
    await _col.add({
      'uid': usuario.uid,
      'nome': usuario.displayName ?? 'Usuário',
      'photoURL': usuario.photoURL ?? '',
      'nota': nota,
      'comentario': comentario.trim(),
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  static double? media(List<Avaliacao> lista) {
    if (lista.isEmpty) return null;
    final soma = lista.fold<int>(0, (s, a) => s + a.nota);
    return soma / lista.length;
  }
}
