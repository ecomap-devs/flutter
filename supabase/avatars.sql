-- Políticas do bucket `avatars` no Supabase (projeto wqvxjttidoxcblkfjoaf).
--
-- Até 01/10/2026 elas só existiam no painel. Estado encontrado na revisão:
--   - bucket público, sem limite de tamanho, aceitando qualquer tipo de arquivo;
--   - INSERT liberado para qualquer pessoa, em qualquer caminho do bucket;
--   - SELECT liberado, o que deixava qualquer pessoa LISTAR todos os avatares
--     (e, pelos nomes `<uid>.<ext>`, os uids de quem tem foto).
-- Não havia política de UPDATE, então sobrescrever o avatar de outra pessoa
-- já não era possível — mas o `upsert` dos apps também falhava.
--
-- O que muda:
--   - só imagem (JPEG, PNG, WebP) de até 1 MB;
--   - só arquivo novo, em `<uid>/<32 a 36 caracteres aleatórios>.<ext>`:
--     imprevisível e sem sobrescrever nada;
--   - sem listagem: a URL pública do bucket continua funcionando para exibir.
--
-- Limite conhecido: os apps entram pelo Firebase Auth, não pelo Supabase, então
-- o Supabase não sabe QUEM está enviando — o `<uid>` do caminho não é
-- verificado. Amarrar a foto ao dono exige a integração de terceiros do
-- Supabase com o Firebase Auth, que pede uma claim `role` em todos os usuários
-- (Admin SDK ou funções de bloqueio do Identity Platform).
--
-- Aplicar DEPOIS de os dois apps enviarem no formato novo (site e APK da
-- `main` a partir de 01/10/2026): versões antigas enviam `<uid>.<ext>` e
-- passam a ficar sem foto no cadastro (o cadastro em si continua).

update storage.buckets
set file_size_limit = 1048576,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id = 'avatars';

drop policy if exists "public-upload 1oj01fe_0" on storage.objects;
drop policy if exists "public-upload 1oj01fe_1" on storage.objects;
drop policy if exists "avatars: criar arquivo novo" on storage.objects;

create policy "avatars: criar arquivo novo"
on storage.objects
for insert
to anon, authenticated
with check (
  bucket_id = 'avatars'
  and name ~ '^[A-Za-z0-9]{10,128}/[0-9a-f-]{32,36}\.(jpg|png|webp)$'
);
