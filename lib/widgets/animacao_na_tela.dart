import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mede a interseção com todos os scrollables ancestrais, inclusive grades
/// dentro da página. Não usa timer nem mantém animações rodando fora da tela.
class AnimacaoNaTela extends StatefulWidget {
  const AnimacaoNaTela({
    super.key,
    required this.builder,
    this.child,
    this.duracao = const Duration(milliseconds: 1200),
    this.atraso = Duration.zero,
  });

  final ValueWidgetBuilder<double> builder;
  final Widget? child;
  final Duration duracao;
  final Duration atraso;

  @override
  State<AnimacaoNaTela> createState() => _AnimacaoNaTelaState();
}

class _AnimacaoNaTelaState extends State<AnimacaoNaTela>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _animacao = AnimationController(vsync: this);
  final _rolagens = <ScrollableState>[];
  bool _agendada = false;
  bool _visivel = false;
  bool _reduzir = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final rolagem in _rolagens) {
      rolagem.position.removeListener(_agendar);
    }
    _rolagens.clear();
    context.visitAncestorElements((elemento) {
      if (elemento is StatefulElement && elemento.state is ScrollableState) {
        final rolagem = elemento.state as ScrollableState;
        _rolagens.add(rolagem);
        rolagem.position.addListener(_agendar);
      }
      return true;
    });
    _reduzir = MediaQuery.disableAnimationsOf(context);
    _animacao.duration = widget.duracao + widget.atraso;
    _animacao.reverseDuration = const Duration(milliseconds: 260);
    if (_reduzir) _animacao.value = 1;
    _agendar();
  }

  @override
  void didChangeMetrics() => _agendar();

  void _agendar() {
    if (_agendada) return;
    _agendada = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _agendada = false;
      if (mounted) _verificar();
    });
  }

  void _verificar() {
    if (_reduzir) return;
    final caixa = context.findRenderObject();
    if (caixa is! RenderBox || !caixa.hasSize || !caixa.attached) return;
    var janela = Offset.zero & MediaQuery.sizeOf(context);
    for (final rolagem in _rolagens) {
      final ancestral = rolagem.context.findRenderObject();
      if (ancestral is RenderBox && ancestral.hasSize && ancestral.attached) {
        janela = janela.intersect(
          ancestral.localToGlobal(Offset.zero) & ancestral.size,
        );
      }
    }
    final retangulo = caixa.localToGlobal(Offset.zero) & caixa.size;
    final intersecao = retangulo.intersect(janela);
    final visivel =
        !intersecao.isEmpty &&
        intersecao.height >= math.min(retangulo.height, janela.height) * .12;
    // Mantém o estado na borda para não piscar com movimentos mínimos.
    if (visivel && !_visivel) {
      _visivel = true;
      _animacao.forward();
    } else if (intersecao.isEmpty && _visivel) {
      _visivel = false;
      _animacao.reverse();
    }
  }

  @override
  void dispose() {
    for (final rolagem in _rolagens) {
      rolagem.position.removeListener(_agendar);
    }
    WidgetsBinding.instance.removeObserver(this);
    _animacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animacao,
    child: widget.child,
    builder: (context, child) {
      final inicio =
          widget.atraso.inMilliseconds /
          (widget.duracao + widget.atraso).inMilliseconds;
      final progresso = _reduzir
          ? 1.0
          : Interval(inicio, 1).transform(_animacao.value);
      return widget.builder(context, progresso, child);
    },
  );
}

class RevelarAoRolar extends StatelessWidget {
  const RevelarAoRolar({
    super.key,
    required this.child,
    this.atraso = Duration.zero,
  });
  final Widget child;
  final Duration atraso;

  @override
  Widget build(BuildContext context) => AnimacaoNaTela(
    duracao: const Duration(milliseconds: 750),
    atraso: atraso,
    child: child,
    builder: (_, progresso, conteudo) {
      final valor = Curves.easeOutCubic.transform(progresso);
      return Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - valor)),
          child: conteudo,
        ),
      );
    },
  );
}
