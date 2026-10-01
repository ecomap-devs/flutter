import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FunctionException, Supabase, SupabaseClient;

import '../models/identificacao.dart';

/// Falha com mensagem ja pronta para a tela.
class IdentificacaoException implements Exception {
  const IdentificacaoException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Manda a foto para a Edge Function `identificar-animal`, que consulta o
/// Google Cloud Vision.
///
/// O app nunca fala com o Vision direto: a chave e de API paga e so vive no
/// servidor. Aqui vai apenas o ID token do Firebase, que a funcao confere.
class IdentificacaoService {
  IdentificacaoService({FirebaseAuth? auth, SupabaseClient? supabase})
    : _authInjetado = auth,
      _supabaseInjetado = supabase;

  // Resolvidos so na hora do uso, para a tela poder ser montada (e testada)
  // sem Firebase e Supabase inicializados.
  final FirebaseAuth? _authInjetado;
  final SupabaseClient? _supabaseInjetado;

  FirebaseAuth get _auth => _authInjetado ?? FirebaseAuth.instance;
  SupabaseClient get _supabase => _supabaseInjetado ?? Supabase.instance.client;

  Future<Identificacao> identificar(Uint8List foto) async {
    final usuario = _auth.currentUser;
    if (usuario == null) {
      throw const IdentificacaoException(
        'Entre na sua conta para identificar animais.',
      );
    }
    final token = await usuario.getIdToken();

    final resposta = await _supabase.functions.invoke(
      'identificar-animal',
      body: {'imagem': base64Encode(foto)},
      headers: {'Authorization': 'Bearer $token'},
    );

    final resultado = Identificacao.daVision(resposta.data);
    if (resultado == null) {
      throw const IdentificacaoException(
        'Resposta inesperada do servidor. Tente de novo.',
      );
    }
    return resultado;
  }

  /// Traduz a falha para a mensagem que o usuario le.
  static String mensagemDeErro(Object erro) {
    if (erro is IdentificacaoException) return erro.mensagem;
    if (erro is! FunctionException) {
      return 'Algo deu errado. Verifique sua internet e tente de novo.';
    }
    return switch (erro.status) {
      0 => 'Sem conexão. Verifique sua internet.',
      401 => 'Sua sessão expirou. Saia e entre de novo.',
      413 => 'A foto é grande demais. Tente outra.',
      422 => 'O Google não conseguiu analisar esta foto. Tente outra.',
      429 => 'Muitas consultas seguidas. Aguarde um momento.',
      _ => 'Não foi possível identificar agora. Tente de novo mais tarde.',
    };
  }
}
