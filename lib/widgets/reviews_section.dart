import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;

import '../models/avaliacao.dart';
import '../services/reviews_service.dart';
import '../theme/app_theme.dart';
import 'estrelas.dart';

/// Secao "Avaliacoes do Site" — porte do Reviews.jsx.
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({
    super.key,
    required this.usuario,
    required this.aoPedirLogin,
    this.service,
  });

  final User? usuario;
  final VoidCallback aoPedirLogin;
  final ReviewsService? service;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  late final ReviewsService _service = widget.service ?? ReviewsService();
  final _comentario = TextEditingController();

  static const _porPagina = 6;

  int _nota = 0;
  bool _enviando = false;
  String _erro = '';
  bool _sucesso = false;

  // A assinatura vive no estado, e não no `build`: antes o stream era criado
  // de novo a cada reconstrução, e o app reassinava a coleção à toa.
  int _limite = _porPagina;
  StreamSubscription<List<Avaliacao>>? _assinatura;
  List<Avaliacao> _lista = const [];
  bool _carregando = true;
  bool _falhou = false;
  ResumoAvaliacoes? _resumo;
  int _pedidoResumo = 0;
  Timer? _relogioResumo;

  @override
  void initState() {
    super.initState();
    _assinar();
    // Agregação não é tempo real: uma edição fora da página visível não
    // dispara a lista. O resumo é refeito também de tempos em tempos.
    _relogioResumo = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _atualizarResumo(),
    );
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    _relogioResumo?.cancel();
    _comentario.dispose();
    super.dispose();
  }

  void _assinar() {
    _assinatura?.cancel();
    _assinatura = _service
        .observar(limite: _limite)
        .listen(
          (lista) {
            if (!mounted) return;
            setState(() {
              _lista = lista;
              _carregando = false;
              _falhou = false;
            });
            _atualizarResumo();
          },
          onError: (Object _) {
            if (mounted) {
              setState(() {
                _carregando = false;
                _falhou = true;
              });
            }
          },
        );
  }

  Future<void> _atualizarResumo() async {
    // Só a resposta do pedido mais recente vale: uma lenta que chegue depois
    // não sobrescreve a nova.
    final pedido = ++_pedidoResumo;
    try {
      final r = await _service.resumo();
      if (mounted && pedido == _pedidoResumo) setState(() => _resumo = r);
    } catch (_) {
      // Mantém o último resumo; a lista continua funcionando.
    }
  }

  void _mudarLimite(int limite) {
    setState(() => _limite = limite);
    _assinar();
  }

  Future<void> _enviar() async {
    setState(() => _erro = '');

    final u = widget.usuario;
    if (u == null) {
      widget.aoPedirLogin();
      return;
    }
    if (_nota == 0) {
      setState(() => _erro = 'Selecione uma nota de 1 a 5 estrelas.');
      return;
    }
    if (_comentario.text.trim().isEmpty) {
      setState(() => _erro = 'Escreva um comentário.');
      return;
    }

    if (_comentario.text.trim().length > maxComentario) {
      setState(
        () => _erro = 'O comentário pode ter até $maxComentario caracteres.',
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await _service.publicar(
        usuario: u,
        nota: _nota,
        comentario: _comentario.text,
      );
      if (!mounted) return;
      unawaited(_atualizarResumo());
      _comentario.clear();
      setState(() {
        _nota = 0;
        _sucesso = true;
      });
      // A versao React nao tratava falha aqui: o `addDoc` sem try/catch
      // deixava o botao travado em "Enviando..." para sempre se a regra do
      // Firestore recusasse a escrita.
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _sucesso = false);
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(
          () => _erro = e.code == 'permission-denied'
              ? 'O servidor recusou a avaliação. Confira se o comentário tem '
                    'até $maxComentario caracteres e tente de novo.'
              : 'Não foi possível enviar. Verifique sua conexão e tente de novo.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível enviar. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logado = widget.usuario != null;

    return Container(
      width: double.infinity,
      color: AppCores.fundo,
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Builder(
            builder: (context) {
              final visiveis = _lista;
              final media = _resumo?.media;
              final total = _resumo?.total ?? _lista.length;
              final restantes = total - _lista.length;

              return Column(
                children: [
                  const Text(
                    'COMUNIDADE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppCores.verde,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Avaliações do Site',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppCores.texto,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (media != null) ...[
                    const SizedBox(height: 16),
                    _CartaoMedia(media: media, quantidade: total),
                  ],
                  const SizedBox(height: 48),

                  if (_carregando)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 32),
                      child: CircularProgressIndicator(color: AppCores.verde),
                    ),

                  if (_falhou)
                    _Aviso(
                      texto: 'Não foi possível carregar as avaliações.',
                      erro: true,
                    ),

                  if (visiveis.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, c) {
                        final colunas = (c.maxWidth / 340).floor().clamp(1, 3);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visiveis.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: colunas,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                mainAxisExtent: 172,
                              ),
                          itemBuilder: (_, i) =>
                              _CartaoAvaliacao(avaliacao: visiveis[i]),
                        );
                      },
                    ),

                  if (restantes > 0 || _limite > _porPagina) ...[
                    const SizedBox(height: 24),
                    OutlinedButton(
                      // De 12 em 12, até acabar: antes "Mostrar mais" baixava
                      // a coleção inteira de uma vez.
                      onPressed: () => _mudarLimite(
                        restantes > 0 ? _limite + 12 : _porPagina,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppCores.verde,
                        side: const BorderSide(color: AppCores.verde),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        restantes > 0
                            ? 'Mostrar mais ($restantes restantes)'
                            : 'Mostrar menos',
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                  _Formulario(
                    logado: logado,
                    nota: _nota,
                    comentario: _comentario,
                    enviando: _enviando,
                    erro: _erro,
                    sucesso: _sucesso,
                    aoMudarNota: (n) => setState(() => _nota = n),
                    aoEnviar: _enviar,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CartaoMedia extends StatelessWidget {
  const _CartaoMedia({required this.media, required this.quantidade});

  final double media;
  final int quantidade;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppCores.borda),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          media.toStringAsFixed(1).replaceAll('.', ','),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppCores.texto,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Estrelas(valor: media.round(), somenteLeitura: true),
            const SizedBox(height: 2),
            Text(
              'Classificação do site • $quantidade '
              '${quantidade == 1 ? 'avaliação' : 'avaliações'}',
              style: const TextStyle(fontSize: 12, color: AppCores.textoSuave),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CartaoAvaliacao extends StatelessWidget {
  const _CartaoAvaliacao({required this.avaliacao});

  final Avaliacao avaliacao;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppCores.borda),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Avatar(nome: avaliacao.nome, url: avaliacao.fotoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    avaliacao.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppCores.texto,
                    ),
                  ),
                  Row(
                    children: [
                      Estrelas(valor: avaliacao.nota, somenteLeitura: true),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          avaliacao.tempoRelativo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Text(
            avaliacao.comentario,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppCores.textoMedio,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nome, required this.url});

  final String nome;
  final String url;

  @override
  Widget build(BuildContext context) {
    final inicial = nome.isEmpty ? '?' : nome.characters.first.toUpperCase();

    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
        ),
      ),
      child: url.isEmpty
          ? Center(
              child: Text(
                inicial,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppCores.verde,
                ),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              // Avatar quebrado nao pode virar caixa cinza: cai na inicial.
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  inicial,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppCores.verde,
                  ),
                ),
              ),
            ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.logado,
    required this.nota,
    required this.comentario,
    required this.enviando,
    required this.erro,
    required this.sucesso,
    required this.aoMudarNota,
    required this.aoEnviar,
  });

  final bool logado;
  final int nota;
  final TextEditingController comentario;
  final bool enviando;
  final String erro;
  final bool sucesso;
  final ValueChanged<int> aoMudarNota;
  final VoidCallback aoEnviar;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppCores.borda),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            logado ? 'Deixe sua avaliação' : 'Faça login para avaliar',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppCores.texto,
            ),
          ),
          const SizedBox(height: 20),

          if (sucesso) ...[
            _Aviso(texto: '✓ Avaliação enviada com sucesso!', erro: false),
            const SizedBox(height: 16),
          ],
          if (erro.isNotEmpty) ...[
            _Aviso(texto: erro, erro: true),
            const SizedBox(height: 16),
          ],

          const Text(
            'Sua nota:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppCores.textoMedio,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Estrelas(
              valor: nota,
              aoMudar: logado ? aoMudarNota : null,
              somenteLeitura: !logado,
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: comentario,
            enabled: logado,
            maxLines: 4,
            // O mesmo limite das Firestore Rules: antes o campo aceitava
            // qualquer tamanho e o servidor recusava sem dizer por quê.
            maxLength: maxComentario,
            inputFormatters: [LengthLimitingTextInputFormatter(maxComentario)],
            decoration: InputDecoration(
              hintText: logado
                  ? 'Escreva seu comentário sobre o site...'
                  : 'Faça login para deixar um comentário...',
              fillColor: logado ? Colors.white : const Color(0xFFF9FAFB),
            ),
          ),
          const SizedBox(height: 14),

          FilledButton(
            onPressed: enviando ? null : aoEnviar,
            child: Text(
              !logado
                  ? 'Entrar para avaliar'
                  : enviando
                  ? 'Enviando...'
                  : 'Enviar avaliação',
            ),
          ),
        ],
      ),
    ),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.erro});

  final String texto;
  final bool erro;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: erro ? AppCores.erroFundo : AppCores.sucessoFundo,
      border: Border.all(
        color: erro ? AppCores.erroBorda : AppCores.sucessoBorda,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      texto,
      style: TextStyle(
        fontSize: 13,
        fontWeight: erro ? FontWeight.normal : FontWeight.w600,
        color: erro ? AppCores.erroTexto : AppCores.verde,
      ),
    ),
  );
}
