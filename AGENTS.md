# AGENTS.md — regras do EcoMapBrasil

Regras para quem mexe neste repositório: os cinco do grupo e qualquer assistente
de IA (Claude Code, Copilot, Codex, Gemini). Vale para todos igualmente.

---

## O projeto em três linhas

App Android em Flutter sobre desmatamento e fauna ameaçada nos biomas brasileiros. O
site é o [semestre-4-nextjs](https://github.com/ecomap-devs/semestre-4-nextjs), no mesmo backend. Projeto Interdisciplinar da FATEC, migrado de uma versão React do
semestre anterior. Backend: Firebase (Auth, Firestore) e Supabase (Storage).

---

## 🔴 Regra número um: credenciais

**Nenhuma chave, token ou segredo entra no código-fonte. Nunca.**

As credenciais vivem em `env.json`, que está no `.gitignore`, e chegam ao app por
`--dart-define-from-file`. Os nomes das variáveis estão em `env.example.json`.

```bash
flutter run   --dart-define-from-file=env.json
flutter build apk --dart-define-from-file=env.json
```

Já está no `.gitignore`, e **não tire de lá**:

| Arquivo | Por quê |
|---|---|
| `env.json` | As credenciais |
| `lib/firebase_options.dart` | O `flutterfire configure` gera com as chaves dentro |
| `android/app/google-services.json` | Idem |
| `ios/Runner/GoogleService-Info.plist` | Idem |
| `android/key.properties`, `*.jks`, `*.keystore` | Assinatura de release |

**Uma exceção, e é de propósito:** `android/keystore/debug.jks` **é versionado**. Sem
um keystore de debug compartilhado, cada pessoa assinaria com o próprio
`~/.android/debug.keystore` e teria um SHA-1 diferente — e como a chave de API do
Firebase é restrita por package + SHA-1, o login quebraria para quem não estivesse na
lista, em silêncio, aparecendo como erro genérico de autenticação. Keystore de debug
não é segredo: assina apenas desenvolvimento, não publica nada, e a senha `android` é
a convenção documentada do Android. O de **release nunca entra no repositório**.

Se rodar `flutterfire configure`, os arquivos vão aparecer na sua máquina — é
esperado, e eles não sobem. **Não force o commit deles.**

### As regras ficam versionadas

As Firestore Rules estão em [`firestore.rules`](firestore.rules), não só no console.
Coleção nova **nasce fechada** (`allow read, write: if false`) — para liberar, a
regra entra no arquivo e é revisada no PR, **com caso novo em
`firestore-testes/regras.test.js`**. Cada regra de "nega" de lá corresponde a um ataque
concreto; os da revisão de 01/10/2026 estão todos lá.

```bash
cd firestore-testes && npm install && npm test   # emulador; precisa de Java 21+
firebase deploy --only firestore:rules           # só depois do merge
```

As regras valem também para o site (semestre-4-nextjs): mudança que exija outro formato
de escrita precisa sair nos dois clientes **antes** de as regras novas serem publicadas.

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
A `main` **é protegida de verdade** — não é só convenção. O GitHub recusa push
direto e exige, antes do merge:

| Regra | Valor |
|---|---|
| Pull request obrigatório | sim |
| Aprovações necessárias | **1** |
| Review antiga é descartada ao subir commit novo | sim |
| Checks que precisam passar | `Análise e testes`, `Build APK` |
| Conversas do review resolvidas | sim |
| Force push e deleção da branch | bloqueados |

> **Uma saída de emergência, e ela é consciente:** a proteção **não se aplica a
> administradores da organização**. É o que permite corrigir a `main` quando algo
> quebra e não há ninguém acordado para aprovar. Use isso como exceção — se virar
> hábito, o processo acima deixa de existir na prática.

Não exigimos que a branch esteja atualizada com a `main` antes do merge: num grupo
de cinco isso obrigaria a um rebase a cada merge alheio, e o custo não compensa.

Trabalhe em branch e abra PR.

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
- A CI precisa passar (análise, testes e APK).
- O APK de cada PR fica como artefato da CI: dá para instalar e testar antes de aprovar.
- Peça revisão de pelo menos uma pessoa do grupo.

---

## CI e deploy

Tudo automático, em `.github/workflows/`:

| Quando | O que acontece |
|---|---|
| Push ou PR | `dart format`, `flutter analyze`, `flutter test`, build do APK e testes das regras do Firestore |

O APK debug fica anexado à execução da CI por 14 dias — dá para baixar e instalar
no celular sem ter Flutter montado.

**Este repositório não publica nada no Firebase Hosting** desde 01/10/2026: o endereço
principal é do site em Next.js, e um `firebase deploy` daqui o derrubaria. Por isso o
`firebase.json` não tem mais a seção `hosting`. O único deploy que sai daqui é o das
regras: `firebase deploy --only firestore:rules`.

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

- 🟢 **Chave Android restrita** por package + SHA-1 de debug e de release (feito em
  08/09). Se algum dia o keystore de release for regerado, **o SHA-1 novo precisa
  entrar na chave** ou o login para de funcionar no APK assinado.
- 🟢 **`firestore.rules` publicadas** (08/09) e versionadas. O arquivo é a fonte:
  mudou regra, muda o arquivo e sai no PR. Para publicar:
  `firebase deploy --only firestore:rules`.
- 🟢 **E-mail do usuário fora do Firestore** (09/09). `usuarios/{uid}` não guarda mais
  `email`, e a leitura passou a ser só do dono. A premissa que sustentava a alternativa
  cara — "a avaliação precisa de nome e foto daqui" — era falsa: **nada no app lê essa
  coleção**; `ReviewsService.publicar` copia `displayName` e `photoURL` do Auth. **Falta
  limpar os documentos antigos**, que ainda têm o e-mail gravado; parar de escrever não
  apaga o que já está lá.
- 🟡 **GeoJSON de 6,7 MB embarcado** nos assets. Funciona, mas engorda o APK
  (1,48 MB comprimido). Alternativas: servir remoto ou simplificar polígonos.
- 🟡 **Dados de referência hardcoded** em `lib/data/`. Próxima etapa é trocar por
  fonte oficial (PRODES/INPE, ICMBio, IBGE, MapBiomas).
- 🟡 **Identificação por foto** (aba Fotos, 01/10/2026). O app chama a Edge Function
  `supabase/functions/identificar-animal`, que confere o ID token do Firebase e consulta
  o **Gemini** pelo nível gratuito do Google AI Studio. A chave é **secret do Supabase**
  (`GEMINI_API_KEY`), nunca vai para o `env.json`. `GEMINI_MODEL` e
  `GEMINI_MODEL_RESERVA` trocam o modelo sem republicar; o padrão é apelido, porque
  versão fixa envelhece — o `gemini-2.5-flash` já dava 404 em 01/10/2026. O principal é o
  `gemini-flash-lite-latest` (1,8 s no teste de 02/10/2026) e o reserva, o
  `gemini-flash-latest`. A demora do nível gratuito é **fila**, não modelo (o mesmo lite
  levou 1,8 s e 20 s em testes seguidos): se o principal não responde em 6 s, o reserva é
  chamado junto e vale a primeira resposta boa — nos casos lentos, a foto gasta duas
  consultas da cota. Teto de 50 s por chamada; a resposta traz `_diagnostico` com o tempo
  de cada chamada ao Gemini.
  Começou com o Cloud Vision, abandonado porque exige faturamento, e o faturamento do
  Google Cloud no Brasil pedia CNPJ. Dois cuidados do nível gratuito: o
  Google pode usar as fotos enviadas (a tela avisa) e a cota é por minuto e por dia —
  como o cadastro é aberto, qualquer conta nova consegue gastá-la.
- 🟢 **O app já foi executado** (09/09/2026), no navegador e no emulador Android, sem
  exceção nas telas. Falta confirmar o toque no mapa num aparelho Android de verdade.
