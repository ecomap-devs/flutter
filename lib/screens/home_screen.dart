import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/home_data.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/barras_chart.dart';
import '../widgets/charts/donut_chart.dart';
import '../widgets/charts/linha_chart.dart';
import '../widgets/charts/radar_chart.dart';
import '../widgets/reviews_section.dart';

/// Landing page — porte do Home.jsx.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.usuario,
    required this.aoPedirLogin,
  });

  final User? usuario;
  final VoidCallback aoPedirLogin;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const _Hero(),
          const _Estatisticas(),
          const _Graficos(),
          const _LinhaDoTempo(),
          const _Solucoes(),
          ReviewsSection(usuario: usuario, aoPedirLogin: aoPedirLogin),
          const _Rodape(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final ehMobile = Breakpoints.ehMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: ehMobile ? 56 : 88,
        horizontal: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF052E16), Color(0xFF14532D), Color(0xFF166534)],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'PROJETO INTERDISCIPLINAR • FATEC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppCores.verdeClaro,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'O Brasil perde floresta\ntodos os dias.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ehMobile ? 32 : 48,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Dados de desmatamento e fauna ameaçada nos seis biomas '
                'brasileiros — em mapa, gráfico e ficha de espécie, não em '
                'tabela.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFFD1FAE5),
                ),
              ),
            ],
          ),
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
    padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
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
                mainAxisExtent: 150,
              ),
              itemBuilder: (_, i) {
                final e = estatisticas[i];
                return Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppCores.fundo,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppCores.borda),
                  ),
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
        child: DonutChart(),
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
        child: RadarChart(),
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
              const SizedBox(height: 40),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppCores.borda),
    ),
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
        child,
      ],
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
  Widget build(BuildContext context) => IntrinsicHeight(
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
  );
}

class _Solucoes extends StatelessWidget {
  const _Solucoes();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppCores.fundo,
    padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            const _TituloSecao(
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
                    mainAxisExtent: 196,
                  ),
                  itemBuilder: (_, i) {
                    final s = solucoes[i];
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppCores.borda),
                      ),
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
                              color: AppCores.texto,
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
                                color: AppCores.textoSuave,
                              ),
                            ),
                          ),
                        ],
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
  const _TituloSecao({required this.sobretitulo, required this.titulo});

  final String sobretitulo;
  final String titulo;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        sobretitulo,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: AppCores.verde,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        titulo,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppCores.texto,
        ),
      ),
    ],
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
