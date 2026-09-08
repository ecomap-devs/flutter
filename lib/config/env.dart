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

class Env {
  const Env._();

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
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

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Campos sem os quais o app nao sobe.
  static const _obrigatorios = <String, String>{
    'FIREBASE_API_KEY': firebaseApiKey,
    'FIREBASE_APP_ID': firebaseAppId,
    'FIREBASE_MESSAGING_SENDER_ID': firebaseMessagingSenderId,
    'FIREBASE_PROJECT_ID': firebaseProjectId,
    'SUPABASE_URL': supabaseUrl,
    'SUPABASE_ANON_KEY': supabaseAnonKey,
  };

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
