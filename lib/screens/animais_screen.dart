import 'package:flutter/material.dart';

import '../data/animais_data.dart';
import '../models/animal.dart';
import '../theme/app_theme.dart';
import '../widgets/charts/linha_chart.dart';

/// Catalogo de especies ameacadas — porte do Animais.jsx.
class AnimaisScreen extends StatefulWidget {
  const AnimaisScreen({super.key});

  @override
  State<AnimaisScreen> createState() => _AnimaisScreenState();
}

class _AnimaisScreenState extends State<AnimaisScreen> {
  final _busca = TextEditingController();

  String _bioma = 'Todos';
  String _status = 'Todos';

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  List<Animal> get _filtrados {
    final termo = _busca.text.trim().toLowerCase();
    return animais.where((a) {
      final casaBusca = termo.isEmpty || a.nome.toLowerCase().contains(termo);
      final casaBioma = _bioma == 'Todos' || a.bioma == _bioma;
      final casaStatus = _status == 'Todos' || a.status == _status;
      return casaBusca && casaBioma && casaStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            children: [
              TextField(
                controller: _busca,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar espécie...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _busca.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _busca.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final b in biomasFiltro)
                      _Filtro(
                        rotulo: b,
                        ativo: _bioma == b,
                        aoTocar: () => setState(() => _bioma = b),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final s in statusFiltro)
                      _Filtro(
                        rotulo: s,
                        ativo: _status == s,
                        aoTocar: () => setState(() => _status = s),
                        cor: AppCores.statusTexto[s],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppCores.borda),
        Expanded(
          child: lista.isEmpty
              ? const _Vazio()
              : LayoutBuilder(
                  builder: (context, c) {
                    final colunas = (c.maxWidth / 330).floor().clamp(1, 4);
                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: lista.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: colunas,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        mainAxisExtent: 340,
                      ),
                      itemBuilder: (_, i) => _CartaoAnimal(
                        animal: lista[i],
                        aoTocar: () => _abrirFicha(lista[i]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _abrirFicha(Animal a) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controlador) =>
            _FichaAnimal(animal: a, controlador: controlador),
      ),
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.rotulo,
    required this.ativo,
    required this.aoTocar,
    this.cor,
  });

  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final destaque = cor ?? AppCores.verde;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: ativo ? destaque : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: ativo ? destaque : AppCores.borda,
            ),
          ),
          child: Text(
            rotulo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ativo ? Colors.white : AppCores.textoMedio,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoAnimal extends StatelessWidget {
  const _CartaoAnimal({required this.animal, required this.aoTocar});

  final Animal animal;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppCores.borda),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 148,
                width: double.infinity,
                child: _ImagemAnimal(url: animal.imagem),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppCores.texto,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Etiqueta(
                          texto: animal.status,
                          fundo: animal.corStatusFundo,
                          cor: animal.corStatusTexto,
                        ),
                        _Etiqueta(
                          texto: animal.bioma,
                          fundo: animal.corBioma.withValues(alpha: 0.12),
                          cor: animal.corBioma,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          animal.emRecuperacao
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 15,
                          color: animal.emRecuperacao
                              ? AppCores.verde
                              : AppCores.erroTexto,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          animal.variacaoFormatada,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: animal.emRecuperacao
                                ? AppCores.verde
                                : AppCores.erroTexto,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'desde 2000',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppCores.textoSuave,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinhaChart(
                      valores: animal.tendencia,
                      rotulos: animal.anos,
                      cor: animal.emRecuperacao
                          ? AppCores.verde
                          : AppCores.erroTexto,
                      mostrarEixo: false,
                      altura: 42,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ImagemAnimal extends StatelessWidget {
  const _ImagemAnimal({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (_, filho, progresso) => progresso == null
            ? filho
            : Container(
                color: AppCores.fundo,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppCores.verde,
                    ),
                  ),
                ),
              ),
        // Imagem hospedada no Supabase pode falhar (offline, bucket movido).
        // Cai num placeholder em vez de exibir o icone de erro do Flutter.
        errorBuilder: (_, _, _) => Container(
          color: AppCores.verdeFundo,
          child: const Center(
            child: Icon(Icons.pets, size: 34, color: AppCores.verde),
          ),
        ),
      );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.fundo,
    required this.cor,
  });

  final String texto;
  final Color fundo;
  final Color cor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: cor,
          ),
        ),
      );
}

class _FichaAnimal extends StatelessWidget {
  const _FichaAnimal({required this.animal, required this.controlador});

  final Animal animal;
  final ScrollController controlador;

  @override
  Widget build(BuildContext context) => ListView(
        controller: controlador,
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ImagemAnimal(url: animal.imagem),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close,
                          size: 20, color: Colors.white),
                      tooltip: 'Fechar',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.nome,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppCores.texto,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Etiqueta(
                      texto: animal.status,
                      fundo: animal.corStatusFundo,
                      cor: animal.corStatusTexto,
                    ),
                    _Etiqueta(
                      texto: animal.bioma,
                      fundo: animal.corBioma.withValues(alpha: 0.12),
                      cor: animal.corBioma,
                    ),
                    _Etiqueta(
                      texto: animal.regiao,
                      fundo: AppCores.borda,
                      cor: AppCores.textoMedio,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  animal.descricao,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: AppCores.textoMedio,
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppCores.fundo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'População estimada',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppCores.textoSuave,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              animal.populacaoFormatada,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppCores.texto,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Desde 2000',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppCores.textoSuave,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            animal.variacaoFormatada,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: animal.emRecuperacao
                                  ? AppCores.verde
                                  : AppCores.erroTexto,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Tendência populacional',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppCores.texto,
                  ),
                ),
                const SizedBox(height: 14),
                LinhaChart(
                  valores: animal.tendencia,
                  rotulos: animal.anos,
                  cor: animal.emRecuperacao
                      ? AppCores.verde
                      : AppCores.erroTexto,
                  altura: 170,
                ),
                const SizedBox(height: 24),

                const Text(
                  'Principais ameaças',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppCores.texto,
                  ),
                ),
                const SizedBox(height: 12),
                for (final ameaca in animal.ameacas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppCores.erroTexto),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ameaca,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppCores.textoMedio,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      );
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: AppCores.textoSuave),
            SizedBox(height: 12),
            Text(
              'Nenhuma espécie encontrada',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppCores.textoMedio,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tente outro termo ou limpe os filtros.',
              style: TextStyle(fontSize: 13, color: AppCores.textoSuave),
            ),
          ],
        ),
      );
}
