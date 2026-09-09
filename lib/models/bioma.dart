import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

/// Bioma brasileiro, com o(s) poligono(s) simplificado(s) usados no mapa.
///
/// A Mata Atlantica e MultiPolygon na fonte — por isso `poligonos` e uma
/// lista de aneis, e nao um anel so.
@immutable
class Bioma {
  const Bioma({
    required this.nome,
    required this.areaKm2,
    required this.percentualDesmatado,
    required this.descricao,
    required this.poligonos,
  });

  final String nome;
  final int areaKm2;
  final int percentualDesmatado;
  final String descricao;
  final List<List<LatLng>> poligonos;

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

  /// Centro medio de todos os aneis — usado para posicionar o rotulo.
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

  /// Os pedacos do alerta, cada um um anel externo fechado.
  ///
  /// E lista de listas porque um alerta pode vir partido: uma area derrubada
  /// que o satelite enxerga como duas manchas separadas chega como
  /// `MultiPolygon`. Sao 1.756 dos 18.262 alertas do arquivo — e justamente os
  /// grandes, porque area grande e a que tem chance de se partir.
  final List<List<LatLng>> partes;

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
  /// Aneis internos (buracos) sao ignorados de proposito: 92 features os tem,
  /// e desenha-los pede outro campo no modelo. Fica para um PR proprio.
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

    final partes = <List<LatLng>>[];
    for (final poligono in poligonos) {
      if (poligono is! List || poligono.isEmpty) continue;
      final anel = poligono.first; // externo; os demais sao buracos
      if (anel is! List) continue;

      final pontos = <LatLng>[];
      for (final par in anel) {
        if (par is! List || par.length < 2) continue;
        final lng = par[0], lat = par[1];
        if (lng is! num || lat is! num) continue;
        pontos.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
      // Parte degenerada nao derruba o alerta inteiro: as outras podem valer.
      if (pontos.length >= 3) partes.add(pontos);
    }
    if (partes.isEmpty) return null;

    final p = (feature['properties'] as Map?) ?? const {};
    return AlertaDesmatamento(
      bioma: (p['BIOMA'] ?? 'Desconhecido').toString(),
      estado: (p['ESTADO'] ?? '').toString(),
      municipio: (p['MUNICIPIO'] ?? '').toString(),
      areaHa: (p['AREAHA'] as num?)?.toDouble() ?? 0,
      ano: (p['ANODETEC'] as num?)?.toInt() ?? 0,
      pressao: (p['VPRESSAO'] ?? '').toString(),
      partes: partes,
    );
  }
}
