import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, FileOptions;

import '../models/avaliacao.dart' show fotoConfiavel;
import 'reviews_service.dart' show maxNome;

/// O mesmo limite do bucket `avatars` no Supabase.
const maxAvatarBytes = 1024 * 1024;

/// A conta foi criada, mas o perfil (foto, nome) não terminou de salvar.
class CadastroIncompleto implements Exception {
  const CadastroIncompleto(this.usuario, this.causa);

  final User usuario;
  final Object causa;
}

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
    try {
      await concluirPerfil(
        cred.user!,
        nome: nome,
        foto: foto,
        extensaoFoto: extensaoFoto,
      );
    } catch (erro) {
      // A conta JA existe neste ponto. Antes, a falha aqui aparecia como falha
      // do cadastro inteiro, e tentar de novo dava "email já está em uso".
      throw CadastroIncompleto(cred.user!, erro);
    }
  }

  /// A parte do cadastro que vem depois de criar a conta: avatar, nome e
  /// perfil. Pode ser chamada de novo se falhar no meio — cada passo confere o
  /// que já foi feito.
  Future<void> concluirPerfil(
    User user, {
    required String nome,
    Uint8List? foto,
    String? extensaoFoto,
  }) async {
    var fotoUrl = fotoConfiavel(user.photoURL);
    if (foto != null && fotoUrl.isEmpty) {
      fotoUrl = await _enviarAvatar(user.uid, foto, extensaoFoto);
    }

    final nomeLimpo = nome.trim();
    final nomeFinal = nomeLimpo.substring(
      0,
      nomeLimpo.length.clamp(0, maxNome),
    );
    await user.updateDisplayName(nomeFinal);
    if (fotoUrl.isNotEmpty) {
      await user.updatePhotoURL(fotoUrl);
    }
    await user.reload();

    // O e-mail NAO entra aqui. Ele ja vive no Firebase Auth, que e o lugar
    // dele, e gravar uma copia em documento de leitura aberta tornava dado
    // pessoal publico sem que nada no app precisasse disso (LGPD).
    final perfil = _db.collection('usuarios').doc(user.uid);
    if ((await perfil.get()).exists) {
      await perfil.update({'nome': nomeFinal, 'photoURL': fotoUrl});
    } else {
      await perfil.set({
        'nome': nomeFinal,
        'photoURL': fotoUrl,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Sobe o avatar e devolve a URL pública, ou '' se falhar.
  ///
  /// Falha ao subir avatar nao pode derrubar o cadastro: perder a conta por
  /// causa da foto seria pior que ficar sem foto. Mesmo criterio do
  /// `if (!error)` da versao React.
  ///
  /// O nome do arquivo e `<uid>/<aleatorio>.<ext>`: imprevisivel, e o bucket
  /// so aceita criar arquivo novo (sem sobrescrever) de imagem de ate 1 MB.
  Future<String> _enviarAvatar(
    String uid,
    Uint8List foto,
    String? extensao,
  ) async {
    if (foto.lengthInBytes > maxAvatarBytes) return '';
    final ext = switch ((extensao ?? '').toLowerCase()) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpg',
    };
    final tipo = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
    final aleatorio = Random.secure();
    final nome = List.generate(
      16,
      (_) => aleatorio.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final caminho = '$uid/$nome.$ext';
    try {
      final bucket = Supabase.instance.client.storage.from('avatars');
      await bucket.uploadBinary(
        caminho,
        foto,
        fileOptions: FileOptions(contentType: tipo),
      );
      return fotoConfiavel(bucket.getPublicUrl(caminho));
    } catch (_) {
      return '';
    }
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
