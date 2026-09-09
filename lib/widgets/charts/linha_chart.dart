import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../animacao_na_tela.dart';

/// Linha de tendencia populacional.
///
/// Serve tanto ao `LineChart()` da Home quanto ao `MiniLineChart` da tela de
/// Animais — a diferenca e so tamanho e se mostra eixo.
class LinhaChart extends StatelessWidget {
  const LinhaChart({
    super.key,
    required this.valores,
    required this.rotulos,
    this.cor = AppCores.verde,
    this.mostrarEixo = true,
    this.altura = 180,
  });

  final List<int> valores;
  final List<String> rotulos;
  final Color cor;
  final bool mostrarEixo;
  final double altura;

  @override
  Widget build(BuildContext context) {
    if (valores.length < 2) return SizedBox(height: altura);

    return AnimacaoNaTela(
      duracao: const Duration(milliseconds: 1500),
      builder: (_, t, _) => SizedBox(
        height: altura,
        child: CustomPaint(
          painter: _LinhaPainter(
            valores: valores,
            rotulos: rotulos,
            cor: cor,
            progresso: Curves.easeInOutCubic.transform(t),
            mostrarEixo: mostrarEixo,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _LinhaPainter extends CustomPainter {
  _LinhaPainter({
    required this.valores,
    required this.rotulos,
    required this.cor,
    required this.progresso,
    required this.mostrarEixo,
  });

  final List<int> valores;
  final List<String> rotulos;
  final Color cor;
  final double progresso;
  final bool mostrarEixo;

  @override
  void paint(Canvas canvas, Size size) {
    final margemBaixo = mostrarEixo ? 22.0 : 4.0;
    final alturaGrafico = size.height - margemBaixo - 4;

    final maximo = valores.reduce((a, b) => a > b ? a : b).toDouble();
    final minimo = valores.reduce((a, b) => a < b ? a : b).toDouble();
    // Faixa nunca zero: serie constante desenharia divisao por zero.
    final faixa = (maximo - minimo).abs() < 1 ? 1.0 : maximo - minimo;

    Offset pontoEm(int i) {
      final x = (i / (valores.length - 1)) * size.width;
      final norm = (valores[i] - minimo) / faixa;
      return Offset(x, 4 + alturaGrafico * (1 - norm));
    }

    final caminho = Path();
    final quantos = ((valores.length - 1) * progresso).clamp(
      0,
      valores.length - 1,
    );
    caminho.moveTo(pontoEm(0).dx, pontoEm(0).dy);
    for (var i = 1; i <= quantos.floor(); i++) {
      final p = pontoEm(i);
      caminho.lineTo(p.dx, p.dy);
    }

    final indice = quantos.floor();
    final fracao = (quantos - indice).toDouble();
    final ponta = indice < valores.length - 1
        ? Offset.lerp(pontoEm(indice), pontoEm(indice + 1), fracao)!
        : pontoEm(indice);
    caminho.lineTo(ponta.dx, ponta.dy);

    // Area sob a curva.
    final area = Path.from(caminho)
      ..lineTo(ponta.dx, 4 + alturaGrafico)
      ..lineTo(pontoEm(0).dx, 4 + alturaGrafico)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cor.withValues(alpha: 0.22), cor.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      caminho,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i <= quantos.floor(); i++) {
      final p = pontoEm(i);
      canvas.drawCircle(p, 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        3.5,
        Paint()
          ..color = cor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (!mostrarEixo) return;
    for (var i = 0; i < rotulos.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: rotulos[i],
          style: const TextStyle(fontSize: 9, color: AppCores.textoSuave),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (i / (valores.length - 1)) * size.width - tp.width / 2;
      tp.paint(
        canvas,
        Offset(x.clamp(0, size.width - tp.width), size.height - 14),
      );
    }
  }

  @override
  bool shouldRepaint(_LinhaPainter old) =>
      old.progresso != progresso || old.valores != valores;
}
