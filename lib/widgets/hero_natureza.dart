import 'package:flutter/material.dart';

import '../data/animais_data.dart';
import '../theme/app_theme.dart';
import 'superficie_vidro.dart';

class HeroNatureza extends StatefulWidget {
  const HeroNatureza({
    super.key,
    required this.aoAbrirMapa,
    required this.aoAbrirAnimais,
  });
  final VoidCallback aoAbrirMapa;
  final VoidCallback aoAbrirAnimais;

  @override
  State<HeroNatureza> createState() => _HeroNaturezaState();
}

class _HeroNaturezaState extends State<HeroNatureza> {
  int _especie = 0;

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.ehMobile(context);
    final animal = animais[_especie];
    final texto = EntradaSuave(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.spa_outlined, color: AppCores.verdeClaro, size: 18),
              Text(
                'CONHECER PARA PRESERVAR',
                style: TextStyle(
                  color: AppCores.verdeClaro,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text.rich(
            const TextSpan(
              children: [
                TextSpan(text: 'O futuro do\nBrasil é '),
                TextSpan(
                  text: 'vivo.',
                  style: TextStyle(color: AppCores.verdeClaro),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: mobile ? 43 : 64,
              height: 1.05,
              letterSpacing: -2.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Explore nossos biomas. Conheça as espécies ameaçadas. Entenda os sinais que a natureza nos dá.',
            style: TextStyle(
              fontSize: 17,
              height: 1.7,
              color: Color(0xFFD1FAE5),
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: widget.aoAbrirMapa,
                icon: const Icon(Icons.explore_outlined, size: 20),
                label: const Text('Explorar o mapa'),
              ),
              OutlinedButton.icon(
                onPressed: widget.aoAbrirAnimais,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x66FFFFFF)),
                  backgroundColor: const Color(0x14FFFFFF),
                ),
                icon: const Icon(Icons.arrow_outward, size: 18),
                label: const Text('Conhecer a fauna'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            '06 BIOMAS  /  UMA NATUREZA INSUBSTITUÍVEL',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              color: Color(0xFFA7F3D0),
            ),
          ),
        ],
      ),
    );
    final fotografia = EntradaSuave(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: mobile ? 330 : 420,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 550),
                    layoutBuilder: (atual, anteriores) => Stack(
                      fit: StackFit.expand,
                      children: [...anteriores, ?atual],
                    ),
                    child: Image.network(
                      animal.imagem,
                      key: ValueKey(animal.imagem),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF14532D), Color(0xFF0F1117)],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.pets_outlined,
                            color: AppCores.verdeClaro,
                            size: 90,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xB3052E16)],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 20,
                    left: 20,
                    child: SuperficieVidro(
                      escuro: true,
                      raio: 999,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      child: Text(
                        'FAUNA BRASILEIRA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 18,
                    left: 18,
                    right: 18,
                    child: SuperficieVidro(
                      escuro: true,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  animal.bioma.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppCores.verdeClaro,
                                    fontSize: 10,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  animal.nome,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: widget.aoAbrirAnimais,
                            tooltip: 'Explorar espécies',
                            icon: const Icon(Icons.arrow_outward),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < 4; i++)
                Tooltip(
                  message: animais[i].nome,
                  child: ChoiceChip(
                    label: Text('0${i + 1}'),
                    selected: _especie == i,
                    onSelected: (_) => setState(() => _especie = i),
                    showCheckmark: false,
                    selectedColor: AppCores.verdeClaro,
                    backgroundColor: const Color(0xFF14532D),
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: _especie == i
                          ? const Color(0xFF052E16)
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(.7, -.5),
          radius: 1.3,
          colors: [Color(0xFF166534), Color(0xFF052E16), Color(0xFF0F1117)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 24 : 48,
        vertical: mobile ? 38 : 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (_, limites) => limites.maxWidth < 850
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [texto, const SizedBox(height: 36), fotografia],
                  )
                : Row(
                    children: [
                      Expanded(child: texto),
                      const SizedBox(width: 56),
                      Expanded(child: fotografia),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
