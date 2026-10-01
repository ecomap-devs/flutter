import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/biomas_data.dart';
import '../models/bioma.dart';
import '../services/geojson_service.dart';
import '../theme/app_theme.dart';
import '../widgets/superficie_vidro.dart';

/// O fundo do mapa. Comeca no claro: biomas coloridos e alertas vermelhos
/// aparecem muito mais sobre ele do que sobre o satelite escuro.
enum _Fundo { claro, satelite }

const _vermelhoAlerta = Color(0xFFDC2626);

/// Abaixo deste zoom o alerta vira ponto; a partir dele, o poligono aparece.
///
/// Com o Brasil inteiro na tela, um alerta de 70 ha tem menos de um pixel: o
/// poligono era desenhado, mas ninguem enxergava. No zoom 7 a maioria ja
/// tem forma visivel.
const _zoomDetalhe = 7.0;

const _centroBrasil = LatLng(-14, -52);

/// Os alertas ja preparados para desenhar, e o resumo para a legenda.
///
/// Montado uma vez quando o GeoJSON termina de carregar: sao 18 mil alertas,
/// e refazer as listas a cada movimento do mapa custaria quadros.
class _DadosMapa {
  _DadosMapa(List<AlertaDesmatamento> alertas)
    : total = alertas.length,
      areaHa = alertas.fold(0, (s, a) => s + a.areaHa),
      // Ano 0 e alerta sem data no arquivo: fica fora do periodo.
      anoMin = alertas
          .map((a) => a.ano)
          .where((a) => a > 0)
          .fold<int?>(null, (m, a) => m == null || a < m ? a : m),
      anoMax = alertas
          .map((a) => a.ano)
          .where((a) => a > 0)
          .fold<int?>(null, (m, a) => m == null || a > m ? a : m),
      poligonos = [
        for (final a in alertas)
          for (final parte in a.partes)
            Polygon(
              points: parte.contorno,
              holePointsList: parte.buracos,
              color: _vermelhoAlerta.withValues(alpha: 0.6),
              borderColor: const Color(0xFFEF4444),
              borderStrokeWidth: 0.5,
            ),
      ],
      pontos = [
        for (final a in alertas)
          CircleMarker(
            point: a.centro,
            radius: 2.2,
            color: _vermelhoAlerta.withValues(alpha: 0.75),
          ),
      ];

  final int total;
  final double areaHa;
  final int? anoMin;
  final int? anoMax;
  final List<Polygon> poligonos;
  final List<CircleMarker> pontos;
}

/// Mapa interativo dos biomas — porte do Mapa.jsx.
///
/// `flutter_map` e o irmao do Leaflet no Flutter: mesma ideia de camadas
/// sobre tiles, e roda igual na web e no celular. Os dois fundos sao da Esri
/// (o satelite e o mesmo da versao React, o World Imagery).
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _mapa = MapController();
  final _geo = GeoJsonService();

  late final Future<_DadosMapa> _dados;

  Bioma? _selecionado;
  bool _mostrarAlertas = true;
  bool _legendaAberta = true;
  bool _detalhe = false;
  _Fundo _fundo = _Fundo.claro;

  @override
  void initState() {
    super.initState();
    _dados = _geo.carregar().then(_DadosMapa.new);
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  /// Selecao vinda da lista: enquadra o bioma inteiro.
  ///
  /// Antes era `move(centro, 5)`: zoom fixo cortava a Amazonia e deixava o
  /// Pantanal minusculo. Enquadrar pelos limites serve aos dois.
  void _selecionar(Bioma b) {
    setState(() => _selecionado = b);
    final ehMobile = Breakpoints.ehMobile(context);
    _mapa.fitCamera(
      CameraFit.bounds(
        bounds: b.limites,
        // No celular a ficha ocupa o pe da tela; o bioma fica acima dela.
        padding: EdgeInsets.fromLTRB(40, 70, 40, ehMobile ? 300 : 40),
      ),
    );
  }

  /// No celular a lista lateral não cabe: abre numa folha por baixo.
  ///
  /// Revisão de 01/10/2026: antes, no celular, a única forma de escolher um
  /// bioma era acertar o dedo no ponto certo do mapa — sem alternativa para
  /// leitor de tela.
  void _abrirListaDeBiomas() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (contexto) => SizedBox(
        height: MediaQuery.sizeOf(contexto).height * .7,
        child: _ListaBiomas(
          selecionado: _selecionado,
          aoSelecionar: (b) {
            Navigator.of(contexto).pop();
            _selecionar(b);
          },
        ),
      ),
    );
  }

  /// Toque no mapa: seleciona o bioma sob o dedo, ou limpa se caiu fora.
  ///
  /// No React o clique tambem dava `fitBounds`; aqui a camera fica parada,
  /// porque mover o mapa a cada toque atrapalha quem so quer ler a ficha —
  /// quem quer enquadrar o bioma escolhe na lista.
  void _tocarNoMapa(LatLng ponto) {
    final achado = Bioma.maisEspecificoEm(biomas, ponto);
    if (achado != _selecionado) setState(() => _selecionado = achado);
  }

  void _mudouCamera(MapCamera camera, bool _) {
    final detalhe = camera.zoom >= _zoomDetalhe;
    if (detalhe != _detalhe) setState(() => _detalhe = detalhe);
  }

  void _aproximar(double passo) => _mapa.move(
    _mapa.camera.center,
    (_mapa.camera.zoom + passo).clamp(2, 12).toDouble(),
  );

  List<Widget> _camadasDeFundo() => switch (_fundo) {
    _Fundo.claro => [
      TileLayer(
        urlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'br.com.ecomapbrasil',
      ),
    ],
    _Fundo.satelite => [
      TileLayer(
        urlTemplate:
            'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'World_Imagery/MapServer/tile/{z}/{y}/{x}',
        userAgentPackageName: 'br.com.ecomapbrasil',
      ),
    ],
  };

  /// Nomes de cidades e fronteiras, por cima dos biomas e dos alertas — senao
  /// o preenchimento colorido apagaria os nomes.
  Widget _camadaDeNomes() => TileLayer(
    urlTemplate: switch (_fundo) {
      _Fundo.claro =>
        'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'Canvas/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
      _Fundo.satelite =>
        'https://server.arcgisonline.com/ArcGIS/rest/services/'
            'Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
    },
    userAgentPackageName: 'br.com.ecomapbrasil',
  );

  /// Os seis biomas pelo limite do IBGE.
  ///
  /// Ate 01/10/2026 nao eram desenhados: os contornos eram retangulos
  /// herdados do React, e mostrar aquilo seria apresentar fronteira
  /// inventada. O preenchimento e fraco de proposito — o de 28% que existia
  /// antes abafava justamente o vermelho dos alertas. O selecionado ganha
  /// borda grossa e preenchimento mais forte.
  Widget _camadaDeBiomas() => PolygonLayer(
    polygons: [
      for (final b in biomas)
        for (final contorno in b.poligonos)
          Polygon(
            points: contorno,
            holePointsList: b.buracosDe(contorno),
            color: b.cor.withValues(alpha: b == _selecionado ? 0.30 : 0.12),
            borderColor: b.cor,
            borderStrokeWidth: b == _selecionado ? 3 : 1.2,
          ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final ehMobile = Breakpoints.ehMobile(context);

    final mapa = FutureBuilder<_DadosMapa>(
      future: _dados,
      builder: (context, snap) {
        final dados = snap.data;
        final carregando = snap.connectionState == ConnectionState.waiting;
        // No celular a ficha e a legenda disputam o pe da tela.
        final mostrarLegenda =
            _legendaAberta && !(ehMobile && _selecionado != null);

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: _centroBrasil,
                initialZoom: ehMobile ? 3.4 : 4,
                minZoom: 2,
                maxZoom: 12,
                onTap: (_, ponto) => _tocarNoMapa(ponto),
                onPositionChanged: _mudouCamera,
              ),
              children: [
                ..._camadasDeFundo(),
                _camadaDeBiomas(),
                if (_mostrarAlertas && dados != null)
                  _detalhe
                      ? PolygonLayer(polygons: dados.poligonos)
                      : CircleLayer(circles: dados.pontos),
                _camadaDeNomes(),
              ],
            ),

            if (carregando)
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

            Positioned(
              top: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (dados != null)
                    _BotaoMapa(
                      icone: _mostrarAlertas
                          ? Icons.visibility
                          : Icons.visibility_off,
                      corIcone: _mostrarAlertas
                          ? AppCores.erroTexto
                          : AppCores.textoSuave,
                      rotulo: 'Alertas',
                      ativo: _mostrarAlertas,
                      aoTocar: () =>
                          setState(() => _mostrarAlertas = !_mostrarAlertas),
                    ),
                  const SizedBox(height: 8),
                  _BotaoMapa(
                    icone: _fundo == _Fundo.claro
                        ? Icons.satellite_alt_outlined
                        : Icons.map_outlined,
                    rotulo: _fundo == _Fundo.claro ? 'Satélite' : 'Mapa',
                    aoTocar: () => setState(
                      () => _fundo = _fundo == _Fundo.claro
                          ? _Fundo.satelite
                          : _Fundo.claro,
                    ),
                  ),
                  if (!_legendaAberta) ...[
                    const SizedBox(height: 8),
                    _BotaoMapa(
                      icone: Icons.info_outline,
                      rotulo: 'Legenda',
                      aoTocar: () => setState(() => _legendaAberta = true),
                    ),
                  ],
                ],
              ),
            ),

            Positioned(
              left: 12,
              top: 12,
              child: SuperficieVidro(
                padding: const EdgeInsets.all(4),
                raio: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Aproximar mapa',
                      onPressed: () => _aproximar(1),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: 'Afastar mapa',
                      onPressed: () => _aproximar(-1),
                      icon: const Icon(Icons.remove),
                    ),
                    if (ehMobile)
                      IconButton(
                        tooltip: 'Escolher bioma',
                        onPressed: _abrirListaDeBiomas,
                        icon: const Icon(Icons.list_alt),
                      ),
                    IconButton(
                      tooltip: 'Ver todo o Brasil',
                      onPressed: () {
                        setState(() => _selecionado = null);
                        _mapa.move(_centroBrasil, ehMobile ? 3.4 : 4);
                      },
                      icon: const Icon(Icons.public),
                    ),
                  ],
                ),
              ),
            ),

            if (mostrarLegenda)
              Positioned(
                left: 12,
                bottom: 28,
                right: ehMobile ? 12 : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: _Legenda(
                    dados: dados,
                    detalhe: _detalhe,
                    aoFechar: () => setState(() => _legendaAberta = false),
                  ),
                ),
              ),

            if (_selecionado != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 28,
                child: EntradaSuave(
                  key: ValueKey(_selecionado!.nome),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .4,
                    ),
                    child: SingleChildScrollView(
                      child: _FichaBioma(
                        bioma: _selecionado!,
                        aoFechar: () => setState(() => _selecionado = null),
                      ),
                    ),
                  ),
                ),
              ),

            // A Esri pede o credito visivel sobre o mapa; IBGE e INPE sao as
            // fontes dos dados desenhados.
            const Positioned(right: 6, bottom: 4, child: _Creditos()),
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

/// "18262" vira "18.262": separador de milhar brasileiro.
String _milhar(num n) => n.round().toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+$)'),
  (m) => '${m[1]}.',
);

String _hectares(double ha) => ha >= 1000000
    ? '${(ha / 1000000).toStringAsFixed(1).replaceAll('.', ',')} mi ha'
    : '${_milhar(ha)} ha';

class _Legenda extends StatelessWidget {
  const _Legenda({
    required this.dados,
    required this.detalhe,
    required this.aoFechar,
  });

  final _DadosMapa? dados;
  final bool detalhe;
  final VoidCallback aoFechar;

  static const _suave = TextStyle(
    fontSize: 11,
    height: 1.4,
    color: AppCores.textoSuave,
  );

  @override
  Widget build(BuildContext context) {
    final d = dados;
    final periodo = d == null || d.anoMin == null
        ? null
        : d.anoMin == d.anoMax
        ? '${d.anoMin}'
        : '${d.anoMin}–${d.anoMax}';

    return SuperficieVidro(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
      raio: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Legenda',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppCores.texto,
                  ),
                ),
              ),
              IconButton(
                onPressed: aoFechar,
                tooltip: 'Esconder legenda',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 16),
                color: AppCores.textoSuave,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 3, right: 8),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: _vermelhoAlerta,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alerta de desmatamento',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppCores.texto,
                      ),
                    ),
                    Text(
                      d == null
                          ? 'DETER-B / INPE'
                          : 'DETER-B / INPE'
                                '${periodo == null ? '' : ' · $periodo'}'
                                ' · ${_milhar(d.total)} alertas'
                                ' · ${_hectares(d.areaHa)}',
                      style: _suave,
                    ),
                    Text(
                      detalhe
                          ? 'Cada mancha é a área desmatada detectada.'
                          : 'Cada ponto é um alerta. Aproxime para ver a área.',
                      style: _suave,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Biomas (limites do IBGE) · toque para ver a ficha',
            style: _suave,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final b in biomas)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: b.cor.withValues(alpha: 0.35),
                        border: Border.all(color: b.cor, width: 1.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      b.nome,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppCores.textoMedio,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Creditos extends StatelessWidget {
  const _Creditos();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      'Mapa: Esri · Biomas: IBGE · Alertas: INPE',
      style: TextStyle(fontSize: 9, color: AppCores.textoMedio),
    ),
  );
}

class _BotaoMapa extends StatelessWidget {
  const _BotaoMapa({
    required this.icone,
    required this.rotulo,
    required this.aoTocar,
    this.corIcone = AppCores.textoMedio,
    this.ativo = true,
  });

  final IconData icone;
  final Color corIcone;
  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: ativo,
    child: Material(
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
              Icon(icone, size: 16, color: corIcone),
              const SizedBox(width: 8),
              Text(
                rotulo,
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
    ),
  );
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
          'EXPLORE O BRASIL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppCores.verde,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Seis biomas. Muitas conexões.',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppCores.texto,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecione um bioma para conhecer seu território e os impactos do desmatamento.',
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: AppCores.textoSuave,
          ),
        ),
        const SizedBox(height: 20),
        for (final b in biomas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              button: true,
              selected: selecionado?.nome == b.nome,
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
  Widget build(BuildContext context) => SuperficieVidro(
    padding: const EdgeInsets.all(20),
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
