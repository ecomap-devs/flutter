import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FileOptions;

/// Cadastro e login por e-mail/senha, com avatar no Supabase Storage.
///
/// Mesmo fluxo do AuthModal.jsx: cria no Firebase Auth, sobe a foto no bucket
/// `avatars` do Supabase, grava o perfil em `usuarios/{uid}`.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get mudancasDeAutenticacao => _auth.authStateChanges();
  User? get usuarioAtual => _auth.currentUser;

  Future<void> entrar({required String email, required String senha}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
    Uint8List? foto,
    String? extensaoFoto,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
    final user = cred.user!;

    var fotoUrl = '';
    if (foto != null) {
      // Falha ao subir avatar nao pode derrubar o cadastro: a conta ja existe
      // neste ponto, e perde-la por causa da foto seria pior que ficar sem
      // foto. Mesmo criterio do `if (!error)` da versao React.
      try {
        final ext = (extensaoFoto ?? 'png').replaceAll('.', '');
        final caminho = '${user.uid}.$ext';
        final bucket = Supabase.instance.client.storage.from('avatars');
        await bucket.uploadBinary(
          caminho,
          foto,
          fileOptions: const FileOptions(upsert: true),
        );
        fotoUrl = bucket.getPublicUrl(caminho);
      } catch (_) {
        fotoUrl = '';
      }
    }

    await user.updateDisplayName(nome.trim());
    if (fotoUrl.isNotEmpty) {
      await user.updatePhotoURL(fotoUrl);
    }
    await user.reload();

    // O e-mail NAO entra aqui. Ele ja vive no Firebase Auth, que e o lugar
    // dele, e gravar uma copia em documento de leitura aberta tornava dado
    // pessoal publico sem que nada no app precisasse disso (LGPD).
    await _db.collection('usuarios').doc(user.uid).set({
      'nome': nome.trim(),
      'photoURL': fotoUrl,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sair() => _auth.signOut();

  /// Traduz o codigo do Firebase para a mensagem que o usuario le.
  /// Porte do mapa `msgs` do AuthModal.jsx.
  static String mensagemDeErro(Object erro) {
    if (erro is! FirebaseAuthException) {
      return 'Algo deu errado. Tente de novo.';
    }
    return switch (erro.code) {
      'email-already-in-use' => 'Este email já está em uso.',
      'invalid-email' => 'Email inválido.',
      'weak-password' => 'Senha deve ter ao menos 6 caracteres.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email ou senha incorretos.',
      'network-request-failed' => 'Sem conexão. Verifique sua internet.',
      'too-many-requests' => 'Muitas tentativas. Aguarde um momento.',
      _ => erro.message ?? 'Algo deu errado. Tente de novo.',
    };
  }
}
