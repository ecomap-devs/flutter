import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/home_data.dart';
import '../../theme/app_theme.dart';
import '../animacao_na_tela.dart';

/// Rosca de participacao por bioma — porte do `DonutChart()` do Home.jsx.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key});

  @override
  Widget build(BuildContext context) {
    final total = desmatamentoPorBioma.fold<int>(0, (s, b) => s + b.valor);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: AnimacaoNaTela(
            builder: (_, progresso, _) => CustomPaint(
              painter: _DonutPainter(
                progresso: Curves.easeInOutCubic.transform(progresso),
                total: total,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total}k',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppCores.texto,
                      ),
                    ),
                    const Text(
                      'km² perdidos',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppCores.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final b in desmatamentoPorBioma)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppCores.biomasGrafico[b.nome],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    b.nome,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppCores.textoMedio,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.progresso, required this.total});

  final double progresso;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = math.min(size.width, size.height) / 2 - 8;
    final espessura = raio * 0.32;

    var inicio = -math.pi / 2;
    for (final b in desmatamentoPorBioma) {
      final varredura = (b.valor / total) * 2 * math.pi * progresso;
      final p = Paint()
        ..color = AppCores.biomasGrafico[b.nome] ?? AppCores.verde
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura;

      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: raio - espessura / 2),
        inicio,
        varredura,
        false,
        p,
      );
      inicio += (b.valor / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progresso != progresso;
}
