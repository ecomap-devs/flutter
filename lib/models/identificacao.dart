import 'package:flutter/foundation.dart';

/// Rotulo que o Vision atribuiu a foto, com a confianca de 0 a 1.
@immutable
class Rotulo {
  const Rotulo({required this.descricao, required this.confianca});

  final String descricao;
  final double confianca;

  String get confiancaFormatada => '${(confianca * 100).round()}%';
}

/// Pagina da web onde a mesma imagem (ou uma muito parecida) aparece.
@immutable
class PaginaEncontrada {
  const PaginaEncontrada({required this.titulo, required this.url});

  final String titulo;
  final String url;

  /// "pt.wikipedia.org" — mais legivel que a URL inteira.
  String get dominio => Uri.tryParse(url)?.host ?? url;
}

/// O que o Google Cloud Vision encontrou sobre a foto de um animal.
///
/// Vem da Edge Function `identificar-animal`, que repassa `webDetection` e
/// `labelAnnotations` da resposta do Vision sem mexer.
@immutable
class Identificacao {
  const Identificacao({
    required this.palpite,
    required this.rotulos,
    required this.entidades,
    required this.paginas,
    required this.imagensParecidas,
  });

  /// O "melhor palpite" do Google para a imagem, ex.: "onça-pintada".
  final String? palpite;

  /// Rotulos gerais da foto ("Jaguar", "Felidae", "Wildlife"), em ingles.
  final List<Rotulo> rotulos;

  /// Entidades da web ligadas a imagem, ja na ordem de relevancia do Google.
  final List<String> entidades;

  final List<PaginaEncontrada> paginas;

  /// URLs de imagens visualmente parecidas.
  final List<String> imagensParecidas;

  bool get vazia =>
      palpite == null &&
      rotulos.isEmpty &&
      entidades.isEmpty &&
      paginas.isEmpty &&
      imagensParecidas.isEmpty;

  /// Le a resposta da Edge Function.
  ///
  /// Devolve `null` se o formato geral nao for o esperado. Item malformado
  /// dentro de uma lista e pulado, nao derruba o resto: um titulo de pagina
  /// estranho nao pode esconder o palpite.
  static Identificacao? daVision(Object? json) {
    if (json is! Map) return null;
    final web = json['webDetection'];
    final labels = json['labelAnnotations'];
    if (web != null && web is! Map) return null;
    if (labels != null && labels is! List) return null;
    final w = web as Map? ?? const {};

    String? palpite;
    for (final p in _lista(w['bestGuessLabels'])) {
      final texto = _texto(p['label']);
      if (texto != null) {
        palpite = texto;
        break;
      }
    }

    final rotulos = <Rotulo>[];
    for (final l in _lista(labels)) {
      final descricao = _texto(l['description']);
      final score = l['score'];
      if (descricao == null || score is! num) continue;
      rotulos.add(
        Rotulo(descricao: descricao, confianca: score.toDouble().clamp(0, 1)),
      );
    }

    final entidades = <String>[];
    for (final e in _lista(w['webEntities'])) {
      final descricao = _texto(e['description']);
      if (descricao != null && !entidades.contains(descricao)) {
        entidades.add(descricao);
      }
    }

    final paginas = <PaginaEncontrada>[];
    for (final p in _lista(w['pagesWithMatchingImages'])) {
      final url = _url(p['url']);
      if (url == null) continue;
      final titulo = _semHtml(_texto(p['pageTitle']) ?? '');
      paginas.add(
        PaginaEncontrada(
          titulo: titulo.isEmpty ? Uri.parse(url).host : titulo,
          url: url,
        ),
      );
    }

    // Imagens iguais primeiro, depois as parecidas; sem repetir.
    final imagens = <String>[];
    for (final chave in const [
      'fullMatchingImages',
      'partialMatchingImages',
      'visuallySimilarImages',
    ]) {
      for (final i in _lista(w[chave])) {
        final url = _url(i['url']);
        if (url != null && !imagens.contains(url)) imagens.add(url);
      }
    }

    return Identificacao(
      palpite: palpite,
      rotulos: List.unmodifiable(rotulos),
      entidades: List.unmodifiable(entidades),
      paginas: List.unmodifiable(paginas),
      imagensParecidas: List.unmodifiable(imagens),
    );
  }

  /// So os itens que sao mapas; o resto e ignorado.
  static Iterable<Map> _lista(Object? valor) =>
      valor is List ? valor.whereType<Map>() : const [];

  static String? _texto(Object? valor) {
    if (valor is! String) return null;
    final t = valor.trim();
    return t.isEmpty ? null : t;
  }

  /// Aceita so http(s): a URL vai para `Image.network` e para a tela.
  static String? _url(Object? valor) {
    final texto = _texto(valor);
    if (texto == null) return null;
    final uri = Uri.tryParse(texto);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return texto;
  }

  /// O Vision devolve o titulo com o termo buscado em `<b>...</b>`.
  static String _semHtml(String texto) => texto
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .trim();
}
