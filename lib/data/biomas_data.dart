import 'package:latlong2/latlong.dart';
import '../models/bioma.dart';

/// Poligonos simplificados dos seis biomas — porte de `biomesData` do Mapa.jsx.
///
/// No GeoJSON original a ordem e [lng, lat]; aqui ja vem como LatLng(lat, lng).
final biomas = <Bioma>[
  Bioma(
    nome: 'Amazônia',
    areaKm2: 5500000,
    percentualDesmatado: 78,
    descricao: 'Maior floresta tropical do mundo',
    poligonos: const [
      [
        LatLng(5.27, -73.98),
        LatLng(5.27, -60.11),
        LatLng(2.82, -49.95),
        LatLng(-2.33, -44.30),
        LatLng(-16.34, -48.63),
        LatLng(-18.04, -57.30),
        LatLng(-11.87, -67.81),
        LatLng(-9.19, -70.09),
        LatLng(-7.36, -73.98),
        LatLng(5.27, -73.98),
      ],
    ],
  ),
  Bioma(
    nome: 'Cerrado',
    areaKm2: 2036448,
    percentualDesmatado: 45,
    descricao: 'Savana tropical com grande biodiversidade',
    poligonos: const [
      [
        LatLng(-18.04, -57.30),
        LatLng(-16.34, -48.63),
        LatLng(-2.33, -44.30),
        LatLng(-2.33, -42.54),
        LatLng(-14.24, -35.24),
        LatLng(-20.30, -35.24),
        LatLng(-24.53, -46.63),
        LatLng(-24.53, -52.43),
        LatLng(-18.04, -57.30),
      ],
    ],
  ),
  Bioma(
    nome: 'Caatinga',
    areaKm2: 844453,
    percentualDesmatado: 15,
    descricao: 'Vegetação seca adaptada ao semiárido',
    poligonos: const [
      [
        LatLng(-2.33, -42.54),
        LatLng(-2.33, -35.24),
        LatLng(-17.34, -34.80),
        LatLng(-17.34, -42.54),
        LatLng(-2.33, -42.54),
      ],
    ],
  ),
  Bioma(
    nome: 'Mata Atlântica',
    areaKm2: 1110182,
    percentualDesmatado: 32,
    descricao: 'Floresta costeira altamente ameaçada',
    // MultiPolygon na fonte: tres aneis separados.
    poligonos: const [
      [
        LatLng(-5.50, -35.00),
        LatLng(-5.50, -34.80),
        LatLng(-17.50, -34.80),
        LatLng(-17.50, -35.00),
        LatLng(-5.50, -35.00),
      ],
      [
        LatLng(-19.00, -48.50),
        LatLng(-19.00, -40.00),
        LatLng(-33.75, -40.00),
        LatLng(-33.75, -51.00),
        LatLng(-23.00, -51.00),
        LatLng(-19.00, -48.50),
      ],
      [
        LatLng(-12.50, -38.50),
        LatLng(-12.50, -34.80),
        LatLng(-18.00, -34.80),
        LatLng(-18.00, -38.50),
        LatLng(-12.50, -38.50),
      ],
    ],
  ),
  Bioma(
    nome: 'Pantanal',
    areaKm2: 150355,
    percentualDesmatado: 12,
    descricao: 'Maior planície alagada do mundo',
    poligonos: const [
      [
        LatLng(-14.24, -59.18),
        LatLng(-14.24, -55.67),
        LatLng(-22.27, -55.67),
        LatLng(-22.27, -59.18),
        LatLng(-14.24, -59.18),
      ],
    ],
  ),
  Bioma(
    nome: 'Pampa',
    areaKm2: 176496,
    percentualDesmatado: 25,
    descricao: 'Campos nativos do Sul do Brasil',
    poligonos: const [
      [
        LatLng(-28.18, -57.65),
        LatLng(-28.18, -49.70),
        LatLng(-33.75, -49.70),
        LatLng(-33.75, -57.65),
        LatLng(-28.18, -57.65),
      ],
    ],
  ),
];
