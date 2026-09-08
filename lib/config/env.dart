/// Credenciais lidas em tempo de compilacao.
///
/// Nada de chave hardcoded: os valores entram por `--dart-define-from-file`.
///
///   flutter run   --dart-define-from-file=env.json
///   flutter build web --dart-define-from-file=env.json
///
/// `env.json` esta no .gitignore; `env.example.json` mostra os nomes.
///
/// Lembrete do que a versao React ensinou: estas chaves sao *publicas por
/// design* e vao para o bundle/APK de qualquer jeito. Tira-las do codigo evita
/// vazar no repositorio, mas quem protege o dado sao as Firestore Rules e o
/// RLS do Supabase.
library;

import 'package:flutter/foundation.dart' show kIsWeb;

class Env {
  const Env._();

  // ── Firebase: chave e app por plataforma ────────────────────────────────
  //
  // Web e Android usam credenciais DIFERENTES, e nao e preciosismo: a
  // restricao de aplicativo do Google Cloud e exclusiva. A chave web e travada
  // por referenciador HTTP, e requisicao sem header `Referer` — que e o caso
  // de todo app nativo — seria recusada. Uma chave so para os dois alvos
  // significa ou web desprotegida, ou Android quebrado.
  //
  // O `appId` tambem difere: sao dois apps registrados no mesmo projeto.

  static const _apiKeyWeb = String.fromEnvironment('FIREBASE_API_KEY_WEB');
  static const _apiKeyAndroid = String.fromEnvironment(
    'FIREBASE_API_KEY_ANDROID',
  );

  static const _appIdWeb = String.fromEnvironment('FIREBASE_APP_ID_WEB');
  static const _appIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
  );

  static String get firebaseApiKey => kIsWeb ? _apiKeyWeb : _apiKeyAndroid;
  static String get firebaseAppId => kIsWeb ? _appIdWeb : _appIdAndroid;

  // ── Firebase: comum aos dois alvos ──────────────────────────────────────

  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  // ── Supabase ────────────────────────────────────────────────────────────
  //
  // As chaves `anon` viraram legado e foram desativadas neste projeto em
  // 08/09/2026. O formato atual e `sb_publishable_...`.

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Campos sem os quais o app nao sobe, ja resolvidos para a plataforma atual.
  static Map<String, String> get _obrigatorios {
    // Nomes em variavel, e nao ternario dentro do literal: o analyzer nao
    // consegue provar que duas chaves condicionais diferem e acusa
    // `equal_keys_in_map`.
    final nomeApiKey = kIsWeb
        ? 'FIREBASE_API_KEY_WEB'
        : 'FIREBASE_API_KEY_ANDROID';
    final nomeAppId = kIsWeb
        ? 'FIREBASE_APP_ID_WEB'
        : 'FIREBASE_APP_ID_ANDROID';

    return {
      nomeApiKey: firebaseApiKey,
      nomeAppId: firebaseAppId,
      'FIREBASE_MESSAGING_SENDER_ID': firebaseMessagingSenderId,
      'FIREBASE_PROJECT_ID': firebaseProjectId,
      'SUPABASE_URL': supabaseUrl,
      'SUPABASE_PUBLISHABLE_KEY': supabasePublishableKey,
    };
  }

  static List<String> get faltando => _obrigatorios.entries
      .where((e) => e.value.isEmpty)
      .map((e) => e.key)
      .toList();

  /// Falha explicita e cedo.
  ///
  /// Sem isto, uma variavel ausente vira string vazia e o app so quebra la na
  /// frente, no login — o mesmo modo de falha do `import.meta.env` na versao
  /// React, onde o build passava com a chave `undefined`.
  static bool get completo => faltando.isEmpty;
}
