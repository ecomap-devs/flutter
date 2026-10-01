import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/identificacao.dart';
import '../services/identificacao_service.dart';
import '../theme/app_theme.dart';
import '../widgets/superficie_vidro.dart';

/// Tire uma foto de um animal e veja que animal o Gemini acha que e.
///
/// Exige login: cada consulta gasta a cota do projeto no Gemini, e a Edge
/// Function recusa quem nao manda um ID token do Firebase.
class FotosScreen extends StatefulWidget {
  const FotosScreen({
    super.key,
    required this.usuario,
    required this.aoPedirLogin,
    this.servico,
  });

  final User? usuario;
  final VoidCallback aoPedirLogin;
  final IdentificacaoService? servico;

  @override
  State<FotosScreen> createState() => _FotosScreenState();
}

class _FotosScreenState extends State<FotosScreen> {
  late final _servico = widget.servico ?? IdentificacaoService();

  Uint8List? _foto;
  Identificacao? _resultado;
  bool _carregando = false;
  String _erro = '';

  Future<void> _escolher(ImageSource origem) async {
    final XFile? img;
    try {
      // 1024 px basta para o Vision reconhecer o animal e mantem o envio
      // pequeno em rede movel.
      img = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } catch (_) {
      setState(() => _erro = 'Não foi possível abrir a câmera ou a galeria.');
      return;
    }
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!mounted) return;

    setState(() {
      _foto = bytes;
      _resultado = null;
      _erro = '';
      _carregando = true;
    });

    try {
      final r = await _servico.identificar(bytes);
      if (mounted) setState(() => _resultado = r);
    } catch (e) {
      // A tela mostra uma mensagem amigavel; o log guarda o erro real, com o
      // status e o corpo da resposta, para dar para diagnosticar pelo adb.
      debugPrint('Identificacao falhou: $e');
      if (mounted) {
        setState(() => _erro = IdentificacaoService.mensagemDeErro(e));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Que animal é esse?',
                  style: TextStyle(
                    fontSize: 26,
                    letterSpacing: -.7,
                    fontWeight: FontWeight.w800,
                    color: AppCores.texto,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tire uma foto e a inteligência artificial do Google '
                  'diz que animal é.',
                  style: TextStyle(fontSize: 12, color: AppCores.textoSuave),
                ),
                const SizedBox(height: 4),
                // O nivel gratuito do Gemini permite ao Google usar o que e
                // enviado; quem manda a foto precisa saber disso antes.
                const Text(
                  'A foto é enviada ao Gemini, do Google, que pode usá-la para '
                  'melhorar os serviços dele. Não envie fotos de pessoas.',
                  style: TextStyle(fontSize: 11, color: AppCores.textoSuave),
                ),
                const SizedBox(height: 18),
                if (widget.usuario == null)
                  _PedirLogin(aoPedirLogin: widget.aoPedirLogin)
                else
                  ..._conteudo(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _conteudo() => [
    Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _carregando ? null : () => _escolher(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Tirar foto'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _carregando
                ? null
                : () => _escolher(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galeria'),
          ),
        ),
      ],
    ),
    if (_foto != null) ...[
      const SizedBox(height: 18),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: Image.memory(_foto!, fit: BoxFit.cover),
        ),
      ),
    ],
    if (_carregando) ...[
      const SizedBox(height: 24),
      const Center(child: CircularProgressIndicator(color: AppCores.verde)),
      const SizedBox(height: 10),
      const Text(
        'Procurando o animal...',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppCores.textoSuave),
      ),
    ],
    if (_erro.isNotEmpty) ...[
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppCores.erroFundo,
          border: Border.all(color: AppCores.erroBorda),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _erro,
          style: const TextStyle(fontSize: 13, color: AppCores.erroTexto),
        ),
      ),
    ],
    if (_resultado != null) ...[
      const SizedBox(height: 18),
      _Resultado(identificacao: _resultado!),
    ],
  ];
}

class _PedirLogin extends StatelessWidget {
  const _PedirLogin({required this.aoPedirLogin});

  final VoidCallback aoPedirLogin;

  @override
  Widget build(BuildContext context) {
    return SuperficieVidro(
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: AppCores.verde, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Entre na sua conta para identificar animais por foto.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppCores.textoMedio),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: aoPedirLogin,
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Entrar'),
          ),
        ],
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.identificacao});

  final Identificacao identificacao;

  static const _titulo = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppCores.texto,
  );

  @override
  Widget build(BuildContext context) {
    final r = identificacao;
    if (r.vazia) {
      return SuperficieVidro(
        child: Text(
          r.ehAnimal
              ? 'Parece haver um animal, mas não deu para dizer qual. '
                    'Tente uma imagem mais nítida, com o animal em destaque.'
              : 'Não encontramos nenhum animal nesta foto.',
          style: const TextStyle(fontSize: 13, color: AppCores.textoMedio),
        ),
      );
    }

    return SuperficieVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parece ser',
            style: TextStyle(fontSize: 12, color: AppCores.textoSuave),
          ),
          const SizedBox(height: 4),
          Text(
            r.nomePopular!,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppCores.verde,
            ),
          ),
          if (r.nomeCientifico != null) ...[
            const SizedBox(height: 2),
            Text(
              r.nomeCientifico!,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppCores.textoMedio,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Chip(label: Text(r.confianca.rotulo)),
          if (r.descricao != null) ...[
            const SizedBox(height: 14),
            const Text('Por quê', style: _titulo),
            const SizedBox(height: 4),
            Text(
              r.descricao!,
              style: const TextStyle(fontSize: 13, color: AppCores.textoMedio),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Identificação feita por inteligência artificial: pode errar.',
            style: TextStyle(fontSize: 11, color: AppCores.textoSuave),
          ),
        ],
      ),
    );
  }
}
