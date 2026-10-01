// Gera lib/data/biomas_contornos.dart a partir do limite oficial dos biomas.
//
// Fonte: IBGE, "Biomas do Brasil", escala 1:5.000.000 (Biomas_5000mil.zip):
// https://geoftp.ibge.gov.br/informacoes_ambientais/estudos_ambientais/biomas/vetores/
//
// Ate 01/10/2026 os contornos eram retangulos herdados da versao React, e
// por isso o mapa nem os desenhava: mostrar aquilo seria apresentar fronteira
// inventada como se fosse real. Com o limite do IBGE, o mapa pode desenhar.
//
// Como refazer (Node 18+):
//
//   1. Baixe e descompacte o Biomas_5000mil.zip. O .prj vem como
//      "Biomas5000.prj.txt": renomeie para "Biomas5000.prj".
//   2. Separe os seis biomas terrestres (o arquivo traz tambem as zonas
//      marinhas) e simplifique para o tamanho de um mapa de celular:
//
//      npx mapshaper@0.6 Biomas5000.shp encoding=latin1 \
//        -filter '!/Zona|Mar|Costeir|Continental/i.test(NOM_BIOMA)' \
//        -simplify 3% keep-shapes \
//        -filter-islands min-area=2000km2 \
//        -o biomas.json format=geojson precision=0.001
//
//   3. node tool/biomas/gerar.mjs biomas.json
//   4. dart format lib/data/biomas_contornos.dart

import { readFileSync, writeFileSync } from "node:fs";

const entrada = process.argv[2];
if (!entrada) {
  console.error("uso: node tool/biomas/gerar.mjs <biomas.json>");
  process.exit(1);
}

// Nome no IBGE -> prefixo da constante em Dart.
const NOMES = {
  "Amazônia": "amazonia",
  "Cerrado": "cerrado",
  "Caatinga": "caatinga",
  "Mata Atlântica": "mataAtlantica",
  "Pantanal": "pantanal",
  "Pampa": "pampa",
};

const geo = JSON.parse(readFileSync(entrada, "utf8"));
const porNome = new Map(geo.features.map((f) => [f.properties.NOM_BIOMA, f]));

const faltando = Object.keys(NOMES).filter((n) => !porNome.has(n));
if (faltando.length) {
  console.error("Biomas ausentes no GeoJSON:", faltando.join(", "));
  process.exit(1);
}

// ~1 km de resolucao: mais que suficiente na escala 1:5.000.000.
const coord = (v) => Number(v.toFixed(2));
const anel = (pontos) =>
  "[\n" +
  pontos.map(([lng, lat]) => `LatLng(${coord(lat)}, ${coord(lng)}),`).join("\n") +
  "\n]";

let saida = `// GERADO por tool/biomas/gerar.mjs — nao edite a mao.
//
// Limite oficial dos biomas: IBGE, "Biomas do Brasil", 1:5.000.000,
// simplificado para o mapa do app. Para refazer, veja o gerador.

import 'package:latlong2/latlong.dart';
`;

for (const [nome, prefixo] of Object.entries(NOMES)) {
  const g = porNome.get(nome).geometry;
  const poligonos = g.type === "Polygon" ? [g.coordinates] : g.coordinates;
  // O primeiro anel de cada poligono e o contorno; os demais sao buracos
  // (areas cercadas pelo bioma que o IBGE classifica como massa d'agua).
  const contornos = poligonos.map((p) => p[0]);
  const buracos = poligonos.flatMap((p) => p.slice(1));
  const pontos = poligonos.flat().reduce((s, a) => s + a.length, 0);

  saida += `
/// ${nome}: ${contornos.length} parte(s), ${buracos.length} buraco(s), ${pontos} pontos.
const ${prefixo}Contornos = <List<LatLng>>[
${contornos.map(anel).join(",\n")}
];

const ${prefixo}Buracos = <List<LatLng>>[
${buracos.map(anel).join(",\n")}
];
`;
}

const destino = new URL("../../lib/data/biomas_contornos.dart", import.meta.url);
writeFileSync(destino, saida);
console.log("ok:", destino.pathname);
