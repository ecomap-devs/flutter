import 'package:flutter/material.dart';

import '../../data/home_data.dart';
import '../../theme/app_theme.dart';

/// Barras horizontais animadas — porte do `AnimatedBars()` do Home.jsx.
///
/// Na versao React isso era SVG desenhado a mao. O equivalente natural aqui
/// nao e uma lib de graficos: sao widgets com `AnimatedFractionallySizedBox`,
/// que dao a mesma animacao de crescimento sem dependencia nenhuma.
class BarrasChart extends StatefulWidget {
  const BarrasChart({super.key});

  @override
  State<BarrasChart> createState() => _BarrasChartState();
}

class _BarrasChartState extends State<BarrasChart> {
  bool _animou = false;

  @override
  void initState() {
    super.initState();
    // Equivalente ao IntersectionObserver: dispara uma vez, logo apos montar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animou = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final maximo = desmatamentoPorBioma
        .map((b) => b.valor)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (final b in desmatamentoPorBioma)
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
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        widthFactor: _animou ? b.valor / maximo : 0,
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
    );
  }
}
