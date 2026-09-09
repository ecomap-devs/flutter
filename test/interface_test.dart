import 'package:ecomapbrasil/screens/animais_screen.dart';
import 'package:ecomapbrasil/theme/app_theme.dart';
import 'package:ecomapbrasil/widgets/hero_natureza.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abertura navega e permite escolher outra espécie', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var mapas = 0;
    var catalogos = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: HeroNatureza(
              aoAbrirMapa: () => mapas++,
              aoAbrirAnimais: () => catalogos++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explorar o mapa'));
    await tester.tap(find.text('Conhecer a fauna'));
    expect(mapas, 1);
    expect(catalogos, 1);
    await tester.tap(find.text('02'));
    await tester.pumpAndSettle();
    expect(find.text('Arara-azul'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abertura cabe em celular com movimento reduzido', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            disableAnimations: true,
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: HeroNatureza(aoAbrirMapa: () {}, aoAbrirAnimais: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('busca do catálogo filtra e limpa em tela pequena', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(),
        home: const Scaffold(body: AnimaisScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'onça');
    await tester.pumpAndSettle();
    expect(find.text('Onça-pintada'), findsOneWidget);
    expect(find.text('Arara-azul'), findsNothing);
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
