BEGIN;

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
