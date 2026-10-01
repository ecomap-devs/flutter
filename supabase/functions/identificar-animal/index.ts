// Identifica o animal de uma foto pelo Google Cloud Vision.
//
// Existe para que a chave do Vision NUNCA chegue ao app: ela e de API paga, e
// APK e descompilavel (AGENTS.md, "o que segredo quer dizer aqui"). A chave
// vive como secret do Supabase e so este codigo a le.
//
// Quem chama precisa estar logado no Firebase. A publishable key do Supabase e
// publica por design, entao ela sozinha nao pode bastar para gastar a cota do
// Vision: o app manda o ID token do Firebase em `Authorization`, e ele e
// conferido aqui contra as chaves publicas do Google. Por isso o `verify_jwt`
// do gateway fica desligado (supabase/config.toml) — ele so entende JWT do
// proprio Supabase.
//
// Secrets (supabase secrets set ...):
//   GOOGLE_VISION_API_KEY  chave restrita a Cloud Vision API
//   FIREBASE_PROJECT_ID    o mesmo do env.json do app

import { createRemoteJWKSet, jwtVerify } from "npm:jose@5";

const CHAVE_VISION = Deno.env.get("GOOGLE_VISION_API_KEY") ?? "";
const PROJETO_FIREBASE = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";

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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") {
    return responder(405, { erro: "metodo-invalido" });
  }

  if (!CHAVE_VISION || !PROJETO_FIREBASE) {
    console.error("Secrets GOOGLE_VISION_API_KEY/FIREBASE_PROJECT_ID ausentes");
    return responder(500, { erro: "configuracao" });
  }

  if (!(await usuarioValido(req))) {
    return responder(401, { erro: "nao-autenticado" });
  }

  let imagem: unknown;
  try {
    ({ imagem } = await req.json());
  } catch {
    return responder(400, { erro: "corpo-invalido" });
  }
  if (typeof imagem !== "string" || imagem.length === 0) {
    return responder(400, { erro: "sem-imagem" });
  }
  if (imagem.length > TAMANHO_MAXIMO_BASE64) {
    return responder(413, { erro: "imagem-grande" });
  }

  const resposta = await fetch(
    `https://vision.googleapis.com/v1/images:annotate?key=${CHAVE_VISION}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        requests: [
          {
            image: { content: imagem },
            features: [
              { type: "WEB_DETECTION", maxResults: 10 },
              { type: "LABEL_DETECTION", maxResults: 10 },
            ],
          },
        ],
      }),
    },
  );

  if (!resposta.ok) {
    console.error("Vision respondeu", resposta.status, await resposta.text());
    return responder(502, { erro: "vision-indisponivel" });
  }

  const dados = await resposta.json();
  const primeira = dados?.responses?.[0] ?? {};
  if (primeira.error) {
    console.error("Vision recusou a imagem", primeira.error);
    return responder(422, { erro: "imagem-recusada" });
  }

  // Repassa so o que o app usa; o parser fica no Dart, onde tem teste.
  return responder(200, {
    webDetection: primeira.webDetection ?? {},
    labelAnnotations: primeira.labelAnnotations ?? [],
  });
});
