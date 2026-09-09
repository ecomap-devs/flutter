import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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

    // `contem` é o que substituiu as etiquetas sobre o mapa. No celular não há
    // lista lateral, então sem isto não há como selecionar bioma nenhum.
    test('contem: o centro cai dentro, para bioma de uma peça só', () {
      final umaPeca = biomas.where((b) => b.poligonos.length == 1);
      expect(umaPeca, isNotEmpty);
      for (final b in umaPeca) {
        expect(b.contem(b.centro), isTrue, reason: b.nome);
      }
    });

    test('contem: o centro da Mata Atlântica cai FORA dela', () {
      // Não é defeito de `contem`, é o que `centro` é: média dos vértices de
      // todos os anéis. A Mata Atlântica tem três peças distantes — a faixa
      // costeira do Nordeste e o bloco Sudeste/Sul — e a média cai no vão
      // entre elas. Vale como aviso: `centro` serve de alvo de câmera, não
      // como ponto representativo do bioma.
      final ma = biomas.firstWhere((b) => b.nome == 'Mata Atlântica');
      expect(ma.poligonos, hasLength(3));
      expect(ma.contem(ma.centro), isFalse);
      // Mas um ponto real dentro da peça Sudeste/Sul é reconhecido.
      expect(ma.contem(const LatLng(-23.55, -46.63)), isTrue); // São Paulo
    });

    test('contem: ponto no Atlântico não cai em bioma nenhum', () {
      const altoMar = LatLng(-20, -25);
      for (final b in biomas) {
        expect(b.contem(altoMar), isFalse, reason: b.nome);
      }
    });

    // Os polígonos se sobrepõem, então "contém" não basta para escolher.
    test('maisEspecificoEm: São Paulo é Mata Atlântica, não Cerrado', () {
      const sp = LatLng(-23.55, -46.63);
      final donos = biomas.where((b) => b.contem(sp)).map((b) => b.nome);
      // A sobreposição é real: os dois contêm o ponto.
      expect(donos, containsAll(<String>['Cerrado', 'Mata Atlântica']));
      // E o Cerrado vem antes na lista, então pegar o primeiro daria errado.
      expect(Bioma.maisEspecificoEm(biomas, sp)?.nome, 'Mata Atlântica');
    });

    test('maisEspecificoEm: ponto no Atlântico não devolve bioma', () {
      expect(Bioma.maisEspecificoEm(biomas, const LatLng(-20, -25)), isNull);
    });

    test('maisEspecificoEm: o meio da Amazônia é Amazônia', () {
      expect(
        Bioma.maisEspecificoEm(biomas, const LatLng(-4, -63))?.nome,
        'Amazônia',
      );
    });

    test('contem: a Amazônia não engole um ponto do Sul', () {
      final amazonia = biomas.firstWhere((b) => b.nome == 'Amazônia');
      // Porto Alegre.
      expect(amazonia.contem(const LatLng(-30.03, -51.23)), isFalse);
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
      expect(a.partes, hasLength(1));
      // No GeoJSON a ordem é [lng, lat]; no LatLng é (lat, lng).
      expect(a.partes.first.first.latitude, closeTo(-6.71017, 0.00001));
      expect(a.partes.first.first.longitude, closeTo(-52.4897, 0.00001));
    });

    test('lê MultiPolygon e guarda uma parte por pedaço', () {
      // Regressão: até 09/09 este caso devolvia null e o mapa perdia 1.756
      // alertas — 25,4% da área desmatada do arquivo.
      final f = featureValida();
      f['geometry'] = {
        'type': 'MultiPolygon',
        'coordinates': [
          [
            [
              [-52.0, -6.0],
              [-52.1, -6.0],
              [-52.1, -6.1],
              [-52.0, -6.0],
            ],
          ],
          [
            [
              [-53.0, -7.0],
              [-53.1, -7.0],
              [-53.1, -7.1],
              [-53.0, -7.0],
            ],
          ],
        ],
      };
      final a = AlertaDesmatamento.doGeoJson(f);
      expect(a, isNotNull);
      expect(a!.partes, hasLength(2));
      expect(a.partes[1].first.longitude, closeTo(-53.0, 0.00001));
      // As propriedades continuam sendo as do alerta, não de cada pedaço.
      expect(a.areaHa, 71.63);
    });

    test('parte degenerada não derruba as outras do mesmo alerta', () {
      final f = featureValida();
      f['geometry'] = {
        'type': 'MultiPolygon',
        'coordinates': [
          [
            [
              [-52.0, -6.0],
              [-52.1, -6.1],
            ],
          ],
          [
            [
              [-53.0, -7.0],
              [-53.1, -7.0],
              [-53.1, -7.1],
              [-53.0, -7.0],
            ],
          ],
        ],
      };
      final a = AlertaDesmatamento.doGeoJson(f);
      expect(a, isNotNull);
      expect(a!.partes, hasLength(1));
    });

    test('devolve null para geometria que não é área', () {
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
      // Os testes rodam na VM (nao web), entao a chave cobrada e a do Android.
      expect(Env.faltando, contains('FIREBASE_API_KEY_ANDROID'));
      expect(Env.faltando, contains('SUPABASE_PUBLISHABLE_KEY'));
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
