import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

/// Bioma brasileiro, com o contorno oficial do IBGE simplificado para o mapa.
///
/// Quase todo bioma e MultiPolygon na fonte (ilhas, pedacos separados) — por
/// isso `poligonos` e uma lista de aneis, e nao um anel so.
@immutable
class Bioma {
  const Bioma({
    required this.nome,
    required this.areaKm2,
    required this.percentualDesmatado,
    required this.descricao,
    required this.poligonos,
    this.buracos = const [],
  });

  final String nome;
  final int areaKm2;
  final int percentualDesmatado;
  final String descricao;

  /// Os contornos externos de cada parte do bioma.
  final List<List<LatLng>> poligonos;

  /// Areas cercadas pelo bioma que o IBGE nao conta como bioma: as massas
  /// d'agua continentais, como a represa de Balbina, no meio da Amazonia. Um
  /// ponto aqui dentro NAO e do bioma.
  final List<List<LatLng>> buracos;

  Color get cor => AppCores.biomasMapa[nome] ?? AppCores.verde;

  String get areaFormatada {
    if (areaKm2 >= 1000000) {
      return '${(areaKm2 / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi km²';
    }
    final mil = (areaKm2 / 1000).round().toString();
    final comPonto = mil.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return '$comPonto mil km²';
  }

  /// O bioma mais especifico da lista que contem o ponto, ou `null`.
  ///
  /// Ate 01/10/2026 os poligonos eram retangulos herdados do React e se
  /// sobrepunham muito (Sao Paulo caia no Cerrado E na Mata Atlantica). Com o
  /// limite do IBGE quase nao ha sobreposicao, mas a simplificacao ainda deixa
  /// frestas e encostos de alguns quilometros na fronteira. Entao continua
  /// ganhando o **menor anel** que contem o ponto, que e o mais especifico, em
  /// vez do primeiro da lista — cuja ordem nao quer dizer nada.
  static Bioma? maisEspecificoEm(List<Bioma> lista, LatLng ponto) {
    Bioma? escolhido;
    var menorArea = double.infinity;
    for (final b in lista) {
      if (b._emBuraco(ponto)) continue;
      for (final anel in b.poligonos) {
        if (!_anelContem(anel, ponto)) continue;
        final area = _areaDoAnel(anel);
        if (area < menorArea) {
          menorArea = area;
          escolhido = b;
        }
      }
    }
    return escolhido;
  }

  /// Area do anel pela formula do cadarco, em graus quadrados.
  ///
  /// Nao serve como area de verdade (grau nao tem tamanho constante); serve
  /// para comparar dois aneis entre si, que e o uso aqui.
  static double _areaDoAnel(List<LatLng> anel) {
    var soma = 0.0;
    for (var i = 0, j = anel.length - 1; i < anel.length; j = i++) {
      soma +=
          (anel[j].longitude * anel[i].latitude) -
          (anel[i].longitude * anel[j].latitude);
    }
    return soma.abs() / 2;
  }

  /// O ponto caiu dentro deste bioma?
  ///
  /// E o que resolve o toque no mapa: no celular, que nao tem a lista
  /// lateral, tocar no bioma e o jeito principal de seleciona-lo.
  ///
  /// Algoritmo do raio: conta quantas vezes uma semirreta saindo do ponto
  /// cruza as arestas do anel. Impar = dentro. Sao cerca de mil vertices no
  /// total, entao roda a cada toque sem custo perceptivel.
  bool contem(LatLng ponto) {
    if (_emBuraco(ponto)) return false;
    for (final anel in poligonos) {
      if (_anelContem(anel, ponto)) return true;
    }
    return false;
  }

  bool _emBuraco(LatLng ponto) => buracos.any((b) => _anelContem(b, ponto));

  /// Os buracos que ficam dentro de um contorno — para desenhar cada parte
  /// com os seus. O gerador guarda os buracos numa lista so; como buraco de
  /// bioma nao cruza a borda, basta ver onde cai o primeiro ponto.
  List<List<LatLng>> buracosDe(List<LatLng> contorno) => [
    for (final b in buracos)
      if (b.isNotEmpty && _anelContem(contorno, b.first)) b,
  ];

  /// O retangulo que envolve todas as partes — para a camera enquadrar o
  /// bioma inteiro, do Pantanal a Amazonia, sem chutar zoom.
  LatLngBounds get limites =>
      LatLngBounds.fromPoints([for (final anel in poligonos) ...anel]);

  static bool _anelContem(List<LatLng> anel, LatLng p) {
    if (anel.length < 3) return false;
    var dentro = false;
    for (var i = 0, j = anel.length - 1; i < anel.length; j = i++) {
      final yi = anel[i].latitude, xi = anel[i].longitude;
      final yj = anel[j].latitude, xj = anel[j].longitude;
      // A aresta cruza a latitude do ponto? Se sim, o cruzamento esta a
      // direita dele?
      final cruza =
          (yi > p.latitude) != (yj > p.latitude) &&
          p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi) + xi;
      if (cruza) dentro = !dentro;
    }
    return dentro;
  }

  /// Centro medio de todos os aneis.
  LatLng get centro {
    var lat = 0.0, lng = 0.0, n = 0;
    for (final anel in poligonos) {
      for (final p in anel) {
        lat += p.latitude;
        lng += p.longitude;
        n++;
      }
    }
    if (n == 0) return const LatLng(-14, -52);
    return LatLng(lat / n, lng / n);
  }
}

/// Um pedaco de um alerta: o contorno externo e os buracos dentro dele.
@immutable
class ParteAlerta {
  const ParteAlerta({required this.contorno, this.buracos = const []});

  final List<LatLng> contorno;

  /// Aneis internos: areas dentro do contorno que NAO foram desmatadas.
  ///
  /// Ate 01/10/2026 eram descartados, e essas areas apareciam pintadas como
  /// afetadas — 104 buracos em 92 features do arquivo, divergindo da
  /// geometria original e do site (o Leaflet desenha os buracos).
  final List<List<LatLng>> buracos;
}

/// Poligono de alerta de desmatamento vindo do GeoJSON do DETER-B/INPE.
@immutable
class AlertaDesmatamento {
  const AlertaDesmatamento({
    required this.bioma,
    required this.estado,
    required this.municipio,
    required this.areaHa,
    required this.ano,
    required this.pressao,
    required this.partes,
  });

  final String bioma;
  final String estado;
  final String municipio;
  final double areaHa;
  final int ano;
  final String pressao;

  /// Os pedacos do alerta, cada um com o anel externo e os buracos.
  ///
  /// E lista de listas porque um alerta pode vir partido: uma area derrubada
  /// que o satelite enxerga como duas manchas separadas chega como
  /// `MultiPolygon`. Sao 1.756 dos 18.262 alertas do arquivo — e justamente os
  /// grandes, porque area grande e a que tem chance de se partir.
  final List<ParteAlerta> partes;

  /// Media dos vertices do primeiro contorno.
  ///
  /// Com o Brasil inteiro na tela, um alerta tem menos de um pixel e o
  /// poligono some; o mapa desenha um ponto aqui no lugar dele.
  LatLng get centro {
    final anel = partes.first.contorno;
    var lat = 0.0, lng = 0.0;
    for (final p in anel) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / anel.length, lng / anel.length);
  }

  /// Le uma `Feature` do GeoJSON. Aceita `Polygon` e `MultiPolygon`.
  ///
  /// Devolve `null` para geometria invalida em vez de estourar: o arquivo tem
  /// 6,7 MB e uma feature malformada nao pode derrubar o mapa inteiro.
  ///
  /// Ate 09/09/2026 esta funcao devolvia `null` para tudo que nao fosse
  /// `Polygon`, e `MultiPolygon` caiu nessa peneira. O mapa desenhava 16.506
  /// dos 18.262 alertas — **25,4% da area desmatada do arquivo nunca apareceu
  /// na tela**, e o contador do botao mostrava 16.506 como se fosse o total,
  /// entao a perda nao tinha como ser notada olhando.
  ///
  /// Uma propriedade com tipo inesperado (`AREAHA: "71.63"`, `properties: []`)
  /// tambem nao derruba nada: vira o valor padrao daquele campo.
  static AlertaDesmatamento? doGeoJson(Map<String, dynamic> feature) {
    final geometria = feature['geometry'];
    if (geometria is! Map) return null;

    final coords = geometria['coordinates'];
    if (coords is! List || coords.isEmpty) return null;

    // No GeoJSON um `Polygon` e uma lista de aneis e um `MultiPolygon` e uma
    // lista de poligonos. Normalizar para "lista de poligonos" deixa o resto
    // do codigo com um caminho so.
    final List<dynamic> poligonos = switch (geometria['type']) {
      'Polygon' => [coords],
      'MultiPolygon' => coords,
      _ => const [],
    };
    if (poligonos.isEmpty) return null;

    final partes = <ParteAlerta>[];
    for (final poligono in poligonos) {
      if (poligono is! List || poligono.isEmpty) continue;
      // O primeiro anel e o externo; os demais sao buracos.
      final contorno = _anel(poligono.first);
      // Parte degenerada nao derruba o alerta inteiro: as outras podem valer.
      if (contorno == null) continue;
      final buracos = [for (final anel in poligono.skip(1)) ?_anel(anel)];
      partes.add(ParteAlerta(contorno: contorno, buracos: buracos));
    }
    if (partes.isEmpty) return null;

    final bruto = feature['properties'];
    final p = bruto is Map ? bruto : const {};
    return AlertaDesmatamento(
      bioma: _texto(p['BIOMA'], 'Desconhecido'),
      estado: _texto(p['ESTADO'], ''),
      municipio: _texto(p['MUNICIPIO'], ''),
      areaHa: _numero(p['AREAHA'])?.toDouble() ?? 0,
      ano: _numero(p['ANODETEC'])?.toInt() ?? 0,
      pressao: _texto(p['VPRESSAO'], ''),
      partes: partes,
    );
  }

  /// Um anel do GeoJSON (`[[lng, lat], ...]`) com ao menos 3 pontos validos.
  static List<LatLng>? _anel(Object? anel) {
    if (anel is! List) return null;
    final pontos = <LatLng>[];
    for (final par in anel) {
      if (par is! List || par.length < 2) continue;
      final lng = par[0], lat = par[1];
      if (lng is! num || lat is! num) continue;
      if (lat.abs() > 90 || lng.abs() > 180) continue;
      pontos.add(LatLng(lat.toDouble(), lng.toDouble()));
    }
    return pontos.length >= 3 ? pontos : null;
  }

  static num? _numero(Object? valor) => switch (valor) {
    num n => n,
    String t => num.tryParse(t),
    _ => null,
  };

  static String _texto(Object? valor, String padrao) =>
      valor == null ? padrao : valor.toString();
}
