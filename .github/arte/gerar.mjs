// Gera as artes do README a partir do próprio repositório, sem dependência nenhuma:
//
//   node .github/arte/gerar.mjs
//
// - banner.svg  : os alertas do DETER-B (assets/data) desenhados como mapa de
//                 densidade, no lugar onde cada um foi detectado
// - numeros.svg : o app em números, contados nos arquivos, não digitados
//
// Determinístico: com o repositório igual, os arquivos saem byte a byte iguais.
// Cada arte respeita `prefers-reduced-motion`.

import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const aqui = dirname(fileURLToPath(import.meta.url));
const raiz = join(aqui, '..', '..');
const ler = (caminho) => readFileSync(join(raiz, caminho), 'utf8');

// Paleta: fundo escuro de cartão, com verde, azul e laranja para os destaques.
const COR = {
  fundo: '#0f1419',
  borda: '#263040',
  texto: '#e6edf3',
  apagado: '#9aa7b4',
  verde: '#199e70',
  azul: '#3987e5',
  laranja: '#d95926',
};
const FONTE = "'Segoe UI', -apple-system, 'Helvetica Neue', Helvetica, Arial, sans-serif";
const MOVIMENTO_REDUZIDO = '@media (prefers-reduced-motion: reduce){*{animation:none!important}}';

const fmt = (n) => Math.round(n).toLocaleString('pt-BR');
const r1 = (n) => Math.round(n * 10) / 10;

// ─── Dados ──────────────────────────────────────────────────────────────────

const geojson = JSON.parse(ler('assets/data/alertas-desmatamento.json'));
const alertas = geojson.features;

// Os biomas: cada bloco `Bioma(` do Dart, com os seus `LatLng(lat, lng)`.
const biomasDart = ler('lib/data/biomas_data.dart');
const biomas = biomasDart
  .split(/\n\s*Bioma\(/)
  .slice(1)
  .map((bloco) => ({
    nome: /nome:\s*'([^']+)'/.exec(bloco)[1],
    pontos: [...bloco.matchAll(/LatLng\(([-\d.]+),\s*([-\d.]+)\)/g)].map((m) => [
      Number(m[2]),
      Number(m[1]),
    ]),
  }));

const especies = (ler('lib/data/animais_data.dart').match(/\bnome:/g) ?? []).length;
const graficos = readdirSync(join(raiz, 'lib/widgets/charts')).filter((f) => f.endsWith('.dart')).length;
const testes = readdirSync(join(raiz, 'test'))
  .filter((f) => f.endsWith('_test.dart'))
  .reduce((soma, f) => soma + (ler(`test/${f}`).match(/^\s*(test|testWidgets)\(/gm) ?? []).length, 0);
const hectares = alertas.reduce((soma, f) => soma + (f.properties.AREAHA ?? 0), 0);
const anos = alertas.map((f) => f.properties.ANODETEC).filter(Number.isFinite);
const anoMin = Math.min(...anos);
const anoMax = Math.max(...anos);

// ─── Banner ─────────────────────────────────────────────────────────────────

// Projeção equirretangular simples, só para caber o Brasil à direita do título.
const MAPA = { x: 870, y: 30, escala: 6.2, lngMin: -74.5, latMax: 5.8 };
const px = ([lng, lat]) => [
  MAPA.x + (lng - MAPA.lngMin) * MAPA.escala,
  MAPA.y + (MAPA.latMax - lat) * MAPA.escala,
];

// O centro de um alerta é a média dos vértices do primeiro anel de cada polígono.
function centro(geometria) {
  const aneis =
    geometria.type === 'Polygon'
      ? [geometria.coordinates[0]]
      : geometria.coordinates.map((poligono) => poligono[0]);
  let lng = 0;
  let lat = 0;
  let n = 0;
  for (const anel of aneis) {
    for (const [x, y] of anel) {
      lng += x;
      lat += y;
      n++;
    }
  }
  return [lng / n, lat / n];
}

// Os 18 mil alertas viram uma grade de densidade: cada célula soma a área dos
// alertas que caem nela, e o raio do ponto cresce com a raiz dessa soma.
const CELULA = 2;
const celulas = new Map();
for (const f of alertas) {
  const [x, y] = px(centro(f.geometry));
  const chave = `${Math.floor(x / CELULA)},${Math.floor(y / CELULA)}`;
  const c = celulas.get(chave) ?? { x: 0, y: 0, n: 0, area: 0 };
  c.x += x;
  c.y += y;
  c.n++;
  c.area += f.properties.AREAHA ?? 0;
  celulas.set(chave, c);
}
const pontos = [...celulas.entries()]
  .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
  .map(([, c], i) => ({
    x: r1(c.x / c.n),
    y: r1(c.y / c.n),
    r: r1(Math.min(2.2, 0.5 + Math.sqrt(c.area) / 30)),
    grupo: i % 4,
  }));

const grupos = [0, 1, 2, 3]
  .map((g) => {
    const circulos = pontos
      .filter((p) => p.grupo === g)
      .map((p) => `<circle cx="${p.x}" cy="${p.y}" r="${p.r}"/>`)
      .join('');
    return `<g style="animation-delay:${g * 1.5}s">${circulos}</g>`;
  })
  .join('\n');

const banner = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 300" width="1200" height="300" role="img" aria-labelledby="t d">
<title id="t">EcoMapBrasil</title>
<desc id="d">Banner do EcoMapBrasil: os ${fmt(alertas.length)} alertas de desmatamento do DETER-B desenhados como pontos laranja no lugar onde cada um foi detectado, ao lado do título.</desc>
<style>
.a g{fill:${COR.laranja};opacity:.75;animation:pulso 6s ease-in-out infinite}
@keyframes pulso{0%,100%{opacity:.75}50%{opacity:.3}}
${MOVIMENTO_REDUZIDO}
</style>
<defs>
<linearGradient id="g" x1="0" x2="1"><stop offset="0" stop-color="${COR.verde}"/><stop offset=".6" stop-color="${COR.azul}"/><stop offset="1" stop-color="${COR.laranja}"/></linearGradient>
<clipPath id="c"><rect width="1200" height="300" rx="18"/></clipPath>
</defs>
<g clip-path="url(#c)">
<rect width="1200" height="300" fill="${COR.fundo}"/>
<g class="a">
${grupos}
</g>
<text x="64" y="138" font-family="${FONTE}" font-size="64" font-weight="700" fill="${COR.texto}">EcoMapBrasil</text>
<rect x="66" y="160" width="120" height="4" rx="2" fill="url(#g)"/>
<text x="64" y="204" font-family="${FONTE}" font-size="22" fill="${COR.apagado}">Desmatamento e fauna ameaçada nos biomas brasileiros</text>
<text x="64" y="238" font-family="${FONTE}" font-size="18" fill="${COR.apagado}">o app Android · Projeto Interdisciplinar da FATEC</text>
</g>
<rect x=".5" y=".5" width="1199" height="299" rx="18" fill="none" stroke="${COR.borda}"/>
</svg>
`;

// ─── Números ────────────────────────────────────────────────────────────────

const numeros = [
  [fmt(alertas.length), 'alertas no mapa'],
  [`${(hectares / 1e6).toFixed(1).replace('.', ',')} mi`, 'hectares em alerta'],
  [String(anoMax - anoMin + 1), `anos (${anoMin}–${anoMax})`],
  [String(biomas.length), 'biomas'],
  [String(especies), 'espécies no catálogo'],
  [String(testes), 'testes'],
];

const colunas = numeros
  .map(([valor, rotulo], i) => {
    const cx = 100 + i * 200;
    return `<text x="${cx}" y="72" text-anchor="middle" font-family="${FONTE}" font-size="40" font-weight="700" fill="${COR.texto}">${valor}</text>
<rect x="${cx - 14}" y="86" width="28" height="3" rx="1.5" fill="${[COR.laranja, COR.laranja, COR.azul, COR.verde, COR.verde, COR.azul][i]}"/>
<text x="${cx}" y="114" text-anchor="middle" font-family="${FONTE}" font-size="15" fill="${COR.apagado}">${rotulo}</text>`;
  })
  .join('\n');

const divisorias = [200, 400, 600, 800, 1000]
  .map((x) => `<line x1="${x}" y1="36" x2="${x}" y2="114" stroke="${COR.borda}"/>`)
  .join('');

const descricao = numeros.map(([v, r]) => `${v} ${r}`).join(', ');
const cartao = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 150" width="1200" height="150" role="img" aria-labelledby="t d">
<title id="t">O EcoMapBrasil em números</title>
<desc id="d">${descricao}.</desc>
<style>${MOVIMENTO_REDUZIDO}</style>
<rect x=".5" y=".5" width="1199" height="149" rx="18" fill="${COR.fundo}" stroke="${COR.borda}"/>
${divisorias}
${colunas}
</svg>
`;

writeFileSync(join(aqui, 'banner.svg'), banner);
writeFileSync(join(aqui, 'numeros.svg'), cartao);
console.log(
  `banner.svg: ${pontos.length} pontos de ${fmt(alertas.length)} alertas, ${biomas.length} biomas · ` +
    `numeros.svg: ${descricao} · gráficos: ${graficos}`,
);
