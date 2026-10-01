import 'package:flutter/foundation.dart';

/// Quanta certeza o Gemini declarou ter na identificacao.
enum Confianca {
  alta('Alta confiança'),
  media('Confiança média'),
  baixa('Baixa confiança');

  const Confianca(this.rotulo);

  final String rotulo;

  static Confianca? deTexto(Object? valor) => switch (valor) {
    'alta' => alta,
    'media' => media,
    'baixa' => baixa,
    _ => null,
  };
}

/// O que o Gemini concluiu sobre a foto de um animal.
///
/// Vem da Edge Function `identificar-animal`, que repassa o JSON do Gemini
/// (gerado num esquema fixo) sem mexer.
@immutable
class Identificacao {
  const Identificacao({
    required this.ehAnimal,
    required this.nomePopular,
    required this.nomeCientifico,
    required this.confianca,
    required this.descricao,
  });

  /// `false` quando a foto nao tem animal (pessoa, objeto, paisagem).
  final bool ehAnimal;

  /// Nome popular no Brasil, ex.: "onça-pintada".
  final String? nomePopular;

  final String? nomeCientifico;
  final Confianca confianca;

  /// Ate duas frases sobre o que se ve na foto.
  final String? descricao;

  /// Nada a mostrar como identificacao: sem animal ou sem nome.
  bool get vazia => !ehAnimal || nomePopular == null;

  /// Le a resposta da Edge Function.
  ///
  /// Devolve `null` se o formato geral nao for o esperado. Campo de texto
  /// ausente ou estranho vira `null` e nao derruba o resto: sem nome
  /// cientifico, o nome popular ainda vale.
  static Identificacao? daResposta(Object? json) {
    if (json is! Map) return null;
    final ehAnimal = json['ehAnimal'];
    if (ehAnimal is! bool) return null;

    return Identificacao(
      ehAnimal: ehAnimal,
      nomePopular: _texto(json['nomePopular'], 120),
      nomeCientifico: _texto(json['nomeCientifico'], 120),
      // Confianca desconhecida conta como baixa: melhor subestimar que
      // vender certeza que o modelo nao declarou.
      confianca: Confianca.deTexto(json['confianca']) ?? Confianca.baixa,
      descricao: _texto(json['descricao'], 600),
    );
  }

  /// Texto limpo e com teto de tamanho: a resposta vem de um modelo, e um
  /// texto sem fim nao pode empurrar o resto da tela para fora.
  static String? _texto(Object? valor, int maximo) {
    if (valor is! String) return null;
    final t = valor.trim();
    if (t.isEmpty) return null;
    return t.length <= maximo ? t : '${t.substring(0, maximo).trimRight()}…';
  }
}
