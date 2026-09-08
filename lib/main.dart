import 'package:flutter/material.dart';

import 'config/env.dart';
import 'screens/app_shell.dart';
import 'services/auth_service.dart';
import 'services/firebase_init.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sem credenciais o app nao sobe — e diz exatamente o que falta.
  //
  // A versao React falhava calada aqui: `import.meta.env` ausente virava
  // `undefined`, o build passava e o erro so aparecia no login. Uma tela de
  // erro legivel custa 20 linhas e economiza a tarde de quem clonar o repo.
  if (!Env.completo) {
    runApp(TelaDeConfiguracao(faltando: Env.faltando));
    return;
  }

  await inicializarServicos();
  runApp(const EcoMapApp());
}

class EcoMapApp extends StatelessWidget {
  const EcoMapApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EcoMapBrasil',
        debugShowCheckedModeBanner: false,
        theme: construirTema(),
        home: AppShell(auth: AuthService()),
      );
}

/// Mostrada quando falta variavel de ambiente.
class TelaDeConfiguracao extends StatelessWidget {
  const TelaDeConfiguracao({super.key, required this.faltando});

  final List<String> faltando;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppCores.fundo,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.key_off,
                        size: 40, color: AppCores.erroTexto),
                    const SizedBox(height: 16),
                    const Text(
                      'Faltam credenciais',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppCores.texto,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'O app precisa das chaves do Firebase e do Supabase '
                      'para subir. Copie env.example.json para env.json, '
                      'preencha, e rode com:',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppCores.textoMedio,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const SelectableText(
                        'flutter run --dart-define-from-file=env.json',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Variáveis ausentes:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppCores.texto,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final v in faltando)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.close,
                                size: 14, color: AppCores.erroTexto),
                            const SizedBox(width: 8),
                            SelectableText(
                              v,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: AppCores.erroTexto,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
