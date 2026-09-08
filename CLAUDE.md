# CLAUDE.md

As regras deste repositório estão em **[AGENTS.md](AGENTS.md)**. Leia antes de mexer
em qualquer coisa.

Este arquivo é um ponteiro de propósito: duas listas de regras separadas divergem, e
aí ninguém sabe qual vale. O `AGENTS.md` é a fonte única — vale para os cinco do
grupo e para qualquer assistente de IA.

---

## O essencial, se você só for ler uma coisa

**Credenciais nunca entram no código.** Vivem em `env.json` (ignorado pelo git) e
chegam por `--dart-define-from-file=env.json`. Não commite `firebase_options.dart`,
`google-services.json` nem `key.properties` — já estão no `.gitignore`, e é de
propósito.

**Antes de dizer que terminou:**

```bash
dart format .
flutter analyze     # "No issues found!"
flutter test        # tudo verde
```

**Build passar não prova que a credencial chegou.** Variável ausente vira
`undefined` e compila liso. Para provar, tire o `env.json`, rebuilde e confirme que
o valor sumiu do bundle.

**Não suba nada sem pedido explícito** — nem `git push`, nem `firebase deploy`.
