import 'package:flutter/material.dart';

import '../../data/home_data.dart';
import '../../theme/app_theme.dart';
import '../animacao_na_tela.dart';

/// Barras horizontais animadas — porte do `AnimatedBars()` do Home.jsx.
///
/// Cada barra cresce em sequência quando o gráfico entra na área visível.
/// As proporções continuam calculadas a partir dos dados originais.
class BarrasChart extends StatelessWidget {
  const BarrasChart({super.key});

  @override
  Widget build(BuildContext context) {
    final maximo = desmatamentoPorBioma
        .map((b) => b.valor)
        .reduce((a, b) => a > b ? a : b);

    return AnimacaoNaTela(
      duracao: const Duration(milliseconds: 1700),
      builder: (_, progresso, _) => Column(
        children: [
          for (final (i, b) in desmatamentoPorBioma.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      b.nome,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppCores.textoMedio,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppCores.borda.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor:
                              b.valor /
                              maximo *
                              Interval(
                                i * .09,
                                .55 + i * .09,
                                curve: Curves.easeOutCubic,
                              ).transform(progresso),
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppCores.biomasGrafico[b.nome],
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${b.valor}k',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppCores.texto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
