// Testes das firestore.rules no emulador. Rodar com `npm test` nesta pasta: o
// script sobe o emulador do Firestore, roda os testes e derruba o emulador.
//
// Cada caso de "nega" corresponde a um ataque concreto, a maioria vinda da
// revisão de 01/10/2026; cada "permite" é um caminho que o app ou o site usa.

import { readFileSync } from "node:fs";
import { after, before, beforeEach, describe, test } from "node:test";

import { assertFails, assertSucceeds, initializeTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteField, doc, getDoc, serverTimestamp, setDoc, Timestamp, updateDoc, deleteDoc } from "firebase/firestore";

const FOTO = "https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/avatars/ana/0f8e2c1a-1111-4a5b-9c3d-123456789abc.webp";
const FOTO_ANTIGA = "https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/avatars/ana.png";

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-ecomapbrasil",
    firestore: { rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8") },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

const comoAna = () => env.authenticatedContext("ana").firestore();
const comoBia = () => env.authenticatedContext("bia").firestore();
const anonimo = () => env.unauthenticatedContext().firestore();

const avaliacaoValida = (extra = {}) => ({
  uid: "ana",
  nome: "Ana",
  photoURL: FOTO,
  nota: 5,
  comentario: "Muito bom",
  criadoEm: serverTimestamp(),
  ...extra,
});

/** Grava direto, sem passar pelas regras: o estado anterior de cada teste. */
async function semRegras(caminho, dados) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), caminho), dados);
  });
}

describe("avaliacoes: leitura", () => {
  test("qualquer pessoa lê", async () => {
    await semRegras("avaliacoes/ana", { ...avaliacaoValida(), criadoEm: Timestamp.now() });
    await assertSucceeds(getDoc(doc(anonimo(), "avaliacoes/ana")));
  });
});

describe("avaliacoes: criação", () => {
  test("permite: a própria, com id = uid e hora do servidor", async () => {
    await assertSucceeds(setDoc(doc(comoAna(), "avaliacoes/ana"), avaliacaoValida()));
  });

  test("permite: sem foto", async () => {
    await assertSucceeds(setDoc(doc(comoAna(), "avaliacoes/ana"), avaliacaoValida({ photoURL: "" })));
  });

  test("nega: sem login", async () => {
    await assertFails(setDoc(doc(anonimo(), "avaliacoes/ana"), avaliacaoValida()));
  });

  test("nega: id diferente do uid (uma conta, várias avaliações)", async () => {
    await assertFails(setDoc(doc(comoAna(), "avaliacoes/qualquer-id"), avaliacaoValida()));
  });

  test("nega: em nome de outra pessoa", async () => {
    await assertFails(setDoc(doc(comoAna(), "avaliacoes/ana"), avaliacaoValida({ uid: "bia" })));
  });

  test("nega: data inventada (ano 2099)", async () => {
    await assertFails(setDoc(doc(comoAna(), "avaliacoes/ana"), avaliacaoValida({ criadoEm: Timestamp.fromDate(new Date("2099-01-01")) })));
  });

  test("nega: sem data", async () => {
    const { criadoEm, ...semData } = avaliacaoValida();
    await assertFails(setDoc(doc(comoAna(), "avaliacoes/ana"), semData));
  });

  test("nega: campo extra", async () => {
    await assertFails(setDoc(doc(comoAna(), "avaliacoes/ana"), avaliacaoValida({ admin: true })));
  });

  for (const [caso, extra] of [
    ["nota em texto", { nota: "5" }],
    ["nota 0", { nota: 0 }],
    ["nota 6", { nota: 6 }],
    ["nota fracionada", { nota: 4.5 }],
    ["comentário vazio", { comentario: "" }],
    ["comentário com 2.001 caracteres", { comentario: "x".repeat(2001) }],
    ["nome vazio", { nome: "" }],
    ["nome com 201 caracteres", { nome: "x".repeat(201) }],
    ["foto em servidor de terceiros", { photoURL: "https://rastreador.exemplo/pixel.png" }],
    ["foto de outro bucket", { photoURL: "https://wqvxjttidoxcblkfjoaf.supabase.co/storage/v1/object/public/animals/x.png" }],
    ["foto que não é texto", { photoURL: 123 }],
  ]) {
    test(`nega: ${caso}`, async () => {
      await assertFails(setDoc(doc(comoAna(), "avaliacoes/ana"), avaliacaoValida(extra)));
    });
  }
});

describe("avaliacoes: edição", () => {
  // Uma avaliação antiga, de antes de o id ser o uid, como as 20 que já existem.
  const ANTIGA = "avaliacoes/abc123";
  beforeEach(async () => {
    await semRegras(ANTIGA, { ...avaliacaoValida({ photoURL: FOTO_ANTIGA }), criadoEm: Timestamp.fromDate(new Date("2026-06-01")) });
  });

  test("permite: o autor muda nota e comentário, com a hora da edição", async () => {
    await assertSucceeds(updateDoc(doc(comoAna(), ANTIGA), { nota: 3, comentario: "Mudei de ideia", atualizadoEm: serverTimestamp() }));
  });

  test("nega: nota em texto (derrubava a lista do app)", async () => {
    await assertFails(updateDoc(doc(comoAna(), ANTIGA), { nota: "texto", atualizadoEm: serverTimestamp() }));
  });

  test("nega: nota 999999 (distorcia a média do site)", async () => {
    await assertFails(updateDoc(doc(comoAna(), ANTIGA), { nota: 999999, atualizadoEm: serverTimestamp() }));
  });

  test("nega: apagar um campo obrigatório", async () => {
    await assertFails(updateDoc(doc(comoAna(), ANTIGA), { comentario: deleteField(), atualizadoEm: serverTimestamp() }));
  });

  test("nega: mexer na data de criação", async () => {
    await assertFails(updateDoc(doc(comoAna(), ANTIGA), { criadoEm: Timestamp.fromDate(new Date("2099-01-01")), atualizadoEm: serverTimestamp() }));
  });

  test("nega: editar sem a hora da edição", async () => {
    await assertFails(updateDoc(doc(comoAna(), ANTIGA), { nota: 3 }));
  });

  test("nega: transferir a autoria", async () => {
    await assertFails(updateDoc(doc(comoAna(), ANTIGA), { uid: "bia", atualizadoEm: serverTimestamp() }));
  });

  test("nega: editar a de outra pessoa", async () => {
    await assertFails(updateDoc(doc(comoBia(), ANTIGA), { nota: 1, atualizadoEm: serverTimestamp() }));
  });

  test("nega: acrescentar campo extra", async () => {
    await assertFails(updateDoc(doc(comoAna(), ANTIGA), { admin: true, atualizadoEm: serverTimestamp() }));
  });

  test("permite: o autor apaga a própria", async () => {
    await assertSucceeds(deleteDoc(doc(comoAna(), ANTIGA)));
  });

  test("nega: apagar a de outra pessoa", async () => {
    await assertFails(deleteDoc(doc(comoBia(), ANTIGA)));
  });
});

describe("usuarios", () => {
  const perfil = (extra = {}) => ({ nome: "Ana", photoURL: "", criadoEm: serverTimestamp(), ...extra });

  test("permite: o cadastro grava o próprio perfil", async () => {
    await assertSucceeds(setDoc(doc(comoAna(), "usuarios/ana"), perfil()));
  });

  test("nega: gravar o e-mail de volta", async () => {
    await assertFails(setDoc(doc(comoAna(), "usuarios/ana"), perfil({ email: "ana@exemplo.com" })));
  });

  test("nega: campo extra (admin)", async () => {
    await assertFails(setDoc(doc(comoAna(), "usuarios/ana"), perfil({ admin: true })));
  });

  test("nega: data inventada", async () => {
    await assertFails(setDoc(doc(comoAna(), "usuarios/ana"), perfil({ criadoEm: Timestamp.fromDate(new Date("2000-01-01")) })));
  });

  test("nega: perfil de outra pessoa", async () => {
    await assertFails(setDoc(doc(comoBia(), "usuarios/ana"), perfil()));
  });

  test("nega: ler o perfil de outra pessoa", async () => {
    await semRegras("usuarios/ana", { nome: "Ana", photoURL: "", criadoEm: Timestamp.now() });
    await assertFails(getDoc(doc(comoBia(), "usuarios/ana")));
    await assertSucceeds(getDoc(doc(comoAna(), "usuarios/ana")));
  });

  describe("perfil antigo, ainda com e-mail", () => {
    beforeEach(async () => {
      await semRegras("usuarios/ana", { nome: "Ana", email: "ana@exemplo.com", photoURL: "", criadoEm: Timestamp.now() });
    });

    test("permite: o dono apaga o e-mail", async () => {
      await assertSucceeds(updateDoc(doc(comoAna(), "usuarios/ana"), { email: deleteField() }));
    });

    test("nega: trocar o e-mail", async () => {
      await assertFails(updateDoc(doc(comoAna(), "usuarios/ana"), { email: "outro@exemplo.com" }));
    });

    test("nega: mexer na data de criação", async () => {
      await assertFails(updateDoc(doc(comoAna(), "usuarios/ana"), { criadoEm: Timestamp.now() }));
    });
  });

  test("nega: apagar o perfil", async () => {
    await semRegras("usuarios/ana", { nome: "Ana", photoURL: "", criadoEm: Timestamp.now() });
    await assertFails(deleteDoc(doc(comoAna(), "usuarios/ana")));
  });
});

describe("tudo o mais", () => {
  test("nega: coleção que não está nas regras", async () => {
    await assertFails(setDoc(doc(comoAna(), "qualquer/coisa"), { a: 1 }));
    await assertFails(getDoc(doc(anonimo(), "qualquer/coisa")));
  });
});
