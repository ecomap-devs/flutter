import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ecomapbrasil/config/env.dart';
import 'package:ecomapbrasil/data/animais_data.dart';
import 'package:ecomapbrasil/data/biomas_data.dart';
import 'package:ecomapbrasil/main.dart';
import 'package:ecomapbrasil/models/animal.dart';
import 'package:ecomapbrasil/models/avaliacao.dart';
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

    test('todo bioma tem ao menos uma parte', () {
      for (final b in biomas) {
        expect(b.poligonos, isNotEmpty, reason: b.nome);
      }
    });

    test(
      'todo anel, contorno ou buraco, é fechado e tem ao menos 3 pontos',
      () {
        for (final b in biomas) {
          for (final anel in [...b.poligonos, ...b.buracos]) {
            expect(anel.length, greaterThanOrEqualTo(3), reason: b.nome);
            expect(anel.first, anel.last, reason: '${b.nome}: anel não fecha');
          }
        }
      },
    );

    test('centro cai dentro do território brasileiro', () {
      for (final b in biomas) {
        expect(b.centro.latitude, inInclusiveRange(-34, 6), reason: b.nome);
        expect(b.centro.longitude, inInclusiveRange(-74, -34), reason: b.nome);
      }
    });

    test('limites envolvem todas as partes do bioma', () {
      for (final b in biomas) {
        for (final anel in b.poligonos) {
          for (final p in anel) {
            expect(b.limites.contains(p), isTrue, reason: b.nome);
          }
        }
      }
    });

    test('área grande sai em milhões, área menor em milhares', () {
      final amazonia = biomas.firstWhere((b) => b.nome == 'Amazônia');
      final pantanal = biomas.firstWhere((b) => b.nome == 'Pantanal');
      expect(amazonia.areaFormatada, contains('mi km²'));
      expect(pantanal.areaFormatada, contains('mil km²'));
    });

    // Com o limite do IBGE, cada cidade abaixo cai em um bioma só. Com os
    // retângulos antigos, São Paulo caía no Cerrado e na Mata Atlântica.
    const cidades = {
      // Manaus fica na margem do rio, que o IBGE separa como massa d'água;
      // por isso o ponto da Amazônia é no interior, longe da calha.
      'Interior do Amazonas': (LatLng(-6.00, -60.00), 'Amazônia'),
      'Brasília': (LatLng(-15.79, -47.88), 'Cerrado'),
      'Salgueiro (PE)': (LatLng(-8.07, -39.12), 'Caatinga'),
      'São Paulo': (LatLng(-23.55, -46.63), 'Mata Atlântica'),
      'Nhecolândia (MS)': (LatLng(-18.90, -56.60), 'Pantanal'),
      'Bagé (RS)': (LatLng(-31.33, -54.10), 'Pampa'),
    };

    test('contem: cada cidade cai no seu bioma, e só nele', () {
      for (final MapEntry(key: cidade, value: (ponto, esperado))
          in cidades.entries) {
        final donos = biomas.where((b) => b.contem(ponto)).map((b) => b.nome);
        expect(donos, [esperado], reason: cidade);
      }
    });

    test('maisEspecificoEm: cada cidade devolve o seu bioma', () {
      for (final MapEntry(key: cidade, value: (ponto, esperado))
          in cidades.entries) {
        expect(
          Bioma.maisEspecificoEm(biomas, ponto)?.nome,
          esperado,
          reason: cidade,
        );
      }
    });

    test('contem: ponto no Atlântico não cai em bioma nenhum', () {
      const altoMar = LatLng(-20, -25);
      for (final b in biomas) {
        expect(b.contem(altoMar), isFalse, reason: b.nome);
      }
    });

    test('maisEspecificoEm: ponto no Atlântico não devolve bioma', () {
      expect(Bioma.maisEspecificoEm(biomas, const LatLng(-20, -25)), isNull);
    });

    test('contem: a Amazônia não engole um ponto do Sul', () {
      final amazonia = biomas.firstWhere((b) => b.nome == 'Amazônia');
      // Porto Alegre.
      expect(amazonia.contem(const LatLng(-30.03, -51.23)), isFalse);
    });

    // O IBGE tira as massas d'água dos biomas, e a represa de Balbina vira um
    // buraco na Amazônia. Ponto no buraco não é do bioma, nem para `contem`
    // nem para `maisEspecificoEm`.
    test('buraco: ponto no buraco não pertence ao bioma que o cerca', () {
      const externo = [
        LatLng(0, 0),
        LatLng(0, 10),
        LatLng(-10, 10),
        LatLng(-10, 0),
        LatLng(0, 0),
      ];
      const buraco = [
        LatLng(-4, 4),
        LatLng(-4, 6),
        LatLng(-6, 6),
        LatLng(-6, 4),
        LatLng(-4, 4),
      ];
      const b = Bioma(
        nome: 'Teste',
        areaKm2: 1,
        percentualDesmatado: 0,
        descricao: '',
        poligonos: [externo],
        buracos: [buraco],
      );
      expect(b.contem(const LatLng(-5, 5)), isFalse);
      expect(b.contem(const LatLng(-2, 2)), isTrue);
      expect(Bioma.maisEspecificoEm([b], const LatLng(-5, 5)), isNull);
      expect(b.buracosDe(externo), [buraco]);
      expect(b.buracosDe(buraco), isEmpty);
    });

    test("a Amazônia traz a massa d'água do IBGE como buraco", () {
      final amazonia = biomas.firstWhere((b) => b.nome == 'Amazônia');
      expect(amazonia.buracos, isNotEmpty);
      // E o desenho acha o contorno de cada buraco.
      final ligados = [
        for (final c in amazonia.poligonos) ...amazonia.buracosDe(c),
      ];
      expect(ligados, hasLength(amazonia.buracos.length));
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
      expect(
        a.partes.first.contorno.first.latitude,
        closeTo(-6.71017, 0.00001),
      );
      expect(
        a.partes.first.contorno.first.longitude,
        closeTo(-52.4897, 0.00001),
      );
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
      expect(a.partes[1].contorno.first.longitude, closeTo(-53.0, 0.00001));
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

    // Revisão de 01/10/2026: 92 features do arquivo têm buracos, e eles eram
    // descartados — a área de dentro aparecia pintada como desmatada.
    test('guarda os anéis internos como buracos', () {
      final f = featureValida();
      (f['geometry'] as Map)['coordinates'] = [
        [
          [-53.0, -7.0],
          [-52.0, -7.0],
          [-52.0, -6.0],
          [-53.0, -6.0],
          [-53.0, -7.0],
        ],
        [
          [-52.7, -6.7],
          [-52.3, -6.7],
          [-52.3, -6.3],
          [-52.7, -6.7],
        ],
      ];
      final a = AlertaDesmatamento.doGeoJson(f);
      expect(a!.partes.single.contorno, hasLength(5));
      expect(a.partes.single.buracos, hasLength(1));
      expect(
        a.partes.single.buracos.single.first.longitude,
        closeTo(-52.7, 1e-9),
      );
    });

    test('properties em formato errado não derruba a feature', () {
      final lista = featureValida()..['properties'] = <Object>[];
      expect(AlertaDesmatamento.doGeoJson(lista)?.bioma, 'Desconhecido');

      final texto = featureValida();
      (texto['properties'] as Map)['AREAHA'] = '71.63';
      (texto['properties'] as Map)['ANODETEC'] = 'dois mil';
      final a = AlertaDesmatamento.doGeoJson(texto);
      expect(a!.areaHa, closeTo(71.63, 1e-9));
      expect(a.ano, 0);
    });
  });

  group('tempoRelativoDesde', () {
    final agora = DateTime(2026, 10, 1, 12);
    String ha(Duration d) => tempoRelativoDesde(agora.subtract(d), agora);

    test('minutos, horas e dias', () {
      expect(ha(const Duration(seconds: 30)), 'agora mesmo');
      expect(ha(const Duration(minutes: 5)), 'há 5 min');
      expect(ha(const Duration(hours: 3)), 'há 3h');
      expect(ha(const Duration(days: 1)), 'há 1 dia');
    });

    // Revisão de 01/10/2026: entre 28 e 29 dias aparecia "há 0 mês".
    test('28 e 29 dias continuam em semanas', () {
      expect(ha(const Duration(days: 28)), 'há 4 semanas');
      expect(ha(const Duration(days: 29)), 'há 4 semanas');
      expect(ha(const Duration(days: 30)), 'há 1 mês');
      expect(ha(const Duration(days: 400)), 'há 1 ano');
    });
  });

  group('fotoConfiavel', () {
    test('aceita só o bucket de avatares do projeto', () {
      const nova = '${prefixoAvatares}abc/0f8e2c1a.webp';
      const antiga = '${prefixoAvatares}abc.png';
      expect(fotoConfiavel(nova), nova);
      expect(fotoConfiavel(antiga), antiga);
      expect(fotoConfiavel('https://rastreador.exemplo/pixel.png'), '');
      expect(fotoConfiavel(123), '');
      expect(fotoConfiavel(null), '');
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
