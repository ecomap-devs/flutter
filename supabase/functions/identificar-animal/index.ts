// Identifica o animal de uma foto pelo Gemini (Google AI Studio).
//
// Existe para que a chave do Gemini NUNCA chegue ao app: APK e descompilavel
// (AGENTS.md, "o que segredo quer dizer aqui"), e com a chave na mao qualquer
// um gastaria a cota do projeto. A chave vive como secret do Supabase e so
// este codigo a le.
//
// Antes era o Google Cloud Vision, que exige conta de faturamento — e, no
// Brasil, isso pedia CNPJ. O nivel gratuito do AI Studio nao exige
// faturamento. Em troca, o Google pode usar o que e enviado nele para
// melhorar os produtos dele; a tela de Fotos avisa isso a quem usa.
//
// Quem chama precisa estar logado no Firebase. A publishable key do Supabase e
// publica por design, entao ela sozinha nao pode bastar para gastar a cota: o
// app manda o ID token do Firebase em `Authorization`, e ele e conferido aqui
// contra as chaves publicas do Google. Por isso o `verify_jwt` do gateway fica
// desligado (supabase/config.toml) — ele so entende JWT do proprio Supabase.
//
// Secrets (supabase secrets set ...):
//   GEMINI_API_KEY       chave criada em aistudio.google.com
//   FIREBASE_PROJECT_ID  o mesmo do env.json do app
//   GEMINI_MODEL         opcional; troca o modelo sem republicar a funcao
//   GEMINI_MODEL_RESERVA opcional; o modelo usado quando o principal esta
//                        sobrecarregado
//
// Os padroes sao apelidos ("-latest"), nao versoes fixas: em 01/10/2026 o
// `gemini-2.5-flash` ja respondia 404, e versao fixa envelhece calada.

import { createRemoteJWKSet, jwtVerify } from "npm:jose@5";

const CHAVE_GEMINI = Deno.env.get("GEMINI_API_KEY") ?? "";
const PROJETO_FIREBASE = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
// O lite e o principal desde 02/10/2026. Medido no site: o flash-latest
// estourou 25 s (antes do teto, a chamada chegou a 106 s), e o
// flash-lite-latest (gemini-3.5-flash-lite) respondeu certo em 1,8 s, sem
// gastar token pensando. O Flash completo fica de reserva, para quando o lite
// estiver sobrecarregado.
const MODELO = Deno.env.get("GEMINI_MODEL") || "gemini-flash-lite-latest";
const MODELO_RESERVA = Deno.env.get("GEMINI_MODEL_RESERVA") ||
  "gemini-flash-latest";

// O nivel gratuito responde 503 ("modelo sobrecarregado") com frequencia, e
// quase sempre passa em segundos. Antes de desistir: mais duas tentativas no
// modelo principal e uma no reserva.
const TENTATIVAS = [
  { modelo: MODELO, espera: 0 },
  { modelo: MODELO, espera: 800 },
  { modelo: MODELO, espera: 1600 },
  { modelo: MODELO_RESERVA, espera: 0 },
];

// Teto de tempo. No primeiro teste do site a chamada levou 106 s: sem limite,
// uma tentativa lenta segura a tela pelo tempo que o Google quiser. Uma
// tentativa que estoura o teto pula direto para o modelo reserva, porque
// repetir o mesmo modelo lento so dobraria a espera.
const TETO_POR_TENTATIVA_MS = 25_000;
const TETO_TOTAL_MS = 50_000;

/** Quanto cada tentativa levou — volta na resposta para diagnosticar demora. */
type Tentativa = { modelo: string; status: number | "tempo-esgotado"; ms: number };

// Chaves publicas que assinam os ID tokens do Firebase Auth.
const CHAVES_FIREBASE = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

// ~3 MB de imagem. O app ja reduz para 1024 px antes de mandar; isto e so o
// teto para quem chamar a funcao por fora do app.
const TAMANHO_MAXIMO_BASE64 = 4_000_000;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// O pedido ao modelo. A descricao e so do que se ve na foto: dado ambiental
// (status de ameaca, populacao) gerado por IA seria numero inventado, e o
// AGENTS.md proibe isso.
const INSTRUCAO = `Voce identifica animais em fotos para um app brasileiro sobre fauna.
Responda em portugues do Brasil.
- ehAnimal: false se nao houver animal na foto (pessoa, objeto, paisagem, desenho sem animal).
- nomePopular: o nome popular no Brasil, ex.: "onça-pintada". Vazio se nao for animal.
- nomeCientifico: o nome cientifico da especie, ou do genero se nao der para saber a especie. Vazio se nao souber.
- confianca: "alta", "media" ou "baixa", conforme a certeza da identificacao.
- descricao: ate duas frases sobre o que se ve na foto e as caracteristicas que levaram a identificacao. Nao cite status de conservacao, populacao nem numeros.`;

const ESQUEMA = {
  type: "OBJECT",
  properties: {
    ehAnimal: { type: "BOOLEAN" },
    nomePopular: { type: "STRING" },
    nomeCientifico: { type: "STRING" },
    confianca: { type: "STRING", enum: ["alta", "media", "baixa"] },
    descricao: { type: "STRING" },
  },
  required: ["ehAnimal", "nomePopular", "nomeCientifico", "confianca", "descricao"],
};

function responder(status: number, corpo: unknown): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

async function usuarioValido(req: Request): Promise<boolean> {
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return false;
  try {
    await jwtVerify(token, CHAVES_FIREBASE, {
      issuer: `https://securetoken.google.com/${PROJETO_FIREBASE}`,
      audience: PROJETO_FIREBASE,
    });
    return true;
  } catch {
    return false;
  }
}

// O image_picker devolve JPEG quase sempre, mas a galeria pode mandar PNG ou
// WebP. O inicio do base64 denuncia o formato.
function tipoDaImagem(base64: string): string {
  if (base64.startsWith("iVBOR")) return "image/png";
  if (base64.startsWith("UklGR")) return "image/webp";
  return "image/jpeg";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") {
    return responder(405, { erro: "metodo-invalido" });
  }

  if (!CHAVE_GEMINI || !PROJETO_FIREBASE) {
    console.error("Secrets GEMINI_API_KEY/FIREBASE_PROJECT_ID ausentes");
    return responder(500, { erro: "configuracao" });
  }

  if (!(await usuarioValido(req))) {
    console.warn("Chamada sem ID token valido do Firebase");
    return responder(401, { erro: "nao-autenticado" });
  }

  let imagem: unknown;
  try {
    ({ imagem } = await req.json());
  } catch {
    console.warn("Corpo nao e JSON");
    return responder(400, { erro: "corpo-invalido" });
  }
  if (typeof imagem !== "string" || imagem.length === 0) {
    console.warn("Corpo sem imagem");
    return responder(400, { erro: "sem-imagem" });
  }
  if (imagem.length > TAMANHO_MAXIMO_BASE64) {
    return responder(413, { erro: "imagem-grande" });
  }

  const corpo = JSON.stringify({
    contents: [
      {
        parts: [
          { inline_data: { mime_type: tipoDaImagem(imagem), data: imagem } },
          { text: INSTRUCAO },
        ],
      },
    ],
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: ESQUEMA,
      temperature: 0.2,
    },
  });

  const prazo = Date.now() + TETO_TOTAL_MS;
  const tentativas: Tentativa[] = [];
  let resposta: Response | undefined;
  let pularPrincipal = false;

  for (const [i, { modelo, espera }] of TENTATIVAS.entries()) {
    if (pularPrincipal && modelo === MODELO) continue;
    if (espera) await new Promise((r) => setTimeout(r, espera));
    const restante = prazo - Date.now();
    if (restante < 3_000) break;

    const inicio = Date.now();
    try {
      // A chave vai no cabecalho, nao na URL: URL aparece em log de erro.
      resposta = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${modelo}:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": CHAVE_GEMINI,
          },
          body: corpo,
          signal: AbortSignal.timeout(Math.min(TETO_POR_TENTATIVA_MS, restante)),
        },
      );
    } catch {
      tentativas.push({ modelo, status: "tempo-esgotado", ms: Date.now() - inicio });
      console.warn("Gemini", modelo, "estourou o tempo");
      resposta = undefined;
      pularPrincipal = true;
      continue;
    }
    tentativas.push({ modelo, status: resposta.status, ms: Date.now() - inicio });

    // So sobrecarga (503) e erro interno (500) valem nova tentativa; chave
    // ou modelo errado falharia igual de novo.
    if (resposta.status !== 503 && resposta.status !== 500) break;
    // A ultima resposta fica intacta: o corpo dela vai para o log abaixo.
    if (i === TENTATIVAS.length - 1) break;
    console.warn("Gemini", modelo, "respondeu", resposta.status);
    await resposta.body?.cancel();
    resposta = undefined;
  }

  if (!resposta) {
    console.error("Gemini nao respondeu a tempo", JSON.stringify(tentativas));
    return responder(504, { erro: "ia-lenta", tentativas });
  }

  if (!resposta.ok) {
    console.error("Gemini respondeu", resposta.status, await resposta.text());
    // Cota do nivel gratuito estourada: o app mostra "aguarde um momento".
    if (resposta.status === 429) return responder(429, { erro: "cota", tentativas });
    // O status do Google volta junto (sem a chave) para o motivo aparecer ate
    // no painel de Invocations, mesmo quando o log atrasa.
    return responder(502, {
      erro: "ia-indisponivel",
      status: resposta.status,
      tentativas,
    });
  }

  const dados = await resposta.json();
  const texto = dados?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (typeof texto !== "string") {
    // Acontece quando o filtro de seguranca do Gemini bloqueia a imagem.
    console.error(
      "Gemini sem texto",
      JSON.stringify(dados?.promptFeedback ?? dados?.candidates?.[0]?.finishReason),
    );
    return responder(422, { erro: "imagem-recusada" });
  }

  let identificacao: unknown;
  try {
    identificacao = JSON.parse(texto);
  } catch {
    console.error("Gemini devolveu JSON invalido", texto.slice(0, 200));
    return responder(502, { erro: "resposta-invalida" });
  }

  // Quanto tempo foi, em que modelo, e quanto o modelo "pensou" antes de
  // responder: e o que separa demora do Google de demora do raciocinio.
  const diagnostico = {
    tentativas,
    modelo: dados?.modelVersion ?? null,
    tokensPensamento: dados?.usageMetadata?.thoughtsTokenCount ?? 0,
  };
  console.log("Gemini ok", JSON.stringify(diagnostico));

  // Repassa o objeto como veio; o parser fica no Dart, onde tem teste. O
  // `_diagnostico` vai junto e os parsers do app e do site o ignoram.
  return responder(
    200,
    typeof identificacao === "object" && identificacao !== null && !Array.isArray(identificacao)
      ? { ...identificacao, _diagnostico: diagnostico }
      : identificacao,
  );
});
