\set ON_ERROR_STOP on
\pset pager off

BEGIN;

CREATE TEMP TABLE res (n serial, teste text, ok boolean, detalhe text);

DO $$
DECLARE
    v int;
    tipo text;
    pid int;
    json_depois jsonb;
BEGIN
    SELECT data_type INTO tipo FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'playlist' AND column_name = 'dados_extras';
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('playlist.dados_extras existe e e jsonb', tipo = 'jsonb', coalesce(tipo, 'coluna ausente'));

    SELECT count(*) INTO v FROM pg_indexes
    WHERE tablename = 'playlist' AND indexname = 'playlist_dados_extras_gin';
    INSERT INTO res(teste, ok, detalhe) VALUES ('Indice GIN do JSONB existe', v = 1, v || ' indice');

    SELECT count(*) INTO v FROM playlist WHERE dados_extras <> '{}'::jsonb;
    INSERT INTO res(teste, ok, detalhe) VALUES ('Playlists com dados JSON de teste', v >= 5, v || ' playlists');

    SELECT count(*) INTO v FROM playlist
    WHERE dados_extras @> jsonb_build_object('tags', jsonb_build_array('samba'::text));
    INSERT INTO res(teste, ok, detalhe) VALUES ('Busca por tag com @> (samba)', v >= 1, v || ' resultado(s)');

    SELECT count(*) INTO v FROM playlist WHERE dados_extras->>'destaque' = 'true';
    INSERT INTO res(teste, ok, detalhe) VALUES ('Busca por destaque com ->>', v >= 1, v || ' resultado(s)');

    SELECT count(*) INTO v FROM playlist WHERE dados_extras->>'clima' = 'nostalgico';
    INSERT INTO res(teste, ok, detalhe) VALUES ('Busca por clima com ->>', v >= 1, v || ' resultado(s)');

    INSERT INTO playlist (nome, publica, dados_extras)
    VALUES ('Teste JSONB', true,
            jsonb_build_object('descricao', 'com "aspas"'::text,
                               'tags', to_jsonb(ARRAY(SELECT lower(btrim(t))
                                                      FROM unnest(string_to_array(' MPB, Brasil ,, ', ',')) AS t
                                                      WHERE btrim(t) <> '')),
                               'clima', 'animado'::text, 'destaque', true::boolean))
    RETURNING id INTO pid;
    SELECT dados_extras INTO json_depois FROM playlist WHERE id = pid;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Inserir playlist com JSON (aspas e tags limpas)',
            json_depois->'tags' = '["mpb","brasil"]'::jsonb AND json_depois->>'descricao' = 'com "aspas"',
            json_depois::text);

    UPDATE playlist SET dados_extras = dados_extras || '{"extra": 1}'::jsonb WHERE id = pid;
    UPDATE playlist
    SET dados_extras = COALESCE(dados_extras, '{}'::jsonb) || jsonb_build_object('clima', 'calmo'::text)
    WHERE id = pid;
    SELECT dados_extras INTO json_depois FROM playlist WHERE id = pid;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Atualizar JSON com || preserva as outras chaves',
            json_depois->>'clima' = 'calmo' AND json_depois->>'extra' = '1' AND json_depois->>'descricao' = 'com "aspas"',
            json_depois::text);

    SELECT count(*) INTO v FROM playlist WHERE id = pid AND dados_extras @> '{"tags":["mpb"]}';
    INSERT INTO res(teste, ok, detalhe) VALUES ('Playlist nova aparece na busca por tag', v = 1, v || ' resultado');

    -- Edicao direta pela tela de detalhe (mesmos comandos usados pelo PlaylistDAO)
    UPDATE playlist SET dados_extras = jsonb_set(dados_extras, '{destaque}',
        to_jsonb(NOT COALESCE(CASE WHEN jsonb_typeof(dados_extras->'destaque') = 'boolean'
                                   THEN (dados_extras->>'destaque')::boolean END, false)), true)
    WHERE id = pid;
    SELECT dados_extras INTO json_depois FROM playlist WHERE id = pid;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Alternar destaque com jsonb_set preserva as outras chaves',
            json_depois->>'destaque' = 'false' AND json_depois->>'clima' = 'calmo',
            json_depois::text);

    UPDATE playlist SET dados_extras = jsonb_set(dados_extras, '{tags}',
        dados_extras->'tags' || jsonb_build_array('novatag'::text), true)
    WHERE id = pid;
    SELECT dados_extras INTO json_depois FROM playlist WHERE id = pid;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Adicionar tag com ||', json_depois->'tags' = '["mpb","brasil","novatag"]'::jsonb,
            json_depois->>'tags');

    UPDATE playlist SET dados_extras = jsonb_set(dados_extras, '{tags}',
        COALESCE((SELECT jsonb_agg(t) FROM jsonb_array_elements(dados_extras->'tags') AS t
                  WHERE t <> to_jsonb('mpb'::text)), '[]'::jsonb), true)
    WHERE id = pid;
    SELECT dados_extras INTO json_depois FROM playlist WHERE id = pid;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Remover tag com jsonb_agg', json_depois->'tags' = '["brasil","novatag"]'::jsonb,
            json_depois->>'tags');

    UPDATE playlist SET dados_extras = jsonb_set(dados_extras, '{clima}', to_jsonb('animado'::text), true)
    WHERE id = pid;
    SELECT dados_extras INTO json_depois FROM playlist WHERE id = pid;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Trocar clima com jsonb_set', json_depois->>'clima' = 'animado' AND json_depois->>'descricao' = 'com "aspas"',
            json_depois::text);

    SELECT CASE WHEN jsonb_typeof(j) <> 'object' THEN 'objeto'
                WHEN j->'tags' IS NOT NULL AND jsonb_typeof(j->'tags') <> 'array' THEN 'tags'
                WHEN j->'destaque' IS NOT NULL AND jsonb_typeof(j->'destaque') <> 'boolean' THEN 'destaque'
           END INTO tipo
    FROM (SELECT '{"tags": "x"}'::jsonb AS j) AS x;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Validacao do editor recusa tags que nao e lista', tipo = 'tags', coalesce(tipo, 'aceitou'));
END
$$;

SELECT n, CASE WHEN ok THEN 'OK' ELSE 'FALHOU' END AS status, teste, detalhe FROM res ORDER BY n;
SELECT count(*) FILTER (WHERE NOT ok) AS falhas, count(*) AS total FROM res;

ROLLBACK;
