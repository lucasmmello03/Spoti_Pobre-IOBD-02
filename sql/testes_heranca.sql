\set ON_ERROR_STOP on
\pset pager off

BEGIN;

CREATE TEMP TABLE res (n serial, teste text, ok boolean, detalhe text);

DO $$
DECLARE
    v int;
    antes_pai int;
    antes_only int;
    cid int;
    mid int;
    erro_ok boolean;
    origem text;
BEGIN
    SELECT count(*) INTO v FROM pg_inherits
    WHERE inhrelid = 'album_coletanea'::regclass AND inhparent = 'album'::regclass;
    INSERT INTO res(teste, ok, detalhe) VALUES ('album_coletanea herda de album (INHERITS)', v = 1, v || ' vinculo');

    SELECT count(*) INTO v FROM information_schema.columns
    WHERE table_name = 'album_coletanea' AND column_name IN ('tema', 'ano_referencia');
    INSERT INTO res(teste, ok, detalhe) VALUES ('Atributos proprios da filha (tema, ano_referencia)', v = 2, v || ' colunas');

    SELECT count(*) INTO v FROM information_schema.columns
    WHERE table_name = 'album_coletanea' AND column_name IN ('id', 'titulo', 'data_lancamento', 'genero_id', 'capa');
    INSERT INTO res(teste, ok, detalhe) VALUES ('Colunas herdadas do pai presentes na filha', v = 5, v || ' colunas');

    SELECT count(*) INTO v FROM album_coletanea;
    INSERT INTO res(teste, ok, detalhe) VALUES ('Coletaneas de teste cadastradas', v >= 3, v || ' coletaneas');

    SELECT count(*) INTO antes_pai FROM album;
    SELECT count(*) INTO antes_only FROM ONLY album;
    INSERT INTO album_coletanea (titulo, genero_id, tema, ano_referencia)
    VALUES ('Coletanea de teste', 1, 'Teste', 2000) RETURNING id INTO cid;

    SELECT tableoid::regclass::text INTO origem FROM album WHERE id = cid;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('SELECT FROM album inclui a filha (tableoid mostra a origem)',
            (SELECT count(*) FROM album) = antes_pai + 1 AND origem = 'album_coletanea', origem);

    INSERT INTO res(teste, ok, detalhe)
    VALUES ('SELECT FROM ONLY album exclui a filha',
            (SELECT count(*) FROM ONLY album) = antes_only, (SELECT count(*) FROM ONLY album) || ' albuns comuns');

    INSERT INTO res(teste, ok, detalhe)
    VALUES ('id da filha vem da sequence do pai (sem colisao)',
            NOT EXISTS (SELECT 1 FROM ONLY album WHERE id = cid), 'id ' || cid);

    erro_ok := false;
    BEGIN
        INSERT INTO album_coletanea (id, titulo, tema, ano_referencia) VALUES (cid, 'Duplicada', 'x', 2000);
    EXCEPTION WHEN unique_violation THEN
        erro_ok := true;
    END;
    INSERT INTO res(teste, ok, detalhe) VALUES ('PRIMARY KEY refeita na filha rejeita id repetido', erro_ok, 'unique_violation');

    SELECT id INTO mid FROM musica ORDER BY id LIMIT 1;
    erro_ok := false;
    BEGIN
        INSERT INTO album_musica (album_id, musica_id) VALUES (cid, mid);
    EXCEPTION WHEN foreign_key_violation THEN
        erro_ok := true;
    END;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('FK do pai nao enxerga a filha (album_musica rejeita)', erro_ok, 'foreign_key_violation');

    INSERT INTO coletanea_musica (coletanea_id, musica_id) VALUES (cid, mid);
    SELECT count(*) INTO v FROM coletanea_musica WHERE coletanea_id = cid;
    INSERT INTO res(teste, ok, detalhe) VALUES ('coletanea_musica aceita a coletanea (FK na filha)', v = 1, v || ' musica');

    erro_ok := false;
    BEGIN
        INSERT INTO album_coletanea (titulo, tema, ano_referencia) VALUES ('Ano ruim', 'x', 1800);
    EXCEPTION WHEN check_violation THEN
        erro_ok := true;
    END;
    INSERT INTO res(teste, ok, detalhe) VALUES ('CHECK do ano de referencia', erro_ok, 'check_violation');

    erro_ok := false;
    BEGIN
        INSERT INTO album_coletanea (titulo, tema, ano_referencia) VALUES (NULL, 'x', 2000);
    EXCEPTION WHEN not_null_violation THEN
        erro_ok := true;
    END;
    INSERT INTO res(teste, ok, detalhe) VALUES ('NOT NULL herdado do pai (titulo)', erro_ok, 'not_null_violation');

    erro_ok := false;
    BEGIN
        INSERT INTO album_coletanea (titulo, tema, ano_referencia, capa) VALUES ('Capa sem tipo', 'x', 2000, '\x00'::bytea);
    EXCEPTION WHEN check_violation THEN
        erro_ok := true;
    END;
    INSERT INTO res(teste, ok, detalhe) VALUES ('CHECK herdado do pai (album_capa_coerente)', erro_ok, 'check_violation');

    UPDATE album SET titulo = 'Titulo alterado pelo pai' WHERE id = cid;
    SELECT count(*) INTO v FROM album_coletanea WHERE id = cid AND titulo = 'Titulo alterado pelo pai';
    INSERT INTO res(teste, ok, detalhe) VALUES ('UPDATE no pai alcanca a filha', v = 1, v || ' linha');

    DELETE FROM ONLY album WHERE id = cid;
    SELECT count(*) INTO v FROM album_coletanea WHERE id = cid;
    INSERT INTO res(teste, ok, detalhe) VALUES ('DELETE FROM ONLY album nao remove a filha', v = 1, v || ' linha continua');
END
$$;

SELECT n, CASE WHEN ok THEN 'OK' ELSE 'FALHOU' END AS status, teste, detalhe FROM res ORDER BY n;
SELECT count(*) FILTER (WHERE NOT ok) AS falhas, count(*) AS total FROM res;

ROLLBACK;
