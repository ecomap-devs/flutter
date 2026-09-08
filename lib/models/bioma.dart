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
    required this.poligono,
  });

  final String bioma;
  final String estado;
  final String municipio;
  final double areaHa;
  final int ano;
  final String pressao;
  final List<LatLng> poligono;

  /// Le uma `Feature` do GeoJSON.
  ///
  /// Devolve `null` para geometria invalida em vez de estourar: o arquivo tem
  /// 6,7 MB e uma feature malformada nao pode derrubar o mapa inteiro.
  static AlertaDesmatamento? doGeoJson(Map<String, dynamic> feature) {
    final geometria = feature['geometry'];
    if (geometria is! Map || geometria['type'] != 'Polygon') return null;

    final coords = geometria['coordinates'];
    if (coords is! List || coords.isEmpty) return null;

    final anel = coords.first;
    if (anel is! List || anel.length < 3) return null;

    final pontos = <LatLng>[];
    for (final par in anel) {
      if (par is! List || par.length < 2) continue;
      final lng = par[0], lat = par[1];
      if (lng is! num || lat is! num) continue;
      pontos.add(LatLng(lat.toDouble(), lng.toDouble()));
    }
    if (pontos.length < 3) return null;

    final p = (feature['properties'] as Map?) ?? const {};
    return AlertaDesmatamento(
      bioma: (p['BIOMA'] ?? 'Desconhecido').toString(),
      estado: (p['ESTADO'] ?? '').toString(),
      municipio: (p['MUNICIPIO'] ?? '').toString(),
      areaHa: (p['AREAHA'] as num?)?.toDouble() ?? 0,
      ano: (p['ANODETEC'] as num?)?.toInt() ?? 0,
      pressao: (p['VPRESSAO'] ?? '').toString(),
      poligono: pontos,
    );
  }
}
