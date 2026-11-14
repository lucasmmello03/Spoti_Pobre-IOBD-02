BEGIN;

-- =====================================================================
-- Requisito 1: JSONB (playlist.dados_extras)
-- =====================================================================

ALTER TABLE playlist
    ADD COLUMN IF NOT EXISTS dados_extras jsonb NOT NULL DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS playlist_dados_extras_gin
    ON playlist USING gin (dados_extras jsonb_path_ops);

UPDATE playlist p
SET dados_extras = v.dados
FROM (VALUES
    ('MPB Essencial',
     '{"descricao": "Selecao de classicos da MPB", "tags": ["mpb", "brasil", "classicos"], "clima": "nostalgico", "destaque": true}'::jsonb),
    ('Clássicos do Samba',
     '{"descricao": "Os sambas que todo mundo canta junto", "tags": ["samba", "brasil", "classicos"], "clima": "animado", "destaque": true}'::jsonb),
    ('Samba de Raiz',
     '{"descricao": "Samba tradicional, de roda de quintal", "tags": ["samba", "raiz", "classicos"], "clima": "nostalgico", "destaque": true}'::jsonb),
    ('Rock Nacional Anos 80 e 90',
     '{"descricao": "Rock brasileiro de duas decadas", "tags": ["rock", "brasil", "anos80"], "clima": "energetico", "destaque": false}'::jsonb),
    ('Churrasco com Sertanejo',
     '{"descricao": "Trilha para o fim de semana", "tags": ["sertanejo", "festa"], "clima": "animado", "destaque": false}'::jsonb),
    ('Forró Pé de Serra',
     '{"descricao": "Forro raiz do Nordeste", "tags": ["forro", "nordeste", "festa"], "clima": "animado", "destaque": false}'::jsonb),
    ('Bossa Nova & Café',
     '{"descricao": "Para uma tarde tranquila", "tags": ["bossa nova", "cafe"], "clima": "relaxante", "destaque": false}'::jsonb),
    ('Músicas para Trabalhar',
     '{"descricao": "Para manter o foco", "tags": ["foco", "trabalho"], "clima": "focado", "destaque": false}'::jsonb),
    ('Baladas Românticas Nacionais',
     '{"descricao": "Para ouvir a dois", "tags": ["romantico", "brasil"], "clima": "romantico", "destaque": false}'::jsonb)
) AS v(nome, dados)
WHERE p.nome = v.nome;

COMMIT;

-- =====================================================================
-- Requisito 2: BYTEA (capas de album)
-- A coluna album.capa (bytea) ja existe na base do professor.
-- capa_tipo guarda o MIME (image/png, image/jpeg...) para servir a imagem.
-- =====================================================================

BEGIN;

ALTER TABLE album
    ADD COLUMN IF NOT EXISTS capa_tipo text;

ALTER TABLE album
    DROP CONSTRAINT IF EXISTS album_capa_coerente;

ALTER TABLE album
    ADD CONSTRAINT album_capa_coerente
    CHECK ((capa IS NULL AND capa_tipo IS NULL)
        OR (capa IS NOT NULL AND capa_tipo IS NOT NULL AND capa_tipo IN ('image/jpeg', 'image/png', 'image/gif', 'image/webp')));

-- Dados de teste: 4 capas PNG pequenas (bytes reais, via decode base64)

UPDATE album
SET capa = decode('
iVBORw0KGgoAAAANSUhEUgAAAMgAAADIBAMAAABfdrOtAAAAGFBMVEX7vyT4rSD1nBzyixjvehTs
aRDqWAwNDRK9qmgKAAAGY0lEQVR42u1cS27kNhAtlgUhsyNv4CMYyIV65UPNqi8UIEDWAXwDcjkQ
MGYWsT2SWH/KwQSJNm6TIh/fK7KqSKk7PQPAdgfiKiBdvVGlz+S9yGEkGYOp/8qCUBglg3aRt9wZ
kM0t1TsZAmWjQQixkgmDvu8rCXI3jZCTzCQYbjMYFAohWJrDAIB6Llhv1Oyawhi5jFQeZjEAvnw7
FfzxpDDxY4xtNoVJCWBA+uWbTAXnMUaNN0muBMEryWsF54zOSLDxNikQv05mOVplsYj1g2I1CrYx
lZxY5/JqWvmHZb8oK6QQJXRQzI2lgqJYtM9nSvkJhpJYbHgkKwprlQd+ZkmhKw0Oa5hhuwm2sGIp
E7qMlmGnJ3JWL4EInxm9kBlDieQRiTE90kSC2QpDBUkiJeZ9Oas8UH2WcCQ5/P8xv5DAd3h8sem2
Z1ImwvwXCxUcR+OLKtmgAg63lbnQmwm98IztDsFS+/s7SJ7NifQOEKZzImGivOmFCabzlaTphXk6
gTy3GvtYTESKHN95KhsBkpUwXxic3ESmagZ5jo9k5E3sUO8DSCYgsqHo1HLQCwO7LqI0iaqjRITL
VogUg52W9yOIJ3QVkUrimWTP4i8ilXw0Ctrij76HS6YpnH2ha6jPDOKdz4X18JiymQoa1QDLOQNn
FKR7TZOBJJFMUiCXSNaBodFbWwTL9Oc7bZMUPYuQmaRY6OIDSdpbHhUvOhkTD76uRJOJyh3j7j6v
qLs3O5VkX4x55lSFrFiUdXRQsGrhnY712zL0m/lFR50TsErvAFHnv4+Pnph4skmW4oSWrSQdEf1b
XL/PQX6lcj0ms/c1nqZm746EbIvHnpIplygm72u0SZr0vgyIMayYNjVpD5Iczy3UqqQzsTvK7FHv
uMW2N+W9CfERQxmP0/bo9BChezF+QG8XAH0OwnVzUm2SZ7LUgUmOdpHNxXjF4xON9ydl9cdOFrpj
cv9Y+RxCBlyS/UFP4R+fyATRolah/WIKunptbLFTJHofn7iYnjgXKsZpzNeku+LExJntVECubEoN
mPwpTRk+wfwjaIR/4FI3ptlVyax4r1r4CPCb2W+2kFz4CAC/Ov0KKvPjLMgjAAA8+dw2hkz4cIHh
+VE9vv19crlIjA3p4cp1kj5vnahqkab/GVf8/yD/eZB+/Pfl49Pv/w4m7BOq1/cP30miFzF5iai1
A6FH1Ugq3x3sAzZ50Yl0N8i5xesLOGK8lEjse26nCPb6Z7NptKv/OVZ891hYB2FkaDxoB2VummdX
nyYCqDdq8vw0rBjUyTPPEniBQ4uxR8XqMkijH5JUcEr3thi77VFMkV6C1KAXenF39f3mI90eWowt
NGQDSI87jiaWIlPfox1TxQhRvXrQQTZPH46bccYSCsFOMukOvTz3YlTz5osnnJtrZiJdaYW2pjIR
bTKj0Fl1fItCHBlKSjdbV30qkehTVu8HEN6bVpNYTYNHeYzNQLCb3EoXOiBQerP5l2bPhRuYvmqm
G14StZ8MUJvRv3Rhdo0K77vtNTLTlnEww0FUr8LrCxYnsQwdd9/ib4bJjHP+1RSN3t5b6RDNJ5oh
4yencLuWyAdIC1JpFv9yQ6rfFiPSXV64z+V0py7WD5AWoWLdhCFN3BYwmsm/3H7I1fyCNat2n5TV
dxqkex16bzZvvO6ZNB/KUN8iR1HODJL1TDfuREJLu4hK43lXn0nuWJexnmZXk2KiFJI15yfvGWnr
E6W8AW/STut9zM1QpHkl1MajZiuyN14Bzu/tce/TFdcXJuv5q/+LSdo6Fx9x/shMcq4rdagW2gqr
YQW7SxhvWLnRrr5ddK6yU2s8W+mTYtFnKx2mBBPDyo3axwcEk1qv/Bbbtcup1i12ix8yyYfsN2bP
6DNLF8e3sts5D8ooLEnkb5AOIRRi0yr5rhZBISZII9UC5EZQAxgdSLXI/Ykc4IVqhgigPSaqdV17
CcL8BTZBy8r9HA7KeUm1l55/tIB6INC5MVt/GKEDY/Z9jG+Zld/wEw/nubMyL6ZM/CDGCP9szYUn
QtfKZisNLnu2ceNz4XaVWKszTQ2FlZuU3NUgRhOJnFOiegXGmYh2ZBvKJVZtHx8wfgWFCHHQ2WYx
1jEy3iZRKqhEAFeAK/MuigggAexAqWAgAkj8SJUYE7X7nulsZQW4KiWiOwOkCWppBHsL1Rf8Bcf9
7C8+oDkcAAAAAElFTkSuQmCC
', 'base64'),
    capa_tipo = 'image/png'
WHERE titulo = 'Clube da Esquina';

UPDATE album
SET capa = decode('
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
RU5ErkJggg==
', 'base64'),
    capa_tipo = 'image/png'
WHERE titulo = 'Transa';

UPDATE album
SET capa = decode('
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
Dv8ArWPwRBl81agAAAAASUVORK5CYII=
', 'base64'),
    capa_tipo = 'image/png'
WHERE titulo = 'Elis & Tom';

UPDATE album
SET capa = decode('
iVBORw0KGgoAAAANSUhEUgAAAMgAAADIBAMAAABfdrOtAAAAGFBMVEUixV4et2AbqmMYnWYVkGgS
g2sPdm4NDRKW7WNYAAAGGUlEQVR42u1cO5LjOgwkUCrH5A0V7aE28g3J2Ak2mI9FCn9pq97UPicz
Y4sEGiC7AVoaKN+vX2V+0SgXX+3z5/b9zmO9RLPRTxNxr1E/foIIpEtDTwihSpd+frJJQMjE8L60
S3hoQeID0s34c1BQAMLORl3J0pBD+2VkdwSrq8uN94AORh72ytJgKE6Md05+mcHqoZ0xpwWVRRG3
wa69r3A9rGB17ybvXMCQSTvlbXCX0ocRC0iPENb54oEOICEbzOWE/KK7YIMZgKdokZPENPZljOza
FRlVWcegASSnXMsoNKAm1ZFWI7sGJKu8YzbyUDzPy/w0ElUgF0qJ40ybNivZe0HW9/H+ZHvIs0rB
Or5PXVJeelvZdhnI8BUrRagjSAqXGSweHW/mG8omTzsi1UpnkkPsZhwWkO6nkuN8GACilxLURSjo
z4i5M7sEBSXfR4kX+V3wFAXfqWQaic5DQScQJ4t1Fgo6M+JlscH9jfy8aZ1fEdNsZNyj88RAQQ/o
kKz0s1HkPKByRVbOAo6OiYIafL4cbV/CGtz5ql6NVlyDB1vVJzXYFzD61pPh3l5zSJql74Iykgnk
kKXOlhLEtA7zu8OUlaH8yckfnt60gJznVOTKEK1Q19WtMlWNFjkV+ASPAkjcJEZDGYlqSgIkphG3
3p+MgKp0eSIMUF0Pc/zRCLlIhKLS60MyYkQpEisuw2URdsh8F2yiFwhlOP5gxJWSkRNFCwklVGXY
rcN80UjII4mtw0jHwRlVFOeilM5TqD9RK0ovlHd/QrbD40rVpXS/5Gofm15EkNlie05Xmd6a2MQP
9vPh7EH1s/Xh0njOt7VaMXGjY2JLurqVTbQXl33OZp32YXTRcrUEGUUupvk7UNlicF9TZrei6RpF
z9nOFRamyCgoPsLZyggzvkZ7GErCyF2H6ePlwAsjYaFEaUfKUZSt+gFtwHJNj1wu4F0VhGYQA06N
LBnguCtavqp+XCwh8t3vhdbBMHLrBqXYEr55x5uUbwZ0ZDfj30Jyz2tzh+MzAI+9lN/B5RVF8tjL
+faTVLiGvDf2wtwbooMaUSSPwt93dFPiaYKwh0gBM0CiUP6D+2RnfvuZSP438o8aeTK//TgkUEop
r6+/XvxF9RYkz0y0LCOray8VyApcNVItKCEgxxv7oHhAvZ5F1ngwCwnn6/X7Z25GKO5wzrms/xB3
QQkubG0YTEZqamaPPcwOjDiENbJ1k06gMR3kwjUvZiy3xat6kNhrqnpdgAv7BJIZw9xCijmGEPG+
5q7D0MaD3PrGGJ9Wl3lYRmDMe+kGTlBdQX7jQTBgOkKMskm1TcNlPeECBjWgJ3y6wQxYNUgCHRuv
Gg9NNMsLjDNRaZNVaIpPcDbiZZPjvK26NL4m2Le1+afOL1uWfVuAX1C6AJLlBMcv6MoEXCsEsGjM
FocCnEUsYV71A4EDkurwuF4RaAw6lSJT9G70GgcCRyRwS5EaaLHljd5K9HmzOhmpLuejrQOISJSN
Hq3q62wESvbpO9/HWEw1cFppckwwVDHWwOqrq5HqHGk+F8sPRT19VdFEWZHXkRit5Zov58YpkcUm
Z6c5eNyJRA0QI6zVSrV0YjOJcbDVin579ZLYLUmMLTIITWLMnEksEcd4jR4XerQ3er0KxNM6QE0+
4H/eJ7VEmoVA1o/HHuBsOKIaDN7DglDAGA1GFzFCOlhLY6pWjC3bUlatuAvIVTFDgE5idKaFb+3Q
y/EuK4LOo5vjHVaaEDz0l5ymlSatNAwQIzRvS6xV9SYxthDDAfv9ic3xTbpHsWkBx2AjwCo6184f
nYTHXsR7Kcn3eHGz4re9SpjjoXmexa7id1pLbVJHssJfy9TnXRwvj8Tli8layi2n0GsFqUH5S1/S
1DsCtozC9YtcKNetAHOM/tQ5/mJCPo3oUPzSa9ddSq7bRRsfRp6Z7spvA7Ccv8OvV6xwXRcWDxS/
Fe7f+XzmxITitdKMOwssuaqxQ+njZHC4KbCEH/J0oIV3Vf/yUJYORigzjgX30/Wtt5IZwYOp4H75
Et2C73+wGEy3auaeWVU4tM3y+3Lz4lHijbUN61wrlPg/PRIp/w+YWNeE0Mv0aAAAAABJRU5ErkJg
gg==
', 'base64'),
    capa_tipo = 'image/png'
WHERE titulo = 'Cartola';

COMMIT;

-- =====================================================================
-- Requisito 3: Heranca (album_coletanea INHERITS album)
-- Atributos proprios da colecao: tema e ano de referencia.
-- Particularidades do PostgreSQL tratadas aqui:
--   * PRIMARY KEY, UNIQUE e FOREIGN KEY NAO sao herdadas: sao refeitas na filha.
--   * NOT NULL e CHECK sao herdados (inclui album_capa_coerente).
--   * O id da filha vem da mesma sequence do pai (album_id_seq).
--   * FKs que apontam para album(id) nao enxergam linhas da filha:
--     por isso as musicas da coletanea ficam em coletanea_musica.
-- =====================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS album_coletanea (
    tema text NOT NULL,
    ano_referencia integer NOT NULL CHECK (ano_referencia BETWEEN 1900 AND 2100),
    PRIMARY KEY (id),
    FOREIGN KEY (genero_id) REFERENCES genero (id)
) INHERITS (album);

CREATE TABLE IF NOT EXISTS coletanea_musica (
    coletanea_id integer NOT NULL REFERENCES album_coletanea (id),
    musica_id integer NOT NULL REFERENCES musica (id),
    PRIMARY KEY (coletanea_id, musica_id)
);

-- Dados de teste
INSERT INTO album_coletanea (titulo, data_lancamento, genero_id, tema, ano_referencia)
SELECT v.titulo, v.lancamento, g.id, v.tema, v.ano
FROM (VALUES
    ('Os Melhores do Samba', DATE '2018-03-10', 'Samba', 'Samba de roda', 2018),
    ('MPB para Ouvir na Chuva', DATE '2021-06-01', 'MPB', 'Tardes de chuva', 2021),
    ('Rock Brasil Anos 80', DATE '1995-09-15', 'Rock Nacional', 'Geracao 80', 1985)
) AS v(titulo, lancamento, genero, tema, ano)
JOIN genero g ON g.nome = v.genero
WHERE NOT EXISTS (SELECT 1 FROM album_coletanea c WHERE c.titulo = v.titulo);

INSERT INTO coletanea_musica (coletanea_id, musica_id)
SELECT c.id, m.id
FROM album_coletanea c
JOIN LATERAL (SELECT id FROM musica ORDER BY id LIMIT 3 OFFSET (c.id % 5) * 3) m ON true
ON CONFLICT DO NOTHING;

COMMIT;

-- =====================================================================
-- Requisito 5: DCL (controle de acesso)
-- Papeis:
--   spoti_admin    -> usado pela aplicacao: SELECT, INSERT, UPDATE e DELETE
--   spoti_consulta -> somente leitura: SELECT, sem a coluna senha de usuario
-- As senhas abaixo sao apenas de teste.
-- =====================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'spoti_admin') THEN
        CREATE ROLE spoti_admin LOGIN PASSWORD 'senha_admin_teste';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'spoti_consulta') THEN
        CREATE ROLE spoti_consulta LOGIN PASSWORD 'senha_consulta_teste';
    END IF;
END
$$;

-- Conexao: remove o acesso padrao de PUBLIC e libera so os dois papeis.
DO $$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO spoti_admin, spoti_consulta', current_database());
END
$$;

GRANT USAGE ON SCHEMA public TO spoti_admin, spoti_consulta;

-- Administrador da aplicacao: operacoes de CRUD nas tabelas do sistema.
GRANT SELECT, INSERT, UPDATE, DELETE ON
    usuario, usuario_premium, playlist, usuario_playlist, musica, playlist_musica,
    reproducao, genero, album, album_musica, artista, album_artista,
    album_coletanea, coletanea_musica
TO spoti_admin;

-- As colunas serial precisam de acesso as sequences para inserir.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO spoti_admin;

-- Somente leitura: consulta as tabelas, mas nao enxerga a coluna senha.
GRANT SELECT ON
    usuario_playlist, playlist, musica, playlist_musica,
    reproducao, genero, album, album_musica, artista, album_artista,
    album_coletanea, coletanea_musica
TO spoti_consulta;

GRANT SELECT (id, email, nome, data_nascimento) ON usuario TO spoti_consulta;
GRANT SELECT (id, email, nome, data_nascimento, plano, valor_mensal, validade) ON usuario_premium TO spoti_consulta;

-- REVOKE: garante que o papel de leitura nao escreve em nenhuma tabela
-- nem usa as sequences, mesmo que um GRANT mais amplo seja feito depois.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON
    usuario, usuario_premium, playlist, usuario_playlist, musica, playlist_musica,
    reproducao, genero, album, album_musica, artista, album_artista,
    album_coletanea, coletanea_musica
FROM spoti_consulta;

REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM spoti_consulta;
