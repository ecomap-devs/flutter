import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import 'package:ecomapbrasil/models/identificacao.dart';
import 'package:ecomapbrasil/screens/fotos_screen.dart';
import 'package:ecomapbrasil/services/identificacao_service.dart';

void main() {
  group('Identificacao.daVision', () {
    test('lê palpite, rótulos, entidades, páginas e imagens', () {
      final r = Identificacao.daVision({
        'webDetection': {
          'bestGuessLabels': [
            {'label': 'onça-pintada', 'languageCode': 'pt'},
          ],
          'webEntities': [
            {'entityId': '/m/1', 'score': 1.4, 'description': 'Jaguar'},
            {'entityId': '/m/2', 'score': 0.8, 'description': 'Felidae'},
          ],
          'pagesWithMatchingImages': [
            {
              'url': 'https://pt.wikipedia.org/wiki/Onça-pintada',
              'pageTitle': '<b>Onça</b>-pintada &amp; Cia',
            },
          ],
          'fullMatchingImages': [
            {'url': 'https://exemplo.org/a.jpg'},
          ],
          'visuallySimilarImages': [
            {'url': 'https://exemplo.org/a.jpg'},
            {'url': 'https://exemplo.org/b.jpg'},
          ],
        },
        'labelAnnotations': [
          {'description': 'Jaguar', 'score': 0.973},
        ],
      })!;

      expect(r.palpite, 'onça-pintada');
      expect(r.entidades, ['Jaguar', 'Felidae']);
      expect(r.rotulos.single.descricao, 'Jaguar');
      expect(r.rotulos.single.confiancaFormatada, '97%');
      expect(r.paginas.single.titulo, 'Onça-pintada & Cia');
      expect(r.paginas.single.dominio, 'pt.wikipedia.org');
      // Imagem repetida entre as listas aparece uma vez só.
      expect(r.imagensParecidas, [
        'https://exemplo.org/a.jpg',
        'https://exemplo.org/b.jpg',
      ]);
      expect(r.vazia, isFalse);
    });

    test('resposta sem nada encontrado é vazia, não nula', () {
      final r = Identificacao.daVision({
        'webDetection': <String, dynamic>{},
        'labelAnnotations': <dynamic>[],
      });
      expect(r, isNotNull);
      expect(r!.vazia, isTrue);
    });

    test('formato geral inválido devolve null', () {
      expect(Identificacao.daVision(null), isNull);
      expect(Identificacao.daVision('erro'), isNull);
      expect(Identificacao.daVision([1, 2]), isNull);
      expect(Identificacao.daVision({'webDetection': 'x'}), isNull);
      expect(Identificacao.daVision({'labelAnnotations': {}}), isNull);
    });

    test('item malformado é pulado sem derrubar o resto', () {
      final r = Identificacao.daVision({
        'webDetection': {
          'bestGuessLabels': [
            'texto solto',
            {'label': '   '},
            {'label': 'tamanduá-bandeira'},
          ],
          'pagesWithMatchingImages': [
            {'url': 'javascript:alert(1)', 'pageTitle': 'ruim'},
            {'url': 'nao é url'},
            {'pageTitle': 'sem url'},
            {'url': 'https://exemplo.org/p', 'pageTitle': 42},
          ],
          'visuallySimilarImages': [
            {'url': 'file:///etc/passwd'},
            {'url': 'http://exemplo.org/c.png'},
          ],
        },
        'labelAnnotations': [
          {'description': 'Anteater'},
          {'score': 0.9},
          {'description': 'Mammal', 'score': 1.7},
        ],
      })!;

      expect(r.palpite, 'tamanduá-bandeira');
      // Sem título legível, a página cai no domínio.
      expect(r.paginas.single.titulo, 'exemplo.org');
      expect(r.imagensParecidas, ['http://exemplo.org/c.png']);
      expect(r.rotulos.single.descricao, 'Mammal');
      expect(r.rotulos.single.confianca, 1);
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
