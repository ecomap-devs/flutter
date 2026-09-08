import 'package:flutter/material.dart';

/// Dados estaticos da landing page — porte do Home.jsx.

class Estatistica {
  const Estatistica(this.icone, this.valor, this.rotulo, this.cor);
  final IconData icone;
  final String valor;
  final String rotulo;
  final Color cor;
}

const estatisticas = <Estatistica>[
  Estatistica(Icons.trending_up, '+30%',
      'Aumento no desmatamento na última década', Color(0xFF4ADE80)),
  Estatistica(Icons.local_fire_department, '1.5mi ha',
      'Área queimada anualmente no Brasil', Color(0xFFF97316)),
  Estatistica(Icons.warning_amber_rounded, '1.173',
      'Espécies animais ameaçadas de extinção', Color(0xFFFACC15)),
  Estatistica(Icons.map_outlined, '6 biomas',
      'Biomas brasileiros afetados pelo desmatamento', Color(0xFF60A5FA)),
];

class Solucao {
  const Solucao(this.icone, this.titulo, this.texto);
  final IconData icone;
  final String titulo;
  final String texto;
}

const solucoes = <Solucao>[
  Solucao(Icons.shopping_bag_outlined, 'Consumo Consciente',
      'Evite produtos que contribuem para o desmatamento, como carne de origem '
      'duvidosa, madeira ilegal e óleo de palma não sustentável.'),
  Solucao(Icons.volunteer_activism_outlined, 'Apoie Organizações',
      'Contribua com instituições que trabalham para preservar os biomas '
      'brasileiros e combater o desmatamento ilegal.'),
  Solucao(Icons.how_to_vote_outlined, 'Engajamento Político',
      'Apoie políticas públicas e candidatos comprometidos com a preservação '
      'ambiental e o desenvolvimento sustentável.'),
  Solucao(Icons.park_outlined, 'Reflorestamento',
      'Participe de iniciativas de plantio de árvores nativas e recuperação de '
      'áreas degradadas em sua região.'),
  Solucao(Icons.school_outlined, 'Educação Ambiental',
      'Divulgue informações sobre a importância da preservação e os impactos '
      'do desmatamento em sua comunidade.'),
  Solucao(Icons.phone_android_outlined, 'Denuncie',
      'Use aplicativos como "Denúncia Ambiente" para reportar atividades '
      'ilegais de desmatamento que você identificar.'),
];

class ItemLinhaTempo {
  const ItemLinhaTempo(this.ano, this.titulo, this.texto);
  final String ano;
  final String titulo;
  final String texto;
}

const linhaDoTempo = <ItemLinhaTempo>[
  ItemLinhaTempo('2005', 'Pampa sofre impactos crescentes',
      'Expansão agropecuária avança sobre os campos nativos'),
  ItemLinhaTempo('2010', 'Caatinga afetada',
      'Caatinga tem 45% de sua área original desmatada'),
  ItemLinhaTempo('2013', 'Novo Código Florestal',
      'Brasil aprova novo Código Florestal com impacto nos biomas'),
  ItemLinhaTempo('2015', 'Queimadas no Pantanal',
      'Pantanal perde 12% de sua área para queimadas'),
  ItemLinhaTempo('2018', 'Mata Atlântica reduzida',
      'Mata Atlântica tem apenas 12,4% de sua cobertura original'),
  ItemLinhaTempo('2020', 'Perdas no Cerrado',
      'Cerrado perde 7.340 km² de vegetação nativa'),
  ItemLinhaTempo('2022', 'Seca no Pantanal',
      'Pantanal enfrenta pior seca em décadas'),
  ItemLinhaTempo('2023', 'Recorde de desmatamento',
      'Recorde de desmatamento na Amazônia: 11.568 km²'),
];

/// Desmatamento acumulado por bioma, em mil km² — a serie dos graficos
/// de barras, donut e radar da Home.
class ValorBioma {
  const ValorBioma(this.nome, this.valor);
  final String nome;
  final int valor;
}

const desmatamentoPorBioma = <ValorBioma>[
  ValorBioma('Amazônia', 780),
  ValorBioma('Cerrado', 520),
  ValorBioma('Mata Atlântica', 320),
  ValorBioma('Caatinga', 150),
  ValorBioma('Pantanal', 90),
  ValorBioma('Pampa', 60),
];

/// Equipe do Projeto Interdisciplinar.
const equipe = <String>[
  'Vinicius',
  'Bruno',
  'Cesar',
  'João Flávio',
  'João Gabriel',
];
