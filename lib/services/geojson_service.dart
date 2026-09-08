import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/bioma.dart';

/// Carrega os alertas de desmatamento do DETER-B/INPE.
///
/// O arquivo tem ~6,7 MB. Parsear isso na thread da UI trava a tela por
/// segundos — no navegador e no celular. Por isso o decode e o mapeamento
/// rodam num isolate (`compute`), que na web vira uma chamada assincrona
/// comum, mas mantem o codigo igual nos dois alvos.
class GeoJsonService {
  static const _caminho = 'assets/data/alertas-desmatamento.json';

  List<AlertaDesmatamento>? _cache;

  /// Le, parseia e devolve os alertas. Resultado fica em cache: trocar de aba
  /// e voltar nao paga o custo de novo.
  Future<List<AlertaDesmatamento>> carregar() async {
    final emCache = _cache;
    if (emCache != null) return emCache;

    final bruto = await rootBundle.loadString(_caminho);
    final alertas = await compute(_parsear, bruto);
    _cache = alertas;
    return alertas;
  }

  /// Roda fora da thread da UI.
  static List<AlertaDesmatamento> _parsear(String bruto) {
    final mapa = jsonDecode(bruto);
    if (mapa is! Map || mapa['features'] is! List) {
      return const <AlertaDesmatamento>[];
    }

    final out = <AlertaDesmatamento>[];
    for (final f in (mapa['features'] as List)) {
      if (f is! Map) continue;
      final alerta =
          AlertaDesmatamento.doGeoJson(Map<String, dynamic>.from(f));
      if (alerta != null) out.add(alerta);
    }
    return out;
  }
}
