import '../models/bioma.dart';
import 'biomas_contornos.dart';

/// Os seis biomas terrestres.
///
/// Os contornos sao o limite oficial do IBGE (`biomas_contornos.dart`, gerado
/// por `tool/biomas/gerar.mjs`). Area, percentual e descricao continuam sendo
/// os valores de referencia herdados do `biomesData` do Mapa.jsx (README,
/// "Sobre os dados").
final biomas = <Bioma>[
  const Bioma(
    nome: 'Amazônia',
    areaKm2: 5500000,
    percentualDesmatado: 78,
    descricao: 'Maior floresta tropical do mundo',
    poligonos: amazoniaContornos,
    buracos: amazoniaBuracos,
  ),
  const Bioma(
    nome: 'Cerrado',
    areaKm2: 2036448,
    percentualDesmatado: 45,
    descricao: 'Savana tropical com grande biodiversidade',
    poligonos: cerradoContornos,
    buracos: cerradoBuracos,
  ),
  const Bioma(
    nome: 'Caatinga',
    areaKm2: 844453,
    percentualDesmatado: 15,
    descricao: 'Vegetação seca adaptada ao semiárido',
    poligonos: caatingaContornos,
    buracos: caatingaBuracos,
  ),
  const Bioma(
    nome: 'Mata Atlântica',
    areaKm2: 1110182,
    percentualDesmatado: 32,
    descricao: 'Floresta costeira altamente ameaçada',
    poligonos: mataAtlanticaContornos,
    buracos: mataAtlanticaBuracos,
  ),
  const Bioma(
    nome: 'Pantanal',
    areaKm2: 150355,
    percentualDesmatado: 12,
    descricao: 'Maior planície alagada do mundo',
    poligonos: pantanalContornos,
    buracos: pantanalBuracos,
  ),
  const Bioma(
    nome: 'Pampa',
    areaKm2: 176496,
    percentualDesmatado: 25,
    descricao: 'Campos nativos do Sul do Brasil',
    poligonos: pampaContornos,
    buracos: pampaBuracos,
  ),
];
