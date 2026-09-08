import '../models/animal.dart';

/// Catalogo de especies — porte de `allAnimals` do Animais.jsx.
///
/// Valores de referencia embutidos no codigo, como na versao React. A troca
/// por dados oficiais (ICMBio) segue como proxima etapa do projeto.
const animais = <Animal>[
  Animal(
    nome: 'Onça-pintada',
    status: 'Criticamente ameaçada',
    bioma: 'Mata Atlântica',
    regiao: 'Sudeste',
    populacao: 300,
    tendencia: [1200, 950, 700, 520, 380, 300],
    anos: ['2000', '2005', '2010', '2015', '2020', '2024'],
    descricao:
        'O maior felino das Américas perdeu mais de 50% de seu habitat na '
        'Mata Atlântica nos últimos 15 anos. A fragmentação florestal impede '
        'a migração entre populações.',
    ameacas: ['Desmatamento', 'Caça ilegal', 'Fragmentação de habitat'],
    imagem: 'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/onca-pintada.png',
  ),
  Animal(
    nome: 'Arara-azul',
    status: 'Em perigo',
    bioma: 'Pantanal',
    regiao: 'Centro-Oeste',
    populacao: 6500,
    tendencia: [10000, 8500, 7200, 6800, 6600, 6500],
    anos: ['2000', '2005', '2010', '2015', '2020', '2024'],
    descricao:
        'Com apenas 6.500 indivíduos restantes, a arara-azul depende da '
        'preservação das matas ciliares e árvores nativas para nidificação '
        'no Pantanal.',
    ameacas: ['Tráfico de animais', 'Perda de habitat', 'Queimadas'],
    imagem: 'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/arara-azul-de-lear_01_0.png',
  ),
  Animal(
    nome: 'Mico-leão-dourado',
    status: 'Criticamente ameaçada',
    bioma: 'Mata Atlântica',
    regiao: 'Sudeste',
    populacao: 2500,
    tendencia: [400, 800, 1200, 1800, 2200, 2500],
    anos: ['2000', '2005', '2010', '2015', '2020', '2024'],
    descricao:
        'Símbolo da conservação brasileira, o mico-leão-dourado é um caso de '
        'sucesso parcial: programas de reintrodução elevaram sua população, '
        'mas a espécie permanece vulnerável.',
    ameacas: [
      'Fragmentação florestal',
      'Doenças',
      'Baixa diversidade genética',
    ],
    imagem: 'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/micoleao-cke.png',
  ),
  Animal(
    nome: 'Lobo-guará',
    status: 'Vulnerável',
    bioma: 'Cerrado',
    regiao: 'Centro-Oeste',
    populacao: 23000,
    tendencia: [35000, 31000, 28000, 26000, 24000, 23000],
    anos: ['2000', '2005', '2010', '2015', '2020', '2024'],
    descricao:
        'O maior canídeo sul-americano habita as vastas savanas do Cerrado. '
        'A expansão agrícola e as rodovias são as principais causas de '
        'mortalidade da espécie.',
    ameacas: ['Expansão agrícola', 'Atropelamentos', 'Perda de habitat'],
    imagem: 'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/lobo-guara.png',
  ),
  Animal(
    nome: 'Tucano-de-bico-preto',
    status: 'Em perigo',
    bioma: 'Amazônia',
    regiao: 'Norte',
    populacao: 4200,
    tendencia: [8000, 7000, 6200, 5400, 4700, 4200],
    anos: ['2000', '2005', '2010', '2015', '2020', '2024'],
    descricao:
        'Dispersor de sementes essencial para a regeneração da Amazônia, o '
        'tucano-de-bico-preto sofre com a fragmentação florestal que isola '
        'populações.',
    ameacas: ['Desmatamento', 'Tráfico de animais', 'Fragmentação'],
    imagem: 'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/large-6.jpg',
  ),
  Animal(
    nome: 'Perereca-verde-da-mata',
    status: 'Criticamente ameaçada',
    bioma: 'Mata Atlântica',
    regiao: 'Sudeste',
    populacao: 180,
    tendencia: [900, 650, 450, 320, 230, 180],
    anos: ['2000', '2005', '2010', '2015', '2020', '2024'],
    descricao:
        'Endêmica de fragmentos florestais da Mata Atlântica, esta perereca é '
        'altamente sensível a alterações microclimáticas causadas pelo '
        'desmatamento.',
    ameacas: ['Desmatamento', 'Mudanças climáticas', 'Fungos patogênicos'],
    imagem: 'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/figura_1.jpg',
  ),
  Animal(
    nome: 'Tamanduá-bandeira',
    status: 'Vulnerável',
    bioma: 'Cerrado',
    regiao: 'Centro-Oeste',
    populacao: 5000,
    tendencia: [9000, 8000, 7000, 6200, 5500, 5000],
    anos: ['2000', '2005', '2010', '2015', '2020', '2024'],
    descricao:
        'O maior mirmecófago do mundo, o tamanduá-bandeira tem baixíssima taxa '
        'reprodutiva, tornando-o extremamente vulnerável à pressão humana '
        'sobre o Cerrado.',
    ameacas: ['Queimadas', 'Atropelamentos', 'Perda de habitat'],
    imagem: 'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/tamandua-bandeira-2.png',
  ),
  Animal(
    nome: 'Boto-cor-de-rosa',
    status: 'Em perigo',
    bioma: 'Amazônia',
    regiao: 'Norte',
    populacao: 12000,
    tendencia: [25000, 21000, 17000, 15000, 13000, 12000],
    anos: ['2000', '2005', '2010', '2015', '2020', '2024'],
    descricao:
        'O maior golfinho de água doce do mundo enfrenta ameaças crescentes '
        'pela poluição dos rios amazônicos, pesca acidental e construção de '
        'hidrelétricas.',
    ameacas: ['Poluição hídrica', 'Pesca acidental', 'Hidrelétricas'],
    imagem: 'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/banner_blog_novo_24.png',
  ),
  Animal(
    nome: 'Ararinha-azul',
    status: 'Extinta na natureza',
    bioma: 'Caatinga',
    regiao: 'Nordeste',
    populacao: 0,
    tendencia: [200, 80, 20, 5, 1, 0],
    anos: ['2000', '2005', '2010', '2015', '2020', '2024'],
    descricao:
        'Considerada extinta na natureza desde 2000, a ararinha-azul sobrevive '
        'apenas em cativeiro. Programas de reintrodução tentam devolvê-la à '
        'Caatinga baiana.',
    ameacas: [
      'Desmatamento total',
      'Captura para cativeiro',
      'Ausência de habitat',
    ],
    imagem: 'https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/ARARINHA_AZUL-795.jpg',
  ),
];

/// Filtros da tela de catalogo.
const biomasFiltro = <String>[
  'Todos',
  'Amazônia',
  'Cerrado',
  'Mata Atlântica',
  'Pantanal',
  'Caatinga',
];

const statusFiltro = <String>[
  'Todos',
  'Criticamente ameaçada',
  'Em perigo',
  'Vulnerável',
  'Extinta na natureza',
];
