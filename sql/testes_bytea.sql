\set ON_ERROR_STOP on
\pset pager off

BEGIN;

CREATE TEMP TABLE res (n serial, teste text, ok boolean, detalhe text);

DO $$
DECLARE
    v int;
    tipo text;
    aid int;
    total_antes int;
    bytes_depois bytea;
    erro_ok boolean;
BEGIN
    SELECT data_type INTO tipo FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'album' AND column_name = 'capa';
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('album.capa existe e e bytea', tipo = 'bytea', coalesce(tipo, 'coluna ausente'));

    SELECT data_type INTO tipo FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'album' AND column_name = 'capa_tipo';
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('album.capa_tipo existe (text)', tipo = 'text', coalesce(tipo, 'coluna ausente'));

    SELECT count(*) INTO v FROM album WHERE capa IS NOT NULL AND octet_length(capa) > 0;
    INSERT INTO res(teste, ok, detalhe) VALUES ('Albuns com capa de teste', v >= 3, v || ' albuns');

    SELECT count(*) INTO v FROM album
    WHERE capa IS NOT NULL AND substring(capa FROM 1 FOR 8) = '\x89504e470d0a1a0a'::bytea;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Capas sao bytes reais (assinatura PNG)', v >= 3, v || ' capas com assinatura PNG');

    SELECT count(*) INTO v FROM album WHERE capa IS NULL;
    INSERT INTO res(teste, ok, detalhe) VALUES ('Existem albuns sem capa', v >= 1, v || ' albuns');

    erro_ok := false;
    BEGIN
        INSERT INTO album (titulo, capa) VALUES ('Sem tipo', '\x00'::bytea);
    EXCEPTION WHEN check_violation THEN
        erro_ok := true;
    END;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('CHECK rejeita capa sem capa_tipo', erro_ok, 'album_capa_coerente');

    erro_ok := false;
    BEGIN
        INSERT INTO album (titulo, capa, capa_tipo) VALUES ('Tipo ruim', '\x00'::bytea, 'text/html');
    EXCEPTION WHEN check_violation THEN
        erro_ok := true;
    END;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('CHECK rejeita tipo que nao e imagem', erro_ok, 'text/html recusado');

    SELECT count(*) INTO total_antes FROM album;
    INSERT INTO album (titulo) VALUES ('Album de teste BYTEA') RETURNING id INTO aid;

    UPDATE album SET capa = '\x89504e470d0a1a0a00112233'::bytea, capa_tipo = 'image/png' WHERE id = aid;
    SELECT capa INTO bytes_depois FROM album WHERE id = aid;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Enviar capa (UPDATE bytea)', bytes_depois = '\x89504e470d0a1a0a00112233'::bytea,
            octet_length(bytes_depois) || ' bytes');

    UPDATE album SET capa = '\xffd8ffe000'::bytea, capa_tipo = 'image/jpeg' WHERE id = aid;
    SELECT capa INTO bytes_depois FROM album WHERE id = aid;
    SELECT capa_tipo INTO tipo FROM album WHERE id = aid;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Trocar capa substitui bytes e tipo', bytes_depois = '\xffd8ffe000'::bytea AND tipo = 'image/jpeg',
            tipo || ', ' || octet_length(bytes_depois) || ' bytes');

    UPDATE album SET capa = NULL, capa_tipo = NULL WHERE id = aid;
    SELECT count(*) INTO v FROM album WHERE id = aid AND capa IS NULL AND capa_tipo IS NULL;
    INSERT INTO res(teste, ok, detalhe)
    VALUES ('Remover capa mantem o album', v = 1 AND (SELECT count(*) FROM album) = total_antes + 1,
            'album ' || aid || ' continua com capa nula');
END
$$;

SELECT n, CASE WHEN ok THEN 'OK' ELSE 'FALHOU' END AS status, teste, detalhe FROM res ORDER BY n;
SELECT count(*) FILTER (WHERE NOT ok) AS falhas, count(*) AS total FROM res;

ROLLBACK;
