import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Desfoque limitado ao cartão para evitar filtrar a tela inteira.
class SuperficieVidro extends StatelessWidget {
  const SuperficieVidro({
    super.key,
    required this.child,
    this.escuro = false,
    this.padding = const EdgeInsets.all(24),
    this.raio = 24,
    this.animarHover = false,
  });

  final Widget child;
  final bool escuro;
  final EdgeInsetsGeometry padding;
  final double raio;
  final bool animarHover;

  @override
  Widget build(BuildContext context) {
    final superficie = ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: escuro
                  ? [const Color(0xB314532D), const Color(0xC70F1117)]
                  : [const Color(0xF5FFFFFF), const Color(0xD9F0FDF4)],
            ),
            borderRadius: BorderRadius.circular(raio),
            border: Border.all(
              color: escuro
                  ? Colors.white.withValues(alpha: .22)
                  : AppCores.verde.withValues(alpha: .16),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return animarHover ? EfeitoHover(child: superficie) : superficie;
  }
}

/// Elevação, escala e luz de borda também respondem ao foco dos descendentes.
class EfeitoHover extends StatefulWidget {
  const EfeitoHover({super.key, required this.child});
  final Widget child;

  @override
  State<EfeitoHover> createState() => _EfeitoHoverState();
}

class _EfeitoHoverState extends State<EfeitoHover> {
  bool _mouse = false;
  bool _foco = false;

  @override
  Widget build(BuildContext context) {
    final ativo = _mouse || _foco;
    final duracao = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    return MouseRegion(
      onEnter: (_) => setState(() => _mouse = true),
      onExit: (_) => setState(() => _mouse = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (valor) => setState(() => _foco = valor),
        child: AnimatedScale(
          scale: ativo ? 1.018 : 1,
          duration: duracao,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: duracao,
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, ativo ? -7 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppCores.verde.withValues(alpha: ativo ? .24 : 0),
                  blurRadius: ativo ? 32 : 0,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppCores.verdeClaro.withValues(alpha: ativo ? .5 : 0),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Entrada curta e finita, sem movimento quando o sistema o desabilita.
class EntradaSuave extends StatelessWidget {
  const EntradaSuave({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, valor, conteudo) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - valor)),
          child: conteudo,
        ),
      ),
    );
  }
}

/// Resposta visual ao mouse e ao foco de teclado, com o mesmo alvo de toque.
class CartaoInterativo extends StatelessWidget {
  const CartaoInterativo({
    super.key,
    required this.child,
    required this.aoTocar,
  });
  final Widget child;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => EfeitoHover(
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: aoTocar, child: child),
    ),
  );
}
