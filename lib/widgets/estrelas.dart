import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Nota em estrelas — porte do `StarRating` do Reviews.jsx.
class Estrelas extends StatefulWidget {
  const Estrelas({
    super.key,
    required this.valor,
    this.aoMudar,
    this.somenteLeitura = false,
    this.tamanho,
  });

  final int valor;
  final ValueChanged<int>? aoMudar;
  final bool somenteLeitura;
  final double? tamanho;

  @override
  State<Estrelas> createState() => _EstrelasState();
}

class _EstrelasState extends State<Estrelas> {
  int _hover = 0;

  @override
  Widget build(BuildContext context) {
    final tam = widget.tamanho ?? (widget.somenteLeitura ? 16.0 : 30.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var estrela = 1; estrela <= 5; estrela++)
          MouseRegion(
            cursor: widget.somenteLeitura
                ? MouseCursor.defer
                : SystemMouseCursors.click,
            onEnter: widget.somenteLeitura
                ? null
                : (_) => setState(() => _hover = estrela),
            onExit: widget.somenteLeitura
                ? null
                : (_) => setState(() => _hover = 0),
            child: GestureDetector(
              onTap: widget.somenteLeitura
                  ? null
                  : () => widget.aoMudar?.call(estrela),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.star_rounded,
                  size: tam,
                  color: estrela <= (_hover > 0 ? _hover : widget.valor)
                      ? AppCores.estrela
                      : const Color(0xFFD1D5DB),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
