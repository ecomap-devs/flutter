import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Especie ameacada do catalogo.
///
/// Campos espelham `allAnimals` do Animais.jsx.
@immutable
class Animal {
  const Animal({
    required this.nome,
    required this.status,
    required this.bioma,
    required this.regiao,
    required this.populacao,
    required this.descricao,
    required this.imagem,
    required this.tendencia,
    required this.anos,
    required this.ameacas,
  });

  final String nome;
  final String status;
  final String bioma;
  final String regiao;

  /// Populacao estimada atual, em individuos.
  final int populacao;
  final String descricao;
  final String imagem;

  /// Serie populacional por ano, para o grafico de tendencia.
  final List<int> tendencia;
  final List<String> anos;
  final List<String> ameacas;

  Color get corStatusFundo => AppCores.statusFundo[status] ?? AppCores.borda;
  Color get corStatusTexto => AppCores.statusTexto[status] ?? AppCores.textoMedio;
  Color get corBioma => AppCores.biomasMapa[bioma] ?? AppCores.verde;

  /// Variacao do primeiro ao ultimo ano da serie, em %. Negativo = declinio.
  double get variacaoPercentual {
    if (tendencia.length < 2) return 0;
    final inicio = tendencia.first;
    if (inicio == 0) return 0;
    return ((tendencia.last - inicio) / inicio) * 100;
  }

  /// `true` quando a serie termina acima de onde comecou — caso do
  /// mico-leao-dourado, o unico do catalogo em recuperacao.
  bool get emRecuperacao => variacaoPercentual > 0;

  String get variacaoFormatada {
    final v = variacaoPercentual;
    final sinal = v > 0 ? '+' : '';
    return '$sinal${v.toStringAsFixed(0)}%';
  }

  String get populacaoFormatada {
    if (populacao == 0) return 'Extinta na natureza';
    if (populacao >= 1000) {
      final milhares = populacao / 1000;
      final txt = milhares.toStringAsFixed(milhares.truncateToDouble() == milhares ? 0 : 1);
      return '$txt mil indivíduos'.replaceAll('.', ',');
    }
    return '$populacao indivíduos';
  }
}
