import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/home_data.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/barras_chart.dart';
import '../widgets/charts/donut_chart.dart';
import '../widgets/charts/linha_chart.dart';
import '../widgets/charts/radar_chart.dart';
import '../widgets/reviews_section.dart';
import '../widgets/hero_natureza.dart';
import '../widgets/superficie_vidro.dart';
import '../widgets/animacao_na_tela.dart';
import '../widgets/rolagem_suave.dart';

/// Landing page — porte do Home.jsx.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.usuario,
    required this.aoPedirLogin,
    required this.aoAbrirMapa,
    required this.aoAbrirAnimais,
  });

  final User? usuario;
  final VoidCallback aoPedirLogin;
  final VoidCallback aoAbrirMapa;
  final VoidCallback aoAbrirAnimais;

  @override
  Widget build(BuildContext context) {
    return RolagemSuave(
      builder: (context, controlador) => SingleChildScrollView(
        controller: controlador,
        child: Column(
          children: [
            HeroNatureza(
              aoAbrirMapa: aoAbrirMapa,
              aoAbrirAnimais: aoAbrirAnimais,
            ),
            const _Estatisticas(),
            const _Graficos(),
            const _LinhaDoTempo(),
            const _Solucoes(),
            RevelarAoRolar(
              child: ReviewsSection(
                usuario: usuario,
                aoPedirLogin: aoPedirLogin,
              ),
            ),
            const _Rodape(),
          ],
        ),
      ),
    );
  }
}

class _Estatisticas extends StatelessWidget {
  const _Estatisticas();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: LayoutBuilder(
          builder: (context, c) {
            final colunas = (c.maxWidth / 260).floor().clamp(1, 4);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: estatisticas.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colunas,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: 150 * MediaQuery.textScalerOf(context).scale(1),
              ),
              itemBuilder: (_, i) {
                final e = estatisticas[i];
                return RevelarAoRolar(
                  atraso: Duration(milliseconds: i * 90),
                  child: SuperficieVidro(
                    animarHover: true,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(e.icone, color: e.cor, size: 26),
                        const Spacer(),
                        Text(
                          e.valor,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppCores.texto,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.rotulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: AppCores.textoSuave,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );
}

class _Graficos extends StatelessWidget {
  const _Graficos();

  @override
  Widget build(BuildContext context) {
    final ehMobile = Breakpoints.ehMobile(context);

    final cartoes = <Widget>[
      const _CartaoGrafico(
        titulo: 'Desmatamento acumulado por bioma',
        subtitulo: 'em mil km²',
        child: BarrasChart(),
      ),
      const _CartaoGrafico(
        titulo: 'Participação de cada bioma',
        subtitulo: 'no total desmatado',
        child: SizedBox(width: 220, child: DonutChart()),
      ),
      _CartaoGrafico(
        titulo: 'Evolução do desmatamento',
        subtitulo: 'Amazônia, em mil km²',
        child: LinhaChart(
          valores: const [180, 320, 460, 580, 690, 780],
          rotulos: const ['2000', '2005', '2010', '2015', '2020', '2024'],
          cor: AppCores.verde,
          altura: 200,
        ),
      ),
      const _CartaoGrafico(
        titulo: 'Pressão relativa entre biomas',
        subtitulo: 'escala até 780 mil km²',
        child: SizedBox(width: 300, child: RadarChart()),
      ),
    ];

    return Container(
      width: double.infinity,
      color: AppCores.fundo,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const _TituloSecao(
                sobretitulo: 'OS NÚMEROS',
                titulo: 'O que os dados mostram',
              ),
              const SizedBox(height: 12),
              const Text(
                'Indicadores de referência do projeto. Não representam monitoramento em tempo real.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppCores.textoSuave,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (ehMobile)
                Column(
                  children: [
                    for (final c in cartoes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: c,
                      ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cartoes[0]),
                        const SizedBox(width: 20),
                        Expanded(child: cartoes[1]),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cartoes[2]),
                        const SizedBox(width: 20),
                        Expanded(child: cartoes[3]),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoGrafico extends StatelessWidget {
  const _CartaoGrafico({
    required this.titulo,
    required this.subtitulo,
    required this.child,
  });

  final String titulo;
  final String subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) => RevelarAoRolar(
    child: SuperficieVidro(
      animarHover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppCores.texto,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 12, color: AppCores.textoSuave),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 310 * MediaQuery.textScalerOf(context).scale(1),
            child: Center(child: child),
          ),
        ],
      ),
    ),
  );
}

class _LinhaDoTempo extends StatelessWidget {
  const _LinhaDoTempo();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            const _TituloSecao(
              sobretitulo: 'LINHA DO TEMPO',
              titulo: 'Duas décadas de perda',
            ),
            const SizedBox(height: 40),
            for (var i = 0; i < linhaDoTempo.length; i++)
              _ItemTempo(
                item: linhaDoTempo[i],
                ultimo: i == linhaDoTempo.length - 1,
              ),
          ],
        ),
      ),
    ),
  );
}

class _ItemTempo extends StatelessWidget {
  const _ItemTempo({required this.item, required this.ultimo});

  final ItemLinhaTempo item;
  final bool ultimo;

  @override
  Widget build(BuildContext context) => RevelarAoRolar(
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              item.ano,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppCores.verde,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppCores.verde,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppCores.verde.withValues(alpha: 0.3),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              if (!ultimo)
                Expanded(child: Container(width: 2, color: AppCores.borda)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppCores.texto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.texto,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppCores.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Solucoes extends StatelessWidget {
  const _Solucoes();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF14532D), Color(0xFF052E16)],
      ),
    ),
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            const _TituloSecao(
              escuro: true,
              sobretitulo: 'O QUE FAZER',
              titulo: 'Soluções ao alcance de todos',
            ),
            const SizedBox(height: 40),
            LayoutBuilder(
              builder: (context, c) {
                final colunas = (c.maxWidth / 330).floor().clamp(1, 3);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: solucoes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colunas,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    mainAxisExtent:
                        250 * MediaQuery.textScalerOf(context).scale(1),
                  ),
                  itemBuilder: (_, i) {
                    final s = solucoes[i];
                    return RevelarAoRolar(
                      atraso: Duration(milliseconds: (i % colunas) * 100),
                      child: SuperficieVidro(
                        animarHover: true,
                        escuro: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppCores.verdeFundo,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                s.icone,
                                color: AppCores.verde,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              s.titulo,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                s.texto,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 5,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: Color(0xFFD1FAE5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({
    required this.sobretitulo,
    required this.titulo,
    this.escuro = false,
  });

  final bool escuro;

  final String sobretitulo;
  final String titulo;

  @override
  Widget build(BuildContext context) => RevelarAoRolar(
    child: Column(
      children: [
        Text(
          sobretitulo,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: escuro ? AppCores.verdeClaro : AppCores.verde,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: escuro ? Colors.white : AppCores.texto,
          ),
        ),
      ],
    ),
  );
}

class _Rodape extends StatelessWidget {
  const _Rodape();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xFF052E16),
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    child: Column(
      children: [
        const Text(
          'EcoMapBrasil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Projeto Interdisciplinar — ${equipe.join(', ')}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFFA7F3D0)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dados de desmatamento: DETER-B / INPE',
          style: TextStyle(fontSize: 12, color: Color(0xFF6EE7B7)),
        ),
      ],
    ),
  );
}
