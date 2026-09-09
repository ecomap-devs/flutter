import 'package:flutter/material.dart';

/// Paleta herdada da versao React (verde #16a34a como cor de acao).
class AppCores {
  const AppCores._();

  static const verde = Color(0xFF16A34A);
  static const verdeClaro = Color(0xFF4ADE80);
  static const verdeFundo = Color(0xFFF0FDF4);

  static const texto = Color(0xFF111111);
  static const textoSuave = Color(0xFF6B7280);
  static const textoMedio = Color(0xFF374151);
  static const borda = Color(0xFFE5E7EB);
  static const fundo = Color(0xFFF8FAFC);

  static const erroFundo = Color(0xFFFEF2F2);
  static const erroBorda = Color(0xFFFECACA);
  static const erroTexto = Color(0xFFDC2626);

  static const sucessoFundo = Color(0xFFF0FDF4);
  static const sucessoBorda = Color(0xFFBBF7D0);

  static const estrela = Color(0xFFF59E0B);

  /// Cores do mapa — as mesmas do `biomeColors` do Mapa.jsx.
  static const biomasMapa = <String, Color>{
    'Amazônia': Color(0xFF0D5016),
    'Cerrado': Color(0xFFD4A017),
    'Caatinga': Color(0xFFFF6B35),
    'Mata Atlântica': Color(0xFF4169E1),
    'Pantanal': Color(0xFF8B4513),
    'Pampa': Color(0xFF32CD32),
  };

  /// Cores dos graficos da Home — deliberadamente diferentes das do mapa,
  /// como na versao React.
  static const biomasGrafico = <String, Color>{
    'Amazônia': Color(0xFF16A34A),
    'Cerrado': Color(0xFFCA8A04),
    'Mata Atlântica': Color(0xFF3B82F6),
    'Caatinga': Color(0xFFF97316),
    'Pantanal': Color(0xFFB45309),
    'Pampa': Color(0xFF4ADE80),
  };

  static const statusFundo = <String, Color>{
    'Criticamente ameaçada': Color(0xFFFEE2E2),
    'Em perigo': Color(0xFFFEF3C7),
    'Vulnerável': Color(0xFFFEF9C3),
    'Extinta na natureza': Color(0xFFF3F4F6),
  };

  static const statusTexto = <String, Color>{
    'Criticamente ameaçada': Color(0xFF991B1B),
    'Em perigo': Color(0xFF92400E),
    'Vulnerável': Color(0xFF854D0E),
    'Extinta na natureza': Color(0xFF374151),
  };
}

/// Larguras de quebra herdadas do `useWindowSize()` da versao React.
class Breakpoints {
  const Breakpoints._();
  static const mobile = 768.0;
  static const tablet = 1024.0;

  static bool ehMobile(BuildContext c) => MediaQuery.sizeOf(c).width < mobile;
  static bool ehTablet(BuildContext c) {
    final l = MediaQuery.sizeOf(c).width;
    return l >= mobile && l < tablet;
  }
}

ThemeData construirTema() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppCores.verde,
      primary: AppCores.verde,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppCores.fundo,
    fontFamily: 'Segoe UI',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF052E16),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 70,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppCores.textoMedio,
      displayColor: AppCores.texto,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppCores.borda, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppCores.borda, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppCores.verde, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppCores.verde,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF86EFAC),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
