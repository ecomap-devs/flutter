import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/screens/mapa_screen.dart';

void main() {
  // Os enderecos de todas as camadas de fundo, na ordem em que sao desenhadas.
  String fundos(WidgetTester tester) => tester
      .widgetList<TileLayer>(find.byType(TileLayer))
      .map((t) => t.urlTemplate)
      .join(' | ');

  testWidgets('o botão alterna o fundo entre mapa claro e satélite', (
    tester,
  ) async {
    // Tamanho de celular: o layout muda (sem lista lateral, legenda larga), e
    // foi no celular que o botão pareceu não funcionar.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MapaScreen())),
    );
    await tester.pump();

    expect(fundos(tester), contains('World_Light_Gray_Base'));
    expect(fundos(tester), isNot(contains('World_Imagery')));
    final camadasAntes = tester.stateList(find.byType(TileLayer)).toSet();

    await tester.tap(find.text('Satélite'));
    await tester.pump();
    expect(fundos(tester), contains('World_Imagery'));
    expect(fundos(tester), isNot(contains('Light_Gray')));
    // As camadas sao NOVAS, nao as antigas com outro endereco: recarregar no
    // lugar foi o que nao redesenhava a imagem no celular.
    final camadasDepois = tester.stateList(find.byType(TileLayer)).toSet();
    expect(camadasDepois.intersection(camadasAntes), isEmpty);

    await tester.tap(find.text('Mapa'));
    await tester.pump();
    expect(fundos(tester), contains('World_Light_Gray_Base'));
    expect(fundos(tester), isNot(contains('World_Imagery')));
  });
}
