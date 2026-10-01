import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Nota em estrelas — porte do `StarRating` do Reviews.jsx.
///
/// Revisão de 01/10/2026: as estrelas eram ícones com `GestureDetector`, sem
/// rótulo nem estado. O leitor de tela não sabia qual era a nota nem que dava
/// para tocar. Agora a nota de leitura é um rótulo só ("4 de 5 estrelas"), e
/// a editável é um grupo de botões focáveis, cada um dizendo se está marcado.
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

  Icon _icone(int estrela, double tam) => Icon(
    Icons.star_rounded,
    size: tam,
    color: estrela <= (_hover > 0 ? _hover : widget.valor)
        ? AppCores.estrela
        : const Color(0xFFD1D5DB),
  );

  @override
  Widget build(BuildContext context) {
    final tam = widget.tamanho ?? (widget.somenteLeitura ? 16.0 : 30.0);
    final editavel = !widget.somenteLeitura && widget.aoMudar != null;

    if (!editavel) {
      return Semantics(
        label: '${widget.valor} de 5 estrelas',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var estrela = 1; estrela <= 5; estrela++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _icone(estrela, tam),
              ),
          ],
        ),
      );
    }

    return Semantics(
      label: 'Sua nota',
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var estrela = 1; estrela <= 5; estrela++)
            Semantics(
              button: true,
              inMutuallyExclusiveGroup: true,
              checked: widget.valor == estrela,
              label: '$estrela estrela${estrela > 1 ? 's' : ''}',
              excludeSemantics: true,
              child: InkResponse(
                onTap: () => widget.aoMudar?.call(estrela),
                onHover: (dentro) =>
                    setState(() => _hover = dentro ? estrela : 0),
                radius: tam * 0.7,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _icone(estrela, tam),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
