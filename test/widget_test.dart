import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/config/env.dart';
import 'package:ecomapbrasil/data/animais_data.dart';
import 'package:ecomapbrasil/data/biomas_data.dart';
import 'package:ecomapbrasil/main.dart';
import 'package:ecomapbrasil/models/animal.dart';
import 'package:ecomapbrasil/models/bioma.dart';
import 'package:ecomapbrasil/widgets/estrelas.dart';

void main() {
  group('Animal', () {
    test('variação percentual é negativa para espécie em declínio', () {
      final onca = animais.firstWhere((a) => a.nome == 'Onça-pintada');
      // 1200 -> 300 = -75%
      expect(onca.variacaoPercentual, closeTo(-75, 0.01));
      expect(onca.emRecuperacao, isFalse);
      expect(onca.variacaoFormatada, '-75%');
    });

    test('mico-leão-dourado é o único em recuperação no catálogo', () {
      final emAlta = animais.where((a) => a.emRecuperacao).toList();
      expect(emAlta, hasLength(1));
      expect(emAlta.single.nome, 'Mico-leão-dourado');
      expect(emAlta.single.variacaoFormatada, startsWith('+'));
    });

    test('série que começa em zero não divide por zero', () {
      const a = Animal(
        nome: 'Teste',
        status: 'Em perigo',
        bioma: 'Cerrado',
        regiao: 'Centro-Oeste',
        populacao: 10,
        tendencia: [0, 10],
        anos: ['2000', '2024'],
        descricao: '',
        imagem: '',
        ameacas: [],
      );
      expect(a.variacaoPercentual, 0);
    });

    test('população zero é rotulada como extinta na natureza', () {
      final ararinha = animais.firstWhere((a) => a.nome == 'Ararinha-azul');
      expect(ararinha.populacao, 0);
      expect(ararinha.populacaoFormatada, 'Extinta na natureza');
    });

    test('todo animal tem série e rótulos do mesmo tamanho', () {
      for (final a in animais) {
        expect(
          a.tendencia.length,
          a.anos.length,
          reason: '${a.nome} tem série e anos com tamanhos diferentes',
        );
      }
    });
  });

  group('Bioma', () {
    test('os seis biomas estão presentes', () {
      expect(biomas, hasLength(6));
      expect(
        biomas.map((b) => b.nome),
        containsAll(<String>[
          'Amazônia',
          'Cerrado',
          'Caatinga',
          'Mata Atlântica',
          'Pantanal',
          'Pampa',
        ]),
      );
    });

    test('Mata Atlântica preserva os três polígonos do MultiPolygon', () {
      final ma = biomas.firstWhere((b) => b.nome == 'Mata Atlântica');
      expect(ma.poligonos, hasLength(3));
    });

    test('todo anel é fechado e tem ao menos 3 pontos', () {
      for (final b in biomas) {
        for (final anel in b.poligonos) {
          expect(anel.length, greaterThanOrEqualTo(3), reason: b.nome);
          expect(anel.first, anel.last, reason: '${b.nome}: anel não fecha');
        }
      }
    });

    test('centro cai dentro do território brasileiro', () {
      for (final b in biomas) {
        expect(b.centro.latitude, inInclusiveRange(-34, 6), reason: b.nome);
        expect(b.centro.longitude, inInclusiveRange(-74, -34), reason: b.nome);
      }
    });

    test('área grande sai em milhões, área menor em milhares', () {
      final amazonia = biomas.firstWhere((b) => b.nome == 'Amazônia');
      final pantanal = biomas.firstWhere((b) => b.nome == 'Pantanal');
      expect(amazonia.areaFormatada, contains('mi km²'));
      expect(pantanal.areaFormatada, contains('mil km²'));
    });
  });

  group('AlertaDesmatamento.doGeoJson', () {
    Map<String, dynamic> featureValida() => {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-52.4897, -6.71017],
            [-52.49377, -6.71026],
            [-52.48901, -6.71604],
            [-52.4897, -6.71017],
          ],
        ],
      },
      'properties': {
        'BIOMA': 'Amazônia',
        'ESTADO': 'PARÁ',
        'MUNICIPIO': 'São Félix do Xingu',
        'AREAHA': 71.63,
        'ANODETEC': 2019,
        'VPRESSAO': 'agriculture',
      },
    };

    test('lê uma feature bem formada e inverte lng/lat para LatLng', () {
      final a = AlertaDesmatamento.doGeoJson(featureValida());
      expect(a, isNotNull);
      expect(a!.bioma, 'Amazônia');
      expect(a.municipio, 'São Félix do Xingu');
      expect(a.areaHa, 71.63);
      expect(a.ano, 2019);
      // No GeoJSON a ordem é [lng, lat]; no LatLng é (lat, lng).
      expect(a.poligono.first.latitude, closeTo(-6.71017, 0.00001));
      expect(a.poligono.first.longitude, closeTo(-52.4897, 0.00001));
    });

    test('devolve null em vez de estourar para geometria não-polígono', () {
      final f = featureValida();
      f['geometry'] = {
        'type': 'Point',
        'coordinates': <double>[-52.0, -6.0],
      };
      expect(AlertaDesmatamento.doGeoJson(f), isNull);
    });

    test('devolve null quando o anel tem menos de 3 pontos', () {
      final f = featureValida();
      f['geometry'] = {
        'type': 'Polygon',
        'coordinates': [
          [
            [-52.0, -6.0],
            [-52.1, -6.1],
          ],
        ],
      };
      expect(AlertaDesmatamento.doGeoJson(f), isNull);
    });

    test('sobrevive a properties ausente', () {
      final f = featureValida()..remove('properties');
      final a = AlertaDesmatamento.doGeoJson(f);
      expect(a, isNotNull);
      expect(a!.bioma, 'Desconhecido');
      expect(a.areaHa, 0);
    });
  });

  group('Env', () {
    test('sem --dart-define, reporta exatamente o que falta', () {
      // Os testes rodam sem env.json, então este é o caminho de falha real.
      expect(Env.completo, isFalse);
      expect(Env.faltando, contains('FIREBASE_API_KEY'));
      expect(Env.faltando, contains('SUPABASE_ANON_KEY'));
    });
  });

  group('Widgets', () {
    testWidgets('Estrelas pinta 5 ícones', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Estrelas(valor: 3, somenteLeitura: true)),
        ),
      );
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    });

    testWidgets('Estrelas somente leitura não dispara aoMudar', (tester) async {
      var chamou = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Estrelas(
              valor: 0,
              somenteLeitura: true,
              aoMudar: (_) => chamou = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star_rounded).first);
      await tester.pump();
      expect(chamou, isFalse);
    });

    testWidgets('Estrelas editável dispara aoMudar com a estrela tocada', (
      tester,
    ) async {
      var recebido = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Estrelas(valor: 0, aoMudar: (n) => recebido = n),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star_rounded).first);
      await tester.pump();
      expect(recebido, 1);
    });

    testWidgets('TelaDeConfiguracao lista as variáveis ausentes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const TelaDeConfiguracao(
          faltando: ['FIREBASE_API_KEY', 'SUPABASE_URL'],
        ),
      );

      expect(find.text('Faltam credenciais'), findsOneWidget);
      expect(find.text('FIREBASE_API_KEY'), findsOneWidget);
      expect(find.text('SUPABASE_URL'), findsOneWidget);
    });
  });
}
