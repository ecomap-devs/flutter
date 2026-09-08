# 🌳 EcoMapBrasil — Flutter

> Plataforma de conscientização sobre desmatamento e fauna ameaçada nos biomas brasileiros.
> Versão **Flutter** (web + Android) do Projeto Interdisciplinar, migrada da versão React.

---

## 📖 Sobre

Reescrita em Flutter do [EcoMapBrasil](https://ecomapbrasil-17756.web.app/), originalmente
feito em React no semestre anterior. Mesmo produto, mesma base de dados — agora rodando
como app Android **e** como site, a partir de um código só.

---

## ✨ O que tem

| Tela | O que faz |
|---|---|
| **Início** | Landing com estatísticas, quatro gráficos (barras, rosca, linha e radar) desenhados em `CustomPainter`, linha do tempo do desmatamento, soluções práticas e as avaliações da comunidade |
| **Mapa** | Mapa interativo em `flutter_map` sobre imagens de satélite, com os 6 biomas e a camada de alertas do DETER-B. Toque no bioma abre área, percentual desmatado e descrição |
| **Animais** | Catálogo de 9 espécies com busca, filtros por bioma e status, gráfico de tendência populacional e ficha detalhada com as principais ameaças |
| **Conta** | Cadastro e login por e-mail/senha (Firebase Auth), avatar no Supabase Storage, avaliações com nota em estrelas salvas em tempo real no Firestore |

Layout responsivo: `NavigationBar` no celular, `NavigationRail` no desktop, grades que
se ajustam à largura disponível.

---

## 🛠️ Tecnologias

- **Flutter 3.47** / Dart 3.13 — Material 3
- **flutter_map** + **latlong2** — mapa (o equivalente do Leaflet da versão web)
- **firebase_core / firebase_auth / cloud_firestore** — conta e avaliações
- **supabase_flutter** — Storage das imagens e dos avatares
- **image_picker** — foto de perfil no cadastro
- Gráficos em **`CustomPainter`**, sem biblioteca de charts — o equivalente ao SVG
  escrito à mão da versão React

---

## 🚀 Como rodar

**Pré-requisitos:** Flutter 3.47+, e Android SDK para rodar no celular/emulador.

```bash
# 1. Clone e instale
git clone <url-do-repo>
cd ecomapbrasil
flutter pub get

# 2. Configure as credenciais
cp env.example.json env.json    # depois preencha o env.json

# 3. Rode
flutter run --dart-define-from-file=env.json              # celular/emulador
flutter run -d chrome --dart-define-from-file=env.json    # navegador
```

> **O `--dart-define-from-file` não é opcional.** Sem ele o app sobe numa tela que
> lista exatamente quais variáveis faltam, em vez de quebrar lá na frente, no login.

### Build

```bash
flutter build web --dart-define-from-file=env.json
flutter build apk --release --dart-define-from-file=env.json
```

---

## 🔑 Credenciais e segurança

O `env.json` está no `.gitignore`; o `env.example.json` mostra os nomes das variáveis.

**Importante, e é o que a versão React ensinou:** a `apiKey` do Firebase e a `anon key`
do Supabase são **públicas por design**. Elas vão para o bundle web e para o APK de
qualquer jeito — APK é descompilável. Tirá-las do código evita vazamento no
repositório, mas **quem protege o dado são as Firestore Rules e o RLS do Supabase**.

O `.gitignore` também cobre, desde o primeiro commit:

```
android/app/google-services.json      # gerado pelo `flutterfire configure`
ios/Runner/GoogleService-Info.plist    # idem
lib/firebase_options.dart              # idem — nasce com as chaves dentro
android/key.properties, *.jks, *.keystore
env.json
```

⚠️ **Pendente:** as chaves em uso são as mesmas da versão React, que ficaram expostas
num repositório público. Precisam ser **rotacionadas** — nova anon key no Supabase e
restrição por domínio na API key do Firebase — antes de o projeto ir para produção.

---

## 📁 Estrutura

```
lib/
├── config/env.dart              # credenciais via --dart-define, com checagem
├── data/                        # dados estáticos portados do React
│   ├── animais_data.dart        # catálogo de espécies
│   ├── biomas_data.dart         # polígonos dos 6 biomas
│   └── home_data.dart           # estatísticas, soluções, linha do tempo
├── models/                      # Animal, Bioma, AlertaDesmatamento, Avaliacao
├── services/                    # Firebase, Supabase, leitura do GeoJSON
├── screens/                     # app_shell, home, mapa, animais
├── widgets/
│   ├── charts/                  # barras, rosca, linha, radar (CustomPainter)
│   ├── auth_modal.dart
│   ├── reviews_section.dart
│   └── estrelas.dart
└── theme/app_theme.dart         # paleta e breakpoints herdados do React

assets/
├── data/alertas-desmatamento.json   # GeoJSON do DETER-B/INPE (6,7 MB)
└── img/logo.png
```

---

## 🧪 Testes

```bash
flutter test
```

19 testes cobrindo o cálculo de tendência populacional, a integridade dos polígonos
dos biomas, o parser de GeoJSON (incluindo geometria inválida e `properties` ausente)
e os widgets de nota e de configuração ausente.

---

## 📊 Sobre os dados

A camada de alertas usa dados públicos do **DETER-B (INPE)**, com bioma, estado,
município, área em hectares e ano por polígono.

Os demais números — percentuais por bioma, séries populacionais e a linha do tempo —
são valores de referência embutidos no código, herdados da versão React. Substituí-los
por dados oficiais (PRODES/INPE, ICMBio, IBGE, MapBiomas) segue como próxima etapa.

---

## 👥 Equipe

Projeto Interdisciplinar — **Vinicius**, **Bruno**, **Cesar**, **João Flávio** e **João Gabriel**.

---

## 📄 Licença

MIT. Projeto acadêmico, sem fins lucrativos.
