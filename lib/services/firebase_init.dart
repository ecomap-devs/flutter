import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Sobe Firebase e Supabase com as credenciais de `--dart-define-from-file`.
///
/// Nao usa `firebase_options.dart` do `flutterfire configure` de proposito:
/// aquele arquivo nasce com as chaves escritas dentro e e exatamente o que
/// vazou na versao React. Ele esta no .gitignore; a config vem do env.
Future<void> inicializarServicos() async {
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: Env.firebaseApiKey,
      appId: Env.firebaseAppId,
      messagingSenderId: Env.firebaseMessagingSenderId,
      projectId: Env.firebaseProjectId,
      authDomain: Env.firebaseAuthDomain.isEmpty
          ? null
          : Env.firebaseAuthDomain,
      storageBucket: Env.firebaseStorageBucket.isEmpty
          ? null
          : Env.firebaseStorageBucket,
    ),
  );

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    debug: kDebugMode,
  );
}
