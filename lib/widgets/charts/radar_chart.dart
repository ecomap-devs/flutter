import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/home_data.dart';
import '../../theme/app_theme.dart';

/// Radar de pressao por bioma — porte do `RadarChart()` do Home.jsx.
class RadarChart extends StatefulWidget {
  const RadarChart({super.key});

  @override
  State<RadarChart> createState() => _RadarChartState();
}

class _RadarChartState extends State<RadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _RadarPainter(
              progresso: Curves.easeOutCubic.transform(_c.value),
            ),
            size: Size.infinite,
          ),
        ),
      );
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.progresso});

  final double progresso;

  /// Mesma escala da versao React: 780 e o teto, 4 aneis.
  static const _maximo = 780.0;
  static const _niveis = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = math.min(size.width, size.height) / 2 - 34;
    final n = desmatamentoPorBioma.length;

    Offset pontoEm(int i, double fracao) {
      final ang = (i / n) * 2 * math.pi - math.pi / 2;
      return centro +
          Offset(math.cos(ang) * raio * fracao, math.sin(ang) * raio * fracao);
    }

    // Teia de fundo.
    final linhaGrade = Paint()
      ..color = AppCores.borda
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var nivel = 1; nivel <= _niveis; nivel++) {
      final f = nivel / _niveis;
      final p = Path();
      for (var i = 0; i < n; i++) {
        final pt = pontoEm(i, f);
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(p..close(), linhaGrade);
    }

    for (var i = 0; i < n; i++) {
      canvas.drawLine(centro, pontoEm(i, 1), linhaGrade);
    }

    // Poligono de dados.
    final p = Path();
    for (var i = 0; i < n; i++) {
      final f = (desmatamentoPorBioma[i].valor / _maximo) * progresso;
      final pt = pontoEm(i, f);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();

    canvas.drawPath(
      p,
      Paint()..color = AppCores.verde.withValues(alpha: 0.22),
    );
    canvas.drawPath(
      p,
      Paint()
        ..color = AppCores.verde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (var i = 0; i < n; i++) {
      final f = (desmatamentoPorBioma[i].valor / _maximo) * progresso;
      canvas.drawCircle(pontoEm(i, f), 3, Paint()..color = AppCores.verde);
    }

    // Rotulos.
    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: desmatamentoPorBioma[i].nome,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppCores.textoMedio,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final ang = (i / n) * 2 * math.pi - math.pi / 2;
      final pos = centro +
          Offset(math.cos(ang) * (raio + 18), math.sin(ang) * (raio + 18));
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progresso != progresso;
}
