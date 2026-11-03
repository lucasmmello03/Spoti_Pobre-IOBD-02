\set ON_ERROR_STOP on
\pset pager off

BEGIN;

CREATE TEMP TABLE res (
    n serial,
    teste text,
    ok boolean,
    detalhe text
);

DO $$
DECLARE
    v int;
    v2 int;
    uid int;
    pid int;
    premid int;
    t text;
    seq text;
    ult bigint;
    chamada boolean;
    maxid bigint;
    ruins text := '';
    tipo text;
BEGIN
    SELECT count(*) INTO v
    FROM unnest(ARRAY['usuario','usuario_premium','playlist','usuario_playlist','musica',
                      'playlist_musica','reproducao','genero','album','album_musica',
                      'artista','album_artista']) x(nome)
    WHERE to_regclass('public.' || x.nome) IS NOT NULL;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Tabelas esperadas existem', v = 12, v || ' de 12');

    SELECT data_type INTO tipo FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'album' AND column_name = 'capa';
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('album.capa existe e e bytea', tipo = 'bytea', coalesce(tipo, 'coluna ausente'));

    INSERT INTO res(teste, ok, detalhe)
    SELECT 'Extensao uuid-ossp instalada', count(*) = 1, count(*) || ' encontrada(s)'
    FROM pg_extension WHERE extname = 'uuid-ossp';

    SELECT count(*) INTO v FROM album;
    SELECT count(*) INTO v2 FROM musica;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Existem albuns e musicas', v > 0 AND v2 > 0, v || ' albuns, ' || v2 || ' musicas');

    SELECT count(*) INTO v
    FROM album a
    INNER JOIN album_musica am ON am.album_id = a.id
    INNER JOIN musica m ON m.id = am.musica_id;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Consulta do dashboard (album + musica) retorna linhas', v > 0, v || ' linhas');

    SELECT count(*) INTO v FROM playlist;
    SELECT count(*) INTO v2
    FROM playlist p
    LEFT JOIN usuario_playlist up ON p.id = up.playlist_id AND up.dono = true
    LEFT JOIN usuario u ON u.id = up.usuario_id;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Listagem de playlists nao perde playlist sem dono', v = v2,
            v || ' playlists, ' || v2 || ' linhas na listagem');

    SELECT count(*) INTO v FROM usuario;
    SELECT count(*) INTO v2 FROM ONLY usuario;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Usuarios comuns (ONLY usuario) disponiveis para os seletores', v2 > 0,
            v2 || ' comuns de ' || v || ' no total (a diferenca sao premium)');

    FOREACH t IN ARRAY ARRAY['usuario','playlist','musica','album','artista','genero','reproducao'] LOOP
        seq := pg_get_serial_sequence(t, 'id');
        EXECUTE format('SELECT last_value, is_called FROM %s', seq) INTO ult, chamada;
        EXECUTE format('SELECT coalesce(max(id), 0) FROM %I', t) INTO maxid;
        IF (CASE WHEN chamada THEN ult + 1 ELSE ult END) <= maxid THEN
            ruins := ruins || t || ' ';
        END IF;
    END LOOP;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Sequences adiante do maior id (sem chave duplicada no proximo insert)',
            ruins = '', CASE WHEN ruins = '' THEN 'todas ok' ELSE 'atrasadas: ' || ruins END);

    INSERT INTO usuario (email, senha, nome, data_nascimento)
    VALUES ('teste.banco@exemplo.com', md5('x'), 'Teste Banco', '2000-01-01')
    RETURNING id INTO uid;
    INSERT INTO res(teste, ok, detalhe) VALUES ('Inserir usuario comum', uid IS NOT NULL, 'id ' || uid);

    INSERT INTO reproducao (musica_id, usuario_id)
    SELECT min(id), uid FROM musica;
    SELECT count(*) INTO v FROM reproducao WHERE usuario_id = uid;
    INSERT INTO res(teste, ok, detalhe) VALUES ('Registrar reproducao de usuario comum', v = 1, v || ' linha');

    INSERT INTO playlist (nome, publica) VALUES ('Playlist de teste do banco', true) RETURNING id INTO pid;
    INSERT INTO usuario_playlist (usuario_id, playlist_id, dono) VALUES (uid, pid, true);
    SELECT count(*) INTO v
    FROM playlist p
    LEFT JOIN usuario_playlist up ON p.id = up.playlist_id AND up.dono = true
    LEFT JOIN usuario u ON u.id = up.usuario_id
    WHERE p.id = pid AND u.nome = 'Teste Banco';
    INSERT INTO res(teste, ok, detalhe) VALUES ('Criar playlist com dono e listar o dono', v = 1, v || ' linha');

    BEGIN
        INSERT INTO usuario (email, senha, nome) VALUES ('teste.banco@exemplo.com', md5('y'), 'Duplicado');
        INSERT INTO res(teste, ok, detalhe) VALUES ('E-mail duplicado e rejeitado', false, 'inseriu duplicado');
    EXCEPTION WHEN unique_violation THEN
        INSERT INTO res(teste, ok, detalhe) VALUES ('E-mail duplicado e rejeitado', true, 'unique_violation, como esperado');
    END;

    SELECT min(id) INTO premid FROM usuario_premium;
    IF premid IS NULL THEN
        INSERT INTO res(teste, ok, detalhe)
        VALUES ('Reproducao de usuario premium e rejeitada pela FK (heranca)', true, 'sem usuario premium nos dados, ignorado');
    ELSE
        BEGIN
            INSERT INTO reproducao (musica_id, usuario_id) SELECT min(id), premid FROM musica;
            INSERT INTO res(teste, ok, detalhe)
            VALUES ('Reproducao de usuario premium e rejeitada pela FK (heranca)', false, 'FK aceitou premium');
        EXCEPTION WHEN foreign_key_violation THEN
            INSERT INTO res(teste, ok, detalhe)
            VALUES ('Reproducao de usuario premium e rejeitada pela FK (heranca)', true,
                    'foreign_key_violation, como esperado: FK nao enxerga a tabela filha');
        END;
    END IF;

    DELETE FROM usuario_playlist WHERE playlist_id = pid;
    DELETE FROM playlist_musica WHERE playlist_id = pid;
    DELETE FROM playlist WHERE id = pid;
    SELECT count(*) INTO v FROM playlist WHERE id = pid;
    INSERT INTO res(teste, ok, detalhe) VALUES ('Excluir playlist (filhos primeiro)', v = 0, v || ' restante(s)');

    DELETE FROM reproducao WHERE usuario_id = uid;
    DELETE FROM usuario_playlist WHERE usuario_id = uid;
    DELETE FROM usuario WHERE id = uid;
    SELECT count(*) INTO v FROM usuario WHERE id = uid;
    INSERT INTO res(teste, ok, detalhe) VALUES ('Excluir usuario (filhos primeiro)', v = 0, v || ' restante(s)');
END
$$;

SELECT n, CASE WHEN ok THEN 'OK' ELSE 'FALHOU' END AS status, teste, detalhe
FROM res
ORDER BY n;

SELECT count(*) FILTER (WHERE NOT ok) AS falhas, count(*) AS total FROM res;

ROLLBACK;
