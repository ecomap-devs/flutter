import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/biomas_data.dart';
import '../models/bioma.dart';
import '../services/geojson_service.dart';
import '../theme/app_theme.dart';

/// Mapa interativo dos biomas — porte do Mapa.jsx.
///
/// `flutter_map` e o irmao do Leaflet no Flutter: mesma ideia de camadas
/// sobre tiles, e roda igual na web e no celular. Os tiles de satelite sao os
/// mesmos da versao React (ArcGIS World Imagery).
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _mapa = MapController();
  final _geo = GeoJsonService();

  late Future<List<AlertaDesmatamento>> _alertas;

  Bioma? _selecionado;
  bool _mostrarAlertas = true;

  @override
  void initState() {
    super.initState();
    _alertas = _geo.carregar();
  }

  /// Selecao vinda da lista lateral: aproxima o mapa no bioma escolhido.
  void _selecionar(Bioma b) {
    setState(() => _selecionado = b);
    _mapa.move(b.centro, 5);
  }

  /// Toque no mapa: seleciona o bioma sob o dedo, ou limpa se caiu fora.
  ///
  /// Substitui as etiquetas que ficavam sobre o mapa. No React o clique
  /// tambem dava `fitBounds`; aqui a camera fica parada, porque mover o mapa
  /// a cada toque atrapalha quem so quer ler a ficha — quem quer aproximar
  /// clica na lista.
  void _tocarNoMapa(LatLng ponto) {
    Bioma? achado;
    for (final b in biomas) {
      if (b.contem(ponto)) {
        achado = b;
        break;
      }
    }
    if (achado != _selecionado) setState(() => _selecionado = achado);
  }

  @override
  Widget build(BuildContext context) {
    final ehMobile = Breakpoints.ehMobile(context);

    final mapa = FutureBuilder<List<AlertaDesmatamento>>(
      future: _alertas,
      builder: (context, snap) {
        final alertas = snap.data ?? const <AlertaDesmatamento>[];

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: const LatLng(-14, -52),
                initialZoom: ehMobile ? 3.4 : 4,
                minZoom: 2,
                maxZoom: 12,
                onTap: (_, ponto) => _tocarNoMapa(ponto),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/'
                      'World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'br.com.ecomapbrasil',
                ),
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/'
                      'Reference/World_Boundaries_and_Places/MapServer/'
                      'tile/{z}/{y}/{x}',
                  userAgentPackageName: 'br.com.ecomapbrasil',
                ),

                // Os biomas nao sao desenhados. Era assim no React
                // (`opacity: 0, fillOpacity: 0`): o mapa mostra os alertas
                // vermelhos, e mais nada. Os poligonos continuam existindo em
                // `biomas_data.dart`, mas so como area de toque — quem resolve
                // isso e `Bioma.contem`, no `onTap` do mapa, entao nao ha
                // camada nenhuma para eles aqui.
                //
                // O ganho nao e so estetico: o preenchimento de 28% de alpha
                // cobria o pais inteiro e abafava justamente o vermelho.
                if (_mostrarAlertas && alertas.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      for (final a in alertas)
                        for (final parte in a.partes)
                          Polygon(
                            points: parte,
                            color: const Color(0xFFDC2626)
                                .withValues(alpha: 0.55),
                            borderColor: const Color(0xFFEF4444),
                            borderStrokeWidth: 0.4,
                          ),
                    ],
                  ),
              ],
            ),

            if (snap.connectionState == ConnectionState.waiting)
              const Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(child: _Chip('Carregando alertas...')),
              ),

            if (snap.hasError)
              const Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: _Chip('Não foi possível carregar os alertas'),
                ),
              ),

            if (snap.connectionState == ConnectionState.done && !snap.hasError)
              Positioned(
                top: 12,
                right: 12,
                child: _BotaoAlertas(
                  ativo: _mostrarAlertas,
                  total: alertas.length,
                  aoTocar: () =>
                      setState(() => _mostrarAlertas = !_mostrarAlertas),
                ),
              ),

            if (_selecionado != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _FichaBioma(
                  bioma: _selecionado!,
                  aoFechar: () => setState(() => _selecionado = null),
                ),
              ),
          ],
        );
      },
    );

    if (ehMobile) return mapa;

    return Row(
      children: [
        SizedBox(
          width: 260,
          child: _ListaBiomas(
            selecionado: _selecionado,
            aoSelecionar: _selecionar,
          ),
        ),
        const VerticalDivider(width: 1, color: AppCores.borda),
        Expanded(child: mapa),
      ],
    );
  }
}

class _ListaBiomas extends StatelessWidget {
  const _ListaBiomas({required this.selecionado, required this.aoSelecionar});

  final Bioma? selecionado;
  final ValueChanged<Bioma> aoSelecionar;

  @override
  Widget build(BuildContext context) => Container(
    color: AppCores.fundo,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'BIOMAS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppCores.verde,
          ),
        ),
        const SizedBox(height: 12),
        for (final b in biomas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => aoSelecionar(b),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selecionado?.nome == b.nome
                      ? AppCores.verdeFundo
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selecionado?.nome == b.nome
                        ? AppCores.verde
                        : AppCores.borda,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: b.cor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b.nome,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppCores.texto,
                        ),
                      ),
                    ),
                    Text(
                      '${b.percentualDesmatado}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppCores.erroTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _FichaBioma extends StatelessWidget {
  const _FichaBioma({required this.bioma, required this.aoFechar});

  final Bioma bioma;
  final VoidCallback aoFechar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: bioma.cor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                bioma.nome,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppCores.texto,
                ),
              ),
            ),
            IconButton(
              onPressed: aoFechar,
              icon: const Icon(Icons.close, size: 18),
              color: AppCores.textoSuave,
              tooltip: 'Fechar',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          bioma.descricao,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppCores.textoSuave,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Metrica(
                rotulo: 'Área original',
                valor: bioma.areaFormatada,
                cor: AppCores.texto,
              ),
            ),
            Expanded(
              child: _Metrica(
                rotulo: 'Desmatado',
                valor: '${bioma.percentualDesmatado}%',
                cor: AppCores.erroTexto,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: bioma.percentualDesmatado / 100,
            minHeight: 8,
            backgroundColor: AppCores.borda,
            valueColor: const AlwaysStoppedAnimation(AppCores.erroTexto),
          ),
        ),
      ],
    ),
  );
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.rotulo,
    required this.valor,
    required this.cor,
  });

  final String rotulo;
  final String valor;
  final Color cor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        rotulo,
        style: const TextStyle(fontSize: 11, color: AppCores.textoSuave),
      ),
      const SizedBox(height: 2),
      Text(
        valor,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cor),
      ),
    ],
  );
}

class _BotaoAlertas extends StatelessWidget {
  const _BotaoAlertas({
    required this.ativo,
    required this.total,
    required this.aoTocar,
  });

  final bool ativo;
  final int total;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    elevation: 3,
    child: InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ativo ? Icons.visibility : Icons.visibility_off,
              size: 16,
              color: ativo ? AppCores.erroTexto : AppCores.textoSuave,
            ),
            const SizedBox(width: 8),
            Text(
              'Alertas ($total)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ativo ? AppCores.texto : AppCores.textoSuave,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)],
    ),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 12, color: AppCores.textoMedio),
    ),
  );
}
