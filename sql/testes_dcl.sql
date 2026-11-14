\set ON_ERROR_STOP on
\pset pager off

BEGIN;

CREATE TEMP TABLE res (n serial, teste text, ok boolean, detalhe text);

DO $$
DECLARE
    v int;
    negado boolean;
BEGIN
    SELECT count(*) INTO v FROM pg_roles WHERE rolname IN ('spoti_admin', 'spoti_consulta') AND rolcanlogin;
    INSERT INTO res(teste, ok, detalhe) VALUES ('Papeis spoti_admin e spoti_consulta existem com LOGIN', v = 2, v || ' papeis');

    ---------------------------------------------------------------- somente leitura
    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    SELECT count(*) INTO v FROM album;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] SELECT em album funciona', v > 0, v || ' albuns');

    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    SELECT count(*) INTO v FROM album_coletanea;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] SELECT na tabela filha funciona', v > 0, v || ' coletaneas');

    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    SELECT count(*) INTO v FROM (SELECT id, nome, email FROM usuario) u;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] SELECT nas colunas autorizadas de usuario', v > 0, v || ' usuarios');

    negado := false;
    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    BEGIN
        PERFORM senha FROM usuario;
    EXCEPTION WHEN insufficient_privilege THEN
        negado := true;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] coluna senha negada', negado, 'insufficient_privilege');

    negado := false;
    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    BEGIN
        INSERT INTO playlist (nome) VALUES ('Nao deveria gravar');
    EXCEPTION WHEN insufficient_privilege THEN
        negado := true;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] INSERT negado', negado, 'insufficient_privilege');

    negado := false;
    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    BEGIN
        UPDATE album SET titulo = 'x' WHERE id = 1;
    EXCEPTION WHEN insufficient_privilege THEN
        negado := true;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] UPDATE negado', negado, 'insufficient_privilege');

    negado := false;
    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    BEGIN
        DELETE FROM album_coletanea;
    EXCEPTION WHEN insufficient_privilege THEN
        negado := true;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] DELETE negado (tabela filha)', negado, 'insufficient_privilege');

    negado := false;
    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    BEGIN
        TRUNCATE playlist_musica;
    EXCEPTION WHEN insufficient_privilege THEN
        negado := true;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] TRUNCATE negado', negado, 'insufficient_privilege');

    negado := false;
    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    BEGIN
        PERFORM nextval('playlist_id_seq');
    EXCEPTION WHEN insufficient_privilege THEN
        negado := true;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] sequence negada', negado, 'insufficient_privilege');

    negado := false;
    EXECUTE 'SET LOCAL ROLE spoti_consulta';
    BEGIN
        PERFORM 1 FROM backup.log;
    EXCEPTION WHEN insufficient_privilege THEN
        negado := true;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[consulta] schema backup negado', negado, 'insufficient_privilege');

    ---------------------------------------------------------------- administrador
    EXECUTE 'SET LOCAL ROLE spoti_admin';
    INSERT INTO playlist (nome) VALUES ('Playlist do teste DCL');
    UPDATE playlist SET publica = false WHERE nome = 'Playlist do teste DCL';
    SELECT count(*) INTO v FROM playlist WHERE nome = 'Playlist do teste DCL' AND publica = false;
    DELETE FROM playlist WHERE nome = 'Playlist do teste DCL';
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[admin] INSERT, UPDATE, SELECT e DELETE em playlist', v = 1, 'ciclo completo');

    EXECUTE 'SET LOCAL ROLE spoti_admin';
    INSERT INTO album_coletanea (titulo, tema, ano_referencia) VALUES ('Coletanea do teste DCL', 'Teste', 2000);
    UPDATE album SET capa = '\x89504e470d0a1a0a'::bytea, capa_tipo = 'image/png' WHERE titulo = 'Coletanea do teste DCL';
    SELECT count(*) INTO v FROM album_coletanea WHERE titulo = 'Coletanea do teste DCL' AND capa IS NOT NULL;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[admin] grava na tabela filha e atualiza capa pelo pai', v = 1, 'album_coletanea');

    EXECUTE 'SET LOCAL ROLE spoti_admin';
    INSERT INTO reproducao (musica_id, usuario_id)
    SELECT (SELECT min(id) FROM musica), (SELECT min(id) FROM ONLY usuario);
    GET DIAGNOSTICS v = ROW_COUNT;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[admin] registra reproducao', v = 1, v || ' linha');

    negado := false;
    EXECUTE 'SET LOCAL ROLE spoti_admin';
    BEGIN
        DROP TABLE playlist_musica;
    EXCEPTION WHEN insufficient_privilege THEN
        negado := true;
    END;
    EXECUTE 'RESET ROLE';
    INSERT INTO res(teste, ok, detalhe) VALUES ('[admin] nao pode apagar tabelas (nao e o dono)', negado, 'insufficient_privilege');

    ---------------------------------------------------------------- catalogo de permissoes
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('has_table_privilege: consulta le e nao escreve',
            has_table_privilege('spoti_consulta', 'album', 'SELECT')
            AND NOT has_table_privilege('spoti_consulta', 'album', 'INSERT')
            AND NOT has_table_privilege('spoti_consulta', 'album', 'UPDATE')
            AND NOT has_table_privilege('spoti_consulta', 'album', 'DELETE'),
            'album');
END
$$;

SELECT n, CASE WHEN ok THEN 'OK' ELSE 'FALHOU' END AS status, teste, detalhe FROM res ORDER BY n;
SELECT count(*) FILTER (WHERE NOT ok) AS falhas, count(*) AS total FROM res;

ROLLBACK;
