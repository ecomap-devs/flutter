# AGENTS.md — regras do EcoMapBrasil

Regras para quem mexe neste repositório: os cinco do grupo e qualquer assistente
de IA (Claude Code, Copilot, Codex, Gemini). Vale para todos igualmente.

---

## O projeto em três linhas

App Flutter (web + Android) sobre desmatamento e fauna ameaçada nos biomas
brasileiros. Projeto Interdisciplinar da FATEC, migrado de uma versão React do
semestre anterior. Backend: Firebase (Auth, Firestore) e Supabase (Storage).

---

## 🔴 Regra número um: credenciais

**Nenhuma chave, token ou segredo entra no código-fonte. Nunca.**

As credenciais vivem em `env.json`, que está no `.gitignore`, e chegam ao app por
`--dart-define-from-file`. Os nomes das variáveis estão em `env.example.json`.

```bash
flutter run   --dart-define-from-file=env.json
flutter build web --dart-define-from-file=env.json
```

Já está no `.gitignore`, e **não tire de lá**:

| Arquivo | Por quê |
|---|---|
| `env.json` | As credenciais |
| `lib/firebase_options.dart` | O `flutterfire configure` gera com as chaves dentro |
| `android/app/google-services.json` | Idem |
| `ios/Runner/GoogleService-Info.plist` | Idem |
| `android/key.properties`, `*.jks`, `*.keystore` | Assinatura de release |

Se rodar `flutterfire configure`, os arquivos vão aparecer na sua máquina — é
esperado, e eles não sobem. **Não force o commit deles.**

### O que "segredo" quer dizer aqui

A `apiKey` do Firebase e a `anon key` do Supabase são **públicas por design**: vão
para o bundle web e para o APK de qualquer jeito, e APK é descompilável. Tirá-las
do código evita vazamento no repositório, mas **não protege dado nenhum**.

Quem protege são as **Firestore Rules** e o **RLS do Supabase**. Se você for mexer
em como o app lê ou escreve dados, a pergunta certa é *"a regra está fechada?"*,
não *"a chave está escondida?"*.

O que **nunca** pode chegar ao cliente, em `env.json` ou fora dele: `service_role`
do Supabase, service account do Firebase, qualquer token de API paga. Esses só
vivem em servidor.

---

## Antes de abrir PR

Rode os três, nesta ordem. É o mesmo que a CI roda — falhar aqui é falhar lá.

```bash
dart format .
flutter analyze     # tem que dar "No issues found!"
flutter test        # tem que passar inteiro
```

`flutter analyze` limpo não é meta, é piso. Não abra PR com warning novo.

---

## Como escrever código aqui

### Idioma
- **Código em português**: classes, métodos, variáveis, campos (`Bioma`, `carregar()`,
  `percentualDesmatado`).
- **Exceção**: o que vem de API externa mantém o nome de lá (`Timestamp`,
  `photoURL`, `uid`, as chaves do GeoJSON como `AREAHA` e `ANODETEC`).
- Comentários e documentação em português.

### Estrutura de pastas
```
lib/
├── config/     credenciais e configuração
├── data/       dados estáticos (catálogo, biomas, textos da Home)
├── models/     classes de domínio + parsers
├── services/   Firebase, Supabase, leitura de arquivo
├── screens/    uma tela por arquivo
├── widgets/    componentes reutilizáveis; charts/ para os gráficos
└── theme/      cores e breakpoints
```

Arquivo novo vai na pasta que corresponde ao papel dele. Se não couber em nenhuma,
provavelmente o papel está confuso — repense antes de criar pasta nova.

### Convenções que este código já segue

**Widget que não muda é `const`.** O analyzer cobra, e é o que evita rebuild à toa.

**Modelo é imutável.** `@immutable`, campos `final`, construtor `const` quando dá.

**Parser não estoura, devolve `null`.** Veja `AlertaDesmatamento.doGeoJson`: o
GeoJSON tem 6,7 MB e milhares de features; uma malformada não pode derrubar o mapa
inteiro. Prefira pular o registro ruim a explodir a tela.

**Imagem de rede sempre tem `errorBuilder`.** As fotos vêm do Supabase e podem
falhar (offline, bucket movido). Cai num placeholder, nunca no ícone de erro cinza
do Flutter.

**Gráfico é `CustomPainter`, não biblioteca.** Foi decisão de projeto, herdada do
SVG escrito à mão da versão React. Se precisar de um gráfico novo, pinte no canvas
como os quatro que já existem em `lib/widgets/charts/`.

**Trabalho pesado sai da thread da UI.** O GeoJSON é parseado em `compute()`. Se
adicionar processamento caro, siga o mesmo caminho.

**Erro de rede vira mensagem em português.** Veja `AuthService.mensagemDeErro()`.
Nunca mostre o código cru do Firebase para quem usa o app.

### Responsividade
Use `Breakpoints.ehMobile(context)` (`app_theme.dart`), não `MediaQuery` solto.
Mobile = `NavigationBar`; desktop = `NavigationRail`. Grades calculam colunas a
partir da largura disponível, com `LayoutBuilder`.

---

## Testes

Teste novo em `test/`. Cubra pelo menos:

- **Cálculo** — a lógica de tendência populacional, formatação, agregação.
- **Parser** — o caminho feliz **e** o dado malformado. Todo parser deste repo tem
  teste de entrada inválida, e é assim que continua.
- **Integridade dos dados** — se você adicionar espécie ou bioma, os testes de
  "série e anos do mesmo tamanho" e "anel fecha" já cobrem, mas confira se passam.

Não precisa testar layout pixel a pixel. Teste comportamento: o widget dispara o
callback? A tela de erro lista o que falta?

---

## Git

### Branches
`main` é protegida. Trabalhe em branch e abra PR.

```
feat/nome-curto      funcionalidade nova
fix/nome-curto       correção
docs/nome-curto      documentação
```

### Commits
Mensagem em português, imperativo, explicando **o porquê** quando não for óbvio.

```
Adicionar filtro por região no catálogo

O filtro por bioma não bastava: três espécies do Sudeste ficavam
espalhadas entre Mata Atlântica e Cerrado, e quem busca por região
não encontrava.
```

Um commit por ideia. Não misture correção de bug com refatoração.

### Pull requests
- Descreva o que muda e por quê.
- A CI precisa passar (análise, testes, build web e APK).
- Cada PR ganha uma **URL de preview** automática — cole no PR se ajudar a revisão.
- Peça revisão de pelo menos uma pessoa do grupo.

---

## CI e deploy

Tudo automático, em `.github/workflows/`:

| Quando | O que acontece |
|---|---|
| Push ou PR | `dart format`, `flutter analyze`, `flutter test`, build web e APK |
| PR aberto | Preview em URL própria, expira em 7 dias |
| Merge na `main` | Testes e deploy no Firebase Hosting |

O APK debug fica anexado à execução da CI por 14 dias — dá para baixar e instalar
no celular sem ter Flutter montado.

**Não rode `firebase deploy` da sua máquina.** O deploy sai da `main`, pela CI, a
partir de código revisado. Deploy manual de árvore local não é reproduzível.

---

## Para assistentes de IA

Tudo acima vale. Além disso:

- **Não invente dado ambiental.** Os números deste repo vêm da versão React e são
  valores de referência declarados como tais no README. Se precisar de número novo,
  peça a fonte — não preencha com estimativa plausível.
- **Não crie `firebase_options.dart` com chaves dentro**, nem sugira `flutterfire
  configure` sem avisar que o arquivo é ignorado de propósito.
- **Não suba nada** (`git push`, `firebase deploy`) sem pedido explícito.
- **Rode `flutter analyze` e `flutter test`** antes de dizer que terminou, e relate
  o resultado real — inclusive quando falha.
- **Build passar não prova que credencial chegou.** Variável ausente vira `undefined`
  e compila liso. Para provar, tire o `env.json`, rebuilde, e confirme que o valor
  sumiu do bundle. Foi assim que a versão React falhava calada.
- Se uma suspeita sua não se confirmar no código, diga isso em vez de manter o
  achado mais vistoso. Achado falso contamina a confiança nos verdadeiros.

---

## Pendências conhecidas

- 🔴 **Rotacionar as chaves** herdadas da versão React — ficaram expostas num
  repositório público. Nova anon key no Supabase, restrição por domínio na API key
  do Firebase.
- 🔴 **Conferir as Firestore Rules** de `avaliacoes` e `usuarios`. Não existe
  `firestore.rules` versionado; as regras foram configuradas pelo console.
- 🟡 **GeoJSON de 6,7 MB embarcado** nos assets. Funciona, mas engorda o APK e o
  visitante da web baixa tudo. Alternativas: servir remoto ou simplificar polígonos.
- 🟡 **Dados de referência hardcoded** em `lib/data/`. Próxima etapa é trocar por
  fonte oficial (PRODES/INPE, ICMBio, IBGE, MapBiomas).
