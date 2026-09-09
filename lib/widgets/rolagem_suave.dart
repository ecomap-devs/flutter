import 'package:flutter/material.dart';

/// Suaviza a roda do mouse. Arraste, teclado, barra de rolagem e pequenos
/// deltas de trackpad continuam sendo tratados pelo Scrollable do Flutter.
class ControladorRolagemSuave extends ScrollController {
  bool reduzirMovimento = false;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _PosicaoSuave(
    physics: physics,
    context: context,
    oldPosition: oldPosition,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    reduzir: () => reduzirMovimento,
  );
}

class _PosicaoSuave extends ScrollPositionWithSingleContext {
  _PosicaoSuave({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.keepScrollOffset,
    required this.reduzir,
  });

  final bool Function() reduzir;
  double? _destino;

  @override
  void pointerScroll(double delta) {
    if (reduzir() || delta.abs() < 18) {
      _destino = null;
      super.pointerScroll(delta);
      return;
    }
    final mesmaDirecao = ((_destino ?? pixels) - pixels) * delta >= 0;
    final origem = activity is DrivenScrollActivity && mesmaDirecao
        ? (_destino ?? pixels)
        : pixels;
    final destino = (origem + delta).clamp(minScrollExtent, maxScrollExtent);
    _destino = destino;
    if (destino == pixels) return;
    animateTo(
      destino,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }
}

class RolagemSuave extends StatefulWidget {
  const RolagemSuave({super.key, required this.builder});
  final Widget Function(BuildContext, ScrollController) builder;

  @override
  State<RolagemSuave> createState() => _RolagemSuaveState();
}

class _RolagemSuaveState extends State<RolagemSuave> {
  final _controlador = ControladorRolagemSuave();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controlador.reduzirMovimento = MediaQuery.disableAnimationsOf(context);
    return widget.builder(context, _controlador);
  }
}
