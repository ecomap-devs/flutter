import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import 'package:ecomapbrasil/models/identificacao.dart';
import 'package:ecomapbrasil/screens/fotos_screen.dart';
import 'package:ecomapbrasil/services/identificacao_service.dart';

void main() {
  group('Identificacao.daResposta', () {
    test('lê nome popular, científico, confiança e descrição', () {
      final r = Identificacao.daResposta({
        'ehAnimal': true,
        'nomePopular': ' onça-pintada ',
        'nomeCientifico': 'Panthera onca',
        'confianca': 'alta',
        'descricao': 'Felino grande com rosetas pretas.',
      })!;

      expect(r.ehAnimal, isTrue);
      expect(r.nomePopular, 'onça-pintada');
      expect(r.nomeCientifico, 'Panthera onca');
      expect(r.confianca, Confianca.alta);
      expect(r.descricao, 'Felino grande com rosetas pretas.');
      expect(r.vazia, isFalse);
    });

    test('foto sem animal é vazia, não nula', () {
      final r = Identificacao.daResposta({
        'ehAnimal': false,
        'nomePopular': '',
        'nomeCientifico': '',
        'confianca': 'alta',
        'descricao': 'Uma paisagem.',
      });
      expect(r, isNotNull);
      expect(r!.vazia, isTrue);
      expect(r.nomePopular, isNull);
    });

    test('formato geral inválido devolve null', () {
      expect(Identificacao.daResposta(null), isNull);
      expect(Identificacao.daResposta('erro'), isNull);
      expect(Identificacao.daResposta([1, 2]), isNull);
      expect(Identificacao.daResposta({'nomePopular': 'onça'}), isNull);
      expect(Identificacao.daResposta({'ehAnimal': 'sim'}), isNull);
    });

    test('campo malformado vira null sem derrubar o resto', () {
      final r = Identificacao.daResposta({
        'ehAnimal': true,
        'nomePopular': 'tamanduá-bandeira',
        'nomeCientifico': 42,
        'confianca': 'certeza absoluta',
        'descricao': 'x' * 5000,
      })!;

      expect(r.nomePopular, 'tamanduá-bandeira');
      expect(r.nomeCientifico, isNull);
      // Confiança desconhecida não vira certeza: cai para baixa.
      expect(r.confianca, Confianca.baixa);
      // Texto sem fim é cortado para não estourar a tela.
      expect(r.descricao!.length, lessThanOrEqualTo(601));
      expect(r.vazia, isFalse);
    });

    test('animal sem nome conta como vazio', () {
      final r = Identificacao.daResposta({'ehAnimal': true})!;
      expect(r.vazia, isTrue);
      expect(r.confianca, Confianca.baixa);
    });
  });
  group('IdentificacaoService.mensagemDeErro', () {
    test('traduz o status da Edge Function', () {
      String msg(int status) => IdentificacaoService.mensagemDeErro(
        FunctionException(status: status),
      );
      expect(msg(401), contains('sessão expirou'));
      expect(msg(413), contains('grande demais'));
      expect(msg(0), contains('Sem conexão'));
      expect(msg(502), contains('Não foi possível identificar'));
    });

    test('mantém a mensagem própria e esconde erro desconhecido', () {
      expect(
        IdentificacaoService.mensagemDeErro(
          const IdentificacaoException('Mensagem pronta.'),
        ),
        'Mensagem pronta.',
      );
      expect(
        IdentificacaoService.mensagemDeErro(StateError('interno')),
        isNot(contains('interno')),
      );
    });
  });

  testWidgets('sem login, a tela de fotos pede para entrar', (tester) async {
    var pediu = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FotosScreen(usuario: null, aoPedirLogin: () => pediu++),
        ),
      ),
    );

    expect(find.text('Tirar foto'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    expect(pediu, 1);
  });
}
