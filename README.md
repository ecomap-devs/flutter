<div align="center">

<img src="assets/img/logo.png" alt="EcoMapBrasil" width="96" />

# 🌳 EcoMapBrasil

**Desmatamento e fauna ameaçada nos biomas brasileiros — em mapa, gráfico e ficha de espécie.**

Projeto Interdisciplinar da FATEC · versão Flutter para **Android** e **web**

[![CI](https://img.shields.io/badge/CI-analyze%20%C2%B7%20test%20%C2%B7%20build-16a34a?style=flat-square)](.github/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%C2%B7%20Firestore-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Supabase](https://img.shields.io/badge/Supabase-Storage-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![Licença MIT](https://img.shields.io/badge/licença-MIT-blue?style=flat-square)](LICENSE)

</div>

---

## 📖 Sobre

O **EcoMapBrasil** reúne num lugar só o que costuma estar espalhado em relatório e
planilha: onde o desmatamento acontece, quais espécies estão ameaçadas e o que dá
para fazer a respeito.

Esta é a reescrita em **Flutter** do projeto [originalmente feito em React](https://ecomapbrasil-17756.web.app/)
no semestre anterior. Mesmo produto, mesma base de dados — agora rodando como app
Android **e** como site, a partir de um código só.

---

## ✨ O que tem

<table>
<tr>
<td width="25%" valign="top">

### 🏠 Início

Estatísticas do desmatamento, **quatro gráficos** desenhados no canvas — barras,
rosca, linha e radar —, linha do tempo de duas décadas, soluções práticas e as
avaliações da comunidade.

</td>
<td width="25%" valign="top">

### 🗺️ Mapa

Mapa interativo sobre imagens de satélite, com os **6 biomas** destacados e a camada
de **alertas do DETER-B**. Toque no bioma para ver área, percentual desmatado e
descrição.

</td>
<td width="25%" valign="top">

### 🐆 Animais

Catálogo de **9 espécies** com busca por nome, filtros por bioma e status de
conservação, gráfico de tendência populacional e ficha com as principais ameaças.

</td>
<td width="25%" valign="top">

### 👤 Conta

Cadastro e login por e-mail/senha, foto de perfil e **avaliações com nota em
estrelas**, salvas em tempo real e visíveis para todo mundo.

</td>
</tr>
</table>

Layout responsivo de verdade: `NavigationBar` no celular, `NavigationRail` no
desktop, e grades que recalculam as colunas conforme a largura disponível.

---

## 🛠️ Stack

| Camada | Escolha | Por quê |
|---|---|---|
| **App** | Flutter 3.47 · Dart 3.13 · Material 3 | Um código para Android e web |
| **Mapa** | `flutter_map` + `latlong2` | O irmão do Leaflet usado na versão React |
| **Gráficos** | `CustomPainter` puro | Sem lib de charts — equivalente ao SVG escrito à mão do original |
| **Conta e dados** | `firebase_auth` · `cloud_firestore` | Auth por e-mail/senha e avaliações em tempo real |
| **Imagens** | `supabase_flutter` | Storage das fotos de espécies e dos avatares |

---

## 🚀 Como rodar

> **Pré-requisitos:** Flutter 3.47+ e, para o app, o Android SDK.

```bash
# 1. Clone e instale
git clone <url-do-repo>
cd ecomapbrasil
flutter pub get

# 2. Configure as credenciais
cp env.example.json env.json    # depois preencha o env.json

# 3. Rode
flutter run --dart-define-from-file=env.json              # celular ou emulador
flutter run -d chrome --dart-define-from-file=env.json    # navegador
```

> [!IMPORTANT]
> O `--dart-define-from-file` **não é opcional**. Sem ele o app abre numa tela
> listando exatamente quais variáveis faltam — em vez de subir normalmente e
> quebrar lá na frente, no login.

### Build

```bash
flutter build web --dart-define-from-file=env.json
flutter build apk --release --dart-define-from-file=env.json
```

### Testes

```bash
flutter test        # 19 testes
flutter analyze     # tem que dar "No issues found!"
```

---

## 🔑 Credenciais e segurança

O `env.json` está no `.gitignore`; o `env.example.json` mostra os nomes das
variáveis. Também ficam de fora do repositório, de propósito:

```
lib/firebase_options.dart              # o flutterfire configure gera com as chaves dentro
android/app/google-services.json       # idem
ios/Runner/GoogleService-Info.plist     # idem
android/key.properties, *.jks, *.keystore
```

### Regras de acesso — o que de fato protege

As **Firestore Rules** estão versionadas em [`firestore.rules`](firestore.rules) e
são publicadas por `firebase deploy --only firestore:rules`. Antes elas moravam só
no console, e ninguém do grupo sabia dizer o que estava valendo.

Mexeu em como o app lê ou grava dado? A regra correspondente entra nesse arquivo e é
revisada no PR.

> [!WARNING]
> **Chave pública de cliente não é segredo.** A `apiKey` do Firebase e a
> *publishable key* do Supabase vão para o bundle web e para o APK de qualquer
> jeito — APK é descompilável. Tirá-las do código evita vazamento no repositório, mas **quem
> protege o dado são as Firestore Rules e o RLS do Supabase**.

### Uma chave por plataforma

Web e Android usam **credenciais diferentes do Firebase**, e não é preciosismo: a
restrição de aplicativo do Google Cloud é *exclusiva*. A chave web é travada por
referenciador HTTP, e requisição sem header `Referer` — o caso de todo app nativo —
seria recusada. Uma chave só para os dois alvos significa ou web desprotegida, ou
Android quebrado.

| Variável | Restrição |
|---|---|
| `FIREBASE_API_KEY_WEB` | Referenciador HTTP (`*.web.app`, `*.firebaseapp.com`, `localhost`) + 4 APIs |
| `FIREBASE_API_KEY_ANDROID` | 4 APIs. **Falta** package name + SHA-1, que só existe com o keystore de release |

`Env` escolhe pela plataforma com `kIsWeb`, e o ramo morto é eliminado no build —
o bundle web não carrega a credencial do Android.

**Rotação concluída em 08/09/2026:** as `anon` keys do Supabase viraram legado e
foram **desativadas**; o projeto usa `sb_publishable_...`. As Firestore Rules foram
publicadas.

---

## 🔄 CI e deploy

Tudo automático, sem `firebase deploy` na mão:

| Quando | O que acontece |
|---|---|
| **Push ou PR** | `dart format` · `flutter analyze` · `flutter test` · build web · build APK |
| **PR aberto** | Deploy num canal de **preview com URL própria**, que expira em 7 dias |
| **Merge na `main`** | Testes e **deploy no Firebase Hosting** |

O APK debug fica anexado à execução da CI por 14 dias — dá para o grupo baixar e
instalar no celular sem ter ambiente Flutter montado.

Configuração em [`.github/workflows/`](.github/workflows/).

---

## 📁 Estrutura

```
lib/
├── config/env.dart              credenciais via --dart-define, com checagem
├── data/                        dados estáticos portados do React
│   ├── animais_data.dart          catálogo de espécies
│   ├── biomas_data.dart           polígonos dos 6 biomas
│   └── home_data.dart             estatísticas, soluções, linha do tempo
├── models/                      Animal · Bioma · AlertaDesmatamento · Avaliacao
├── services/                    Firebase · Supabase · leitura do GeoJSON
├── screens/                     app_shell · home · mapa · animais
├── widgets/
│   ├── charts/                    barras · rosca · linha · radar
│   ├── auth_modal.dart
│   ├── reviews_section.dart
│   └── estrelas.dart
└── theme/app_theme.dart         paleta e breakpoints herdados do React

assets/
├── data/alertas-desmatamento.json   GeoJSON do DETER-B/INPE (6,7 MB)
└── img/logo.png
```

---

## 📊 Sobre os dados

A camada de alertas do mapa usa dados públicos de detecção do **DETER-B (INPE)**,
com bioma, estado, município, área em hectares e ano por polígono.

Os demais números — percentuais por bioma, séries populacionais das espécies e a
linha do tempo — são **valores de referência embutidos no código**, herdados da
versão React e usados para validar a experiência visual. Substituí-los por uma
camada alimentada com dados oficiais (PRODES/INPE, ICMBio, IBGE e MapBiomas) é a
próxima etapa do projeto.

---

## 🤝 Contribuindo

As regras do repositório estão em **[AGENTS.md](AGENTS.md)** — convenções de código,
padrão de commit, o que roda na CI e o que nunca pode ser commitado. Leia antes do
primeiro PR.

Resumo: branch a partir da `main`, `dart format` + `analyze` + `test` antes de abrir
o PR, e uma revisão de alguém do grupo para mergear.

A `main` é protegida: push direto é recusado, e o merge exige **1 aprovação** mais os
três checks da CI (`Análise e testes`, `Build web`, `Build APK`) passando. Cada PR
ganha uma URL de preview automática — cole no PR se ajudar quem for revisar.

---

## 👥 Equipe

Projeto Interdisciplinar desenvolvido por
**Vinicius** · **Bruno** · **Cesar** · **João Flávio** · **João Gabriel**

---

## 📄 Licença

Distribuído sob a licença [MIT](LICENSE). Projeto acadêmico, sem fins lucrativos.
