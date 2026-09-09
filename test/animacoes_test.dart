import 'package:ecomapbrasil/widgets/animacao_na_tela.dart';
import 'package:ecomapbrasil/widgets/charts/barras_chart.dart';
import 'package:ecomapbrasil/widgets/rolagem_suave.dart';
import 'package:ecomapbrasil/widgets/superficie_vidro.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('barras aguardam a rolagem, crescem em sequência e reiniciam', (
    tester,
  ) async {
    final controlador = ScrollController();
    addTearDown(controlador.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controlador,
            child: const Column(
              children: [
                SizedBox(height: 900),
                SizedBox(height: 310, child: BarrasChart()),
                SizedBox(height: 900),
              ],
            ),
          ),
        ),
      ),
    );
    List<double> larguras() => tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((barra) => barra.widthFactor!)
        .toList();
    await tester.pumpAndSettle();
    expect(larguras(), everyElement(0));
    controlador.jumpTo(800);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(larguras().first, greaterThan(0));
    expect(larguras().last, 0);
    await tester.pumpAndSettle();
    expect(larguras().first, 1);
    controlador.jumpTo(0);
    await tester.pumpAndSettle();
    expect(larguras(), everyElement(0));
    controlador.jumpTo(800);
    await tester.pumpAndSettle();
    expect(larguras().first, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('revelação considera a rolagem externa de uma grade aninhada', (
    tester,
  ) async {
    final controlador = ScrollController();
    addTearDown(controlador.dispose);
    var progresso = -1.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controlador,
            child: Column(
              children: [
                const SizedBox(height: 900),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  children: [
                    AnimacaoNaTela(
                      builder: (_, valor, _) {
                        progresso = valor;
                        return const SizedBox(height: 200);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 900),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(progresso, 0);
    controlador.jumpTo(800);
    await tester.pumpAndSettle();
    expect(progresso, 1);
  });

  testWidgets('movimento reduzido mostra conteúdo imediatamente', (
    tester,
  ) async {
    var progresso = -1.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            disableAnimations: true,
          ),
          child: AnimacaoNaTela(
            builder: (_, valor, _) {
              progresso = valor;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(progresso, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'roda do mouse percorre distância gradualmente e respeita limites',
    (tester) async {
      final controlador = ControladorRolagemSuave();
      addTearDown(controlador.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: controlador,
              children: const [SizedBox(height: 3000)],
            ),
          ),
        ),
      );
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(200, 200),
          scrollDelta: Offset(0, 300),
        ),
      );
      await tester.pump();
      expect(controlador.offset, 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controlador.offset, inExclusiveRange(0, 300));
      await tester.pumpAndSettle();
      expect(controlador.offset, 300);
      controlador.position.pointerScroll(10000);
      await tester.pumpAndSettle();
      expect(controlador.offset, controlador.position.maxScrollExtent);
      controlador.reduzirMovimento = true;
      controlador.position.pointerScroll(-100);
      expect(controlador.offset, controlador.position.maxScrollExtent - 100);
    },
  );

  testWidgets('hover amplia o cartão e retorna ao sair', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: EfeitoHover(child: SizedBox(width: 200, height: 100)),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(EfeitoHover)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      greaterThan(1),
    );
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await mouse.removePointer();
  });
}
