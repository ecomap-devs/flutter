import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Modal de login e cadastro — porte do AuthModal.jsx.
class AuthModal extends StatefulWidget {
  const AuthModal({super.key, required this.auth});

  final AuthService auth;

  static Future<void> abrir(BuildContext context, AuthService auth) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => AuthModal(auth: auth),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  bool _cadastro = false;
  bool _carregando = false;
  String _erro = '';

  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  XFile? _foto;
  Uint8List? _bytesFoto;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!mounted) return;
    setState(() {
      _foto = img;
      _bytesFoto = bytes;
    });
  }

  Future<void> _enviar() async {
    setState(() => _erro = '');

    if (_email.text.trim().isEmpty || _senha.text.trim().isEmpty) {
      setState(() => _erro = 'Preencha email e senha.');
      return;
    }
    if (_cadastro && _nome.text.trim().isEmpty) {
      setState(() => _erro = 'Preencha seu nome.');
      return;
    }

    setState(() => _carregando = true);
    try {
      if (_cadastro) {
        await widget.auth.cadastrar(
          nome: _nome.text,
          email: _email.text,
          senha: _senha.text,
          foto: _bytesFoto,
          extensaoFoto: _foto?.name.split('.').last,
        );
      } else {
        await widget.auth.entrar(email: _email.text, senha: _senha.text);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _erro = AuthService.mensagemDeErro(e));
      }
    } finally {
      // O formulario nao se apaga em erro: o texto digitado continua la.
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _cadastro ? 'Criar conta' : 'Entrar na conta',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppCores.texto,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: const Color(0xFF9CA3AF),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _cadastro
                    ? 'Cadastre-se para participar da comunidade.'
                    : 'Acesse para deixar sua avaliação.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppCores.textoSuave,
                ),
              ),
              const SizedBox(height: 22),

              if (_erro.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppCores.erroFundo,
                    border: Border.all(color: AppCores.erroBorda),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _erro,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppCores.erroTexto,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_cadastro) ...[
                TextField(
                  controller: _nome,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Nome completo'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _escolherFoto,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppCores.verdeFundo,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppCores.verde,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _bytesFoto != null
                              ? Image.memory(_bytesFoto!, fit: BoxFit.cover)
                              : const Icon(Icons.photo_camera_outlined,
                                  size: 24, color: AppCores.verde),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Foto de perfil (opcional)',
                        style: TextStyle(
                            fontSize: 12, color: AppCores.textoSuave),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senha,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _carregando ? null : _enviar(),
                decoration: const InputDecoration(hintText: 'Senha'),
              ),
              const SizedBox(height: 20),

              FilledButton(
                onPressed: _carregando ? null : _enviar,
                child: Text(
                  _carregando
                      ? 'Aguarde...'
                      : _cadastro
                          ? 'Criar conta'
                          : 'Entrar',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _carregando
                    ? null
                    : () => setState(() {
                          _cadastro = !_cadastro;
                          _erro = '';
                        }),
                child: Text(
                  _cadastro
                      ? 'Já tem conta? Entrar'
                      : 'Não tem conta? Cadastre-se',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppCores.verde,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
