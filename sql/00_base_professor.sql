DROP DATABASE IF EXISTS spoti_pobre;
CREATE DATABASE spoti_pobre;

-- plpsql
\c spoti_pobre;

-- uuid
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- DDL
CREATE SCHEMA backup;
SET search_path TO public, backup;

CREATE TABLE backup.log (
    id uuid DEFAULT uuid_generate_v4() primary key,
    comentario text not null,
    detalhes jsonb,
    data_hora timestamp default current_timestamp
);

CREATE TABLE usuario (
    id serial primary key,
    email character varying(200) unique not null,
    senha character varying(200) not null,
    nome character varying(200) not null,
    data_nascimento date,
    hash_id uuid DEFAULT uuid_generate_v4() UNIQUE
);
-- se eu desejasse otimizar consultas de tuplas de usuario usando muito a coluna uuid
CREATE INDEX usuario_hash_id ON usuario USING hash (hash_id);


CREATE TABLE usuario_premium (
    plano text NOT NULL DEFAULT 'individual',
    valor_mensal numeric(8,2) NOT NULL DEFAULT 19.90,
    validade date default current_date + interval '30 days'
) INHERITS (usuario);
ALTER TABLE usuario_premium ADD CONSTRAINT usuario_premium_pkey PRIMARY KEY (id);
ALTER TABLE usuario_premium ADD CONSTRAINT usuario_premium_email_unico UNIQUE (email);

INSERT INTO usuario_premium (email, nome, senha, data_nascimento) VALUES
('tomhardy@terradamafia.com.br', 'Tom Hardy', md5('123'), '1970-01-01');

CREATE TABLE playlist (
    id serial primary key,
    nome text not null,
    data_hora_criacao timestamp default current_timestamp,
    publica boolean default true
);
INSERT INTO playlist(nome) VALUES('PLAYLIST DO TOM HARDY') RETURNING id;

CREATE TABLE usuario_playlist (
    id serial primary key,
    usuario_id integer references usuario (id) ,
    playlist_id integer references playlist (id),
    dono boolean default false,
    colaborador boolean default false
);
ALTER TABLE usuario_playlist ADD COLUMN usuario_premium_id INTEGER REFERENCES usuario_premium (id);
ALTER TABLE usuario_playlist DROP CONSTRAINT usuario_playlist_pkey;
ALTER TABLE usuario_playlist ALTER COLUMN usuario_id DROP NOT NULL;

INSERT INTO usuario_playlist(usuario_premium_id, playlist_id) VALUES(22, 22);

CREATE TABLE musica (
    id serial primary key,
    nome text not null,
    duracao time,
    data_hora_lancamento timestamp default current_timestamp
);

CREATE TABLE playlist_musica (
    playlist_id integer references playlist (id),
    musica_id integer references musica (id),
    primary key (playlist_id, musica_id)
);


CREATE TABLE reproducao (
    id serial primary key, -- pk
    musica_id integer references musica (id), -- fk1
    usuario_id integer references usuario (id), -- fk2 
    quando timestamp default current_timestamp, 
    unique (usuario_id, quando) 
);  
--alter table reproducao drop constraint reproducao_pkey;
--alter table reproducao add primary key (musica_id, usuario_id, quando);


CREATE TABLE genero (
    id serial primary key,
    nome text not null
);

CREATE TABLE album (
    id serial primary key,
    titulo text not null,
    data_lancamento date,
    genero_id integer references genero (id)
);
-- add 29/09
 ALTER TABLE album ADD COLUMN capa bytea;

CREATE TABLE album_musica (
    album_id integer references album (id),
    musica_id integer references musica (id),
    primary key (album_id, musica_id)
);

CREATE TABLE artista (
    id serial primary key,
    nome text not null
);

CREATE TABLE album_artista (
    album_id integer references album (id),
    artista_id integer references artista(id),
    primary key (album_id, artista_id)
);


-- 1. GENERO
INSERT INTO genero (nome) VALUES
('Samba'),
('MPB'),
('Sertanejo'),
('Bossa Nova'),
('Rock Nacional'),
('Pagode'),
('Funk'),
('Forró'),
('Rap Nacional'),
( 'Axé'),
( 'Tropicalismo'),
( 'Choro'),
( 'Maracatu'),
( 'Baião'),
( 'Frevo'),
( 'Samba-Enredo'),
( 'Pop Rock Brasil'),
('Reggae Nacional'),
( 'Nova MPB'),
('Sertanejo Universitário');

-- 2. ARTISTA
INSERT INTO artista (nome) VALUES
( 'Caetano Veloso'),
( 'Gilberto Gil'),
( 'Elis Regina'),
( 'Chico Buarque'),
( 'Cartola'),
( 'Tom Jobim'),
( 'Milton Nascimento'),
( 'Tim Maia'),
( 'Legião Urbana'),
( 'Charlie Brown Jr.'),
( 'Racionais MC''s'),
( 'Marisa Monte'),
( 'Chitãozinho & Xororó'),
( 'Zeca Pagodinho'),
( 'Luiz Gonzaga'),
( 'Rita Lee'),
( 'Jorge Ben Jor'),
( 'Djavan'),
( 'Gal Costa'),
( 'Cazuza');

INSERT INTO artista (nome) VALUES
( 'IGOR VOZ E VIOLÃO');

-- 3. ALBUM
/*
INSERT INTO album (titulo, data_lancamento, genero_id) VALUES
(21, 'Album do Igor', CURRENT_DATE, 2);
*/
INSERT INTO album (titulo, data_lancamento, genero_id) VALUES
('Clube da Esquina', '1972-03-01', 2),
('Transa', '1972-01-01', 11),
( 'Elis & Tom', '1974-08-01', 4),
('Cartola', '1976-01-01', 1),
( 'A Tábua de Esmeralda', '1974-05-15', 2),
('Sobrevivendo no Inferno', '1997-12-20', 9),
( 'Dois', '1986-04-20', 5),
( 'Preço Curto... Prazo Longo', '1999-03-06', 17),
( 'Racional Vol. 1', '1975-01-01', 2),
( 'Construção', '1971-12-01', 2),
( 'Evidências', '1989-12-01', 3),
( 'Zeca Pagodinho Ao Vivo', '1999-10-10', 6),
( 'O Canto da Ema', '1956-06-01', 14),
( 'Fruto Proibido', '1975-06-01', 5),
( 'Luz', '1982-08-10', 2),
( 'MM', '1989-01-15', 2),
( 'Refazenda', '1975-05-01', 2),
('Faia D''Água', '1979-04-12', 1),
( 'Ideologia', '1988-04-01', 17),
('Tropicalia ou Panis et Circencis', '1968-07-01', 11);

INSERT INTO album (titulo) VALUES ('AS MELHORES DO IGOR');

INSERT INTO album (titulo) VALUES ('DJAVAN - Só romanticas');

INSERT INTO album (titulo) VALUES ('DJAVAN - Só novelas');

-- 4. MUSICA
INSERT INTO musica ( nome, duracao, data_hora_lancamento) VALUES
('Tudo O Que Você Podia Ser', '00:02:56', '1972-03-01 00:00:00'),
( 'You Don''t Know Me', '00:03:50', '1972-01-01 00:00:00'),
('Águas de Março', '00:03:32', '1974-08-01 00:00:00'),
( 'O Mundo É Um Moinho', '00:03:54', '1976-01-01 00:00:00'),
( 'Os Alquimistas Estão Chegando os Alquimistas', '00:03:15', '1974-05-15 00:00:00'),
( 'Diário de um Detento', '00:07:31', '1997-12-20 00:00:00'),
( 'Tempo Perdido', '00:05:00', '1986-04-20 00:00:00'),
( 'Zica do Bagui', '00:03:05', '1999-03-06 00:00:00'),
( 'Imunização Racional (Que Beleza)', '00:05:10', '1975-01-01 00:00:00'),
( 'Construção', '00:06:24', '1971-12-01 00:00:00'),
( 'Evidências', '00:04:39', '1989-12-01 00:00:00'),
( 'Deixa a Vida Me Levar', '00:04:35', '1999-10-10 00:00:00'),
( 'Asa Branca', '00:03:04', '1956-06-01 00:00:00'),
( 'O Ovelha Negra', '00:05:07', '1975-06-01 00:00:00'),
( 'Sina', '00:05:33', '1982-08-10 00:00:00'),
( 'Bem Que Se Quis', '00:02:55', '1989-01-15 00:00:00'),
( 'Refazenda', '00:03:20', '1975-05-01 00:00:00'),
( 'Garota de Ipanema', '00:05:19', '1964-03-01 00:00:00'),
('Ideologia', '00:04:06', '1988-04-01 00:00:00'),
( 'Alegria, Alegria', '00:02:43', '1968-07-01 00:00:00');


INSERT INTO musica ( nome, duracao, data_hora_lancamento) VALUES
('Samba Elis e Tom', '00:05:00', CURRENT_TIMESTAMP);


INSERT INTO musica ( nome, duracao, data_hora_lancamento) values
('musica', '00:02:00', current_timestamp);
INSERT INTO musica ( nome, duracao, data_hora_lancamento) values
('musica', '00:02:00', current_timestamp);

INSERT INTO musica ( nome, duracao, data_hora_lancamento) values
('musica', '00:02:00', current_timestamp);


-- 5. ALBUM_ARTISTA
INSERT INTO album_artista (album_id, artista_id) VALUES
(1, 7),
(2, 1),
(3, 3),
(3, 6),
(4, 5),
(5, 17),
(6, 11),
(7, 9),
(8, 10),
(9, 8),
(10, 4),
(11, 13),
(12, 14),
(13, 15),
(14, 16),
(15, 18),
(16, 12),
(17, 2),
(18, 6),
(19, 20);

INSERT INTO album_artista (album_id, artista_id) VALUES
(21,21);

INSERT INTO album_artista (album_id, artista_id) VALUES
(22, 18);

INSERT INTO album_artista (album_id, artista_id) VALUES
(23, 18);

-- 6. ALBUM_MUSICA
INSERT INTO album_musica (album_id, musica_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10),
(11, 11),
(12, 12),
(13, 13),
(14, 14),
(15, 15),
(16, 16),
(17, 17),
(3, 18),
(19, 19),
(20, 20);


INSERT INTO album_musica (album_id, musica_id) VALUES
(21,21);

INSERT INTO album_musica (album_id, musica_id) VALUES
(1, 2);

-- 7. USUARIO

INSERT INTO usuario (email, senha, nome, data_nascimento) VALUES
('rafael.betito@riogrande.ifrs.edu.br', md5('123'), 'Rafael Betito', '1995-03-15');

INSERT INTO usuario (email, senha, nome, data_nascimento) VALUES
('joao.silva@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'João Silva', '1995-03-15'),
('maria.oliveira@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Maria Oliveira', '1998-07-22'),
( 'carlos.eduardo@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Carlos Eduardo', '1990-11-05'),
( 'ana.beatriz@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Ana Beatriz', '2001-01-30'),
( 'lucas.mendonca@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Lucas Mendonça', '1997-09-12'),
( 'jessica.lima@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Jéssica Lima', '1993-05-18'),
( 'rodrigo.santos@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Rodrigo Santos', '1988-12-01'),
( 'camila.rocha@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Camila Rocha', '2002-04-10'),
( 'felipe.alves@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Felipe Alves', '1996-08-25'),
( 'larissa.ferreira@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Larissa Ferreira', '1999-02-14'),
( 'bruno.costa@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Bruno Costa', '1992-06-30'),
( 'patricia.gomes@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Patrícia Gomes', '1985-10-20'),
( 'gabriel.souza@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Gabriel Souza', '2000-11-11'),
( 'amanda.martins@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Amanda Martins', '1994-03-08'),
( 'rafael.barbosa@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Rafael Barbosa', '1991-07-04'),
( 'fernanda.lima@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Fernanda Lima', '1997-12-24'),
( 'diego.ribeiro@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Diego Ribeiro', '1989-01-19'),
( 'juliana.carvalho@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Juliana Carvalho', '2003-05-02'),
( 'marcelo.dias@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Marcelo Dias', '1996-10-15'),
('vanessa.nunes@email.com', '$2a$12$eImiTXuWVxfM37uY4JANjO', 'Vanessa Nunes', '1998-08-09');

-- 8. PLAYLIST
INSERT INTO playlist (nome, data_hora_criacao, publica) VALUES
( 'playlist sem dono', '2023-01-10 14:00:00', true);



INSERT INTO playlist (nome, data_hora_criacao, publica) VALUES
( 'MPB Essencial', '2023-01-10 14:00:00', true),
('Clássicos do Samba', '2023-02-15 18:30:00', true),
( 'Rock Nacional Anos 80 e 90', '2023-03-01 08:00:00', true),
( 'Bossa Nova & Café', '2023-03-12 21:15:00', true),
( 'Rap e Poesia do Brasil', '2023-04-05 10:45:00', true),
( 'Churrasco com Sertanejo', '2023-04-20 16:20:00', true),
('Pagode Retrô', '2023-05-01 23:00:00', true),
( 'Grandes Vozes Femininas da MPB', '2023-05-18 09:30:00', true),
( 'Viagem no Tempo: Anos 70', '2023-06-02 11:10:00', true),
( 'Samba de Raiz', '2023-06-25 20:00:00', true),
( 'Forró Pé de Serra', '2023-07-04 07:00:00', true),
( 'Nostalgia Brasil', '2023-07-19 13:40:00', true),
( 'Clube da Esquina & Amigos', '2023-08-08 17:50:00', true),
( 'Músicas para Trabalhar', '2023-08-30 22:10:00', false),
( 'Brasil Secreto', '2023-09-12 12:00:00', false),
( 'Para Cantar na Estrada', '2023-10-01 15:30:00', true),
( 'Baladas Românticas Nacionais', '2023-10-22 06:30:00', true),
('Música Popular da Bahia', '2023-11-05 19:00:00', true),
( 'Soul & Funk Raiz BR', '2023-11-28 01:20:00', true),
( 'Festival MPB Ao Vivo', '2023-12-15 14:15:00', true);

-- 9. USUARIO_PLAYLIST
INSERT INTO usuario_playlist (usuario_id, playlist_id, dono, colaborador) VALUES
(21, 21, false, true);

INSERT INTO usuario_playlist (usuario_id, playlist_id, dono, colaborador) VALUES
(1, 1, true, false),
(2, 2, true, false),
(3, 3, true, false),
(4, 4, true, false),
(5, 5, true, false),
(6, 6, true, false),
(7, 7, true, false),
(8, 8, true, false),
(9, 9, true, false),
(10, 10, true, false),
(11, 11, true, false),
(12, 12, true, false),
(13, 13, true, false),
(14, 14, true, false),
(15, 15, true, false),
(1, 2, false, true),
(2, 1, false, true),
(3, 7, false, true),
(4, 8, false, true),
(5, 3, false, true);

-- 10. PLAYLIST_MUSICA
INSERT INTO playlist_musica (playlist_id, musica_id) VALUES
(1, 3),
(1, 10),
(1, 15),
(2, 4),
(2, 12),
(3, 7),
(3, 8),
(3, 14),
(3, 19),
(4, 3),
(4, 18),
(5, 6),
(6, 11),
(7, 12),
(8, 3),
(8, 14),
(8, 16),
(9, 1),
(9, 2),
(9, 5);

-- 11. REPRODUCAO
INSERT INTO reproducao (musica_id, usuario_id, quando) VALUES
(1, 1, '2026-07-01 10:00:00'),
(3, 1, '2026-07-01 10:05:00'),
(11, 2, '2026-07-02 18:30:00'),
(7, 3, '2026-07-03 14:15:00'),
(18, 4, '2026-07-03 20:00:00'),
(6, 5, '2026-07-04 09:45:00'),
(12, 6, '2026-07-05 22:10:00'),
(16, 7, '2026-07-06 11:20:00'),
(4, 8, '2026-07-07 16:05:00'),
(8, 9, '2026-07-08 19:50:00'),
(10, 10, '2026-07-09 23:30:00'),
(13, 11, '2026-07-10 08:00:00'),
(14, 12, '2026-07-11 17:15:00'),
(15, 13, '2026-07-12 13:40:00'),
(19, 14, '2026-07-13 15:00:00'),
(20, 15, '2026-07-14 21:00:00'),
(9, 16, '2026-07-15 10:30:00'),
(17, 17, '2026-07-16 12:25:00'),
(5, 18, '2026-07-17 18:45:00'),
(2, 19, '2026-07-18 01:00:00');

INSERT INTO reproducao (musica_id, usuario_id, quando) VALUES
(1, 1, CURRENT_TIMESTAMP);

/*
select usuario.id, usuario.email, usuario.nome, musica.nome, reproducao.quando FROM usuario INNER JOIN reproducao ON usuario.id = reproducao.usuario_id INNER JOIN musica ON musica.id = reproducao.musica_id where usuario.id = 1;
*/

-- 1/2)
-- SELECT id, nome, email FROM usuario ORDER BY nome;

-- 3)
-- SELECT * FROM usuario WHERE data_nascimento > '1998-01-01' ORDER BY nome ASC;

-- 4)
-- Select nome, publica from playlist where publica is true;


-- 5)
-- a) SELECT * FROM musica WHERE duracao > '00:05:00';
-- b) SELECT * FROM musica WHERE extract(minutes from duracao) >= 5 and extract(seconds from duracao) > 0;

-- 6)
-- a) select * from album where data_lancamento >= '1980-01-01';
-- b) select * from album where extract(year from data_lancamento) >= 1980;
-- c) SELECT album.titulo, to_char(data_lancamento, 'DD/MM/YYYY') AS data_lancamento, genero.nome FROM album JOIN genero ON album.genero_id = genero.id where extract(year from data_lancamento) < 1980 order by album.titulo;


-- 7) SELECT * FROM artista ORDER BY nome DESC;

-- 8) SELECT * FROM musica where extract(year from data_hora_lancamento) > 1990 order by musica.nome;

-- 9) SELECT * FROM genero;

-- 10) SELECT * FROM playlist where publica is FALSE;

-- 11) SELECT usuario.nome, playlist.nome FROM usuario JOIN usuario_playlist ON usuario.id = usuario_playlist.usuario_id JOIN playlist ON usuario_playlist.playlist_id = playlist.id WHERE dono IS TRUE;

-- 12)
-- aqui apenas lista albuns com pelo menos uma musica
-- select album.titulo, musica.nome FROM album JOIN album_musica ON album.id = album_musica.album_id JOIN musica ON musica.id = album_musica.musica_id ORDER BY album.id;

-- aqui tb lista albuns sem musicas
-- select album.titulo, musica.nome FROM album LEFT JOIN album_musica ON album.id = album_musica.album_id LEFT JOIN musica ON musica.id = album_musica.musica_id ORDER BY album.id;

-- 13) vide 6

-- 14) SELECT artista.nome, album.titulo FROM artista JOIN album_artista ON artista.id = album_artista.artista_id JOIN album ON album.id = album_artista.album_id;

-- 15) SELECT usuario.id, usuario.nome, musica.nome FROM usuario JOIN reproducao ON usuario.id = reproducao.usuario_id JOIN musica ON musica.id = reproducao.musica_id;

-- 16) select musica.nome, playlist.nome FROM playlist JOIN playlist_musica ON playlist.id = playlist_musica.playlist_id JOIN musica ON musica.id = playlist_musica.musica_id;

-- off-topic: materia nova (group by): SELECT playlist.id, playlist.nome, count(musica.id) FROM playlist JOIN playlist_musica ON playlist.id = playlist_musica.playlist_id JOIN musica ON musica.id = playlist_musica.musica_id GROUP BY playlist.id HAVING count(musica.id) > 3;

-- 17)
--SELECT album.titulo, musica.nome as musica_titulo, STRING_AGG(artista.nome, ',') as artista_nome, count(artista.id) FROM musica 
--    JOIN album_musica ON musica.id = album_musica.musica_id     
--    JOIN album ON album.id = album_musica.album_id 
--    JOIN album_artista ON album.id = album_artista.album_id 
--    JOIN artista ON artista.id = album_artista.artista_id 
--    GROUP BY musica.id, album.titulo ORDER BY musica_titulo, artista_nome;

-- 18)
--SELECT album.titulo, musica.nome as musica_titulo, STRING_AGG(artista.nome, ',') as artista_nome, genero.nome FROM musica 
--    JOIN album_musica ON musica.id = album_musica.musica_id     
--    JOIN album ON album.id = album_musica.album_id 
--    JOIN album_artista ON album.id = album_artista.album_id 
--    JOIN artista ON artista.id = album_artista.artista_id 
--    LEFT JOIN genero ON genero.id = album.genero_id
--    GROUP BY musica.id, album.titulo, genero.nome ORDER BY album.titulo, musica_titulo, artista_nome;
--

-- 19)
--SELECT usuario.id, usuario.nome, album.titulo, musica.nome, to_char(quando, 'DD/MM/YYYY HH24:MI:SS') as quando FROM usuario 
--    JOIN reproducao on usuario.id = reproducao.usuario_id 
--    JOIN musica ON musica.id = reproducao.musica_id 
--    LEFT JOIN album_musica ON musica.id = album_musica.musica_id JOIN album ON album.id = album_musica.album_id 
--    ORDER BY reproducao.quando ASC;

-- jump 20) schemas para o proxima aula

-- 21)
-- OPCAO 1
--SELECT usuario.id, usuario.nome, playlist.id, playlist.nome FROM usuario LEFT JOIN usuario_playlist on usuario.id = usuario_playlist.usuario_id LEFT JOIN playlist ON playlist.id = usuario_playlist.playlist_id

-- substracao

--EXCEPT 

-- OPCAO 2
--(SELECT usuario.id, usuario.nome, playlist.id, playlist.nome FROM usuario  JOIN usuario_playlist on usuario.id = usuario_playlist.usuario_id JOIN playlist ON playlist.id = usuario_playlist.playlist_id
--UNION
--SELECT usuario.id, usuario.nome, NULL, NULL FROM usuario WHERE usuario.id not in (select usuario_id from usuario_playlist));


-- 22)
SELECT usuario.id, usuario.nome, playlist.id, playlist.nome, dono FROM usuario right JOIN usuario_playlist ON usuario.id = usuario_playlist.usuario_id right JOIN playlist ON playlist.id = usuario_playlist.playlist_id where usuario.nome is null or dono is true;


-- 23)
-- ja feito

-- 24) 
-- ja feito

-- 25)
-- ja feito

-- 26) SELECT musica.id, musica.nome, case when reproducao.quando IS NOT NULL THEN 'FOI REPRODUZIDA' ELSE 'NENHUMA VEZ REPRODUZIDA' END FROM musica LEFT JOIN reproducao on musica.id = reproducao.musica_id;

-- 27) SELECT usuario.id, usuario.nome, musica.nome FROM usuario JOIN reproducao ON usuario.id = reproducao.usuario_id JOIN musica ON musica.id = reproducao.musica_id;

-- 28) ja feito

-- 29)  
-- select playlist.id, playlist.nome, count(musica_id) as qtde FROM playlist JOIN playlist_musica on playlist.id = playlist_musica.playlist_id GROUP BY playlist.id, playlist.nome ORDER BY playlist.id;

-- 30) select usuario.id, usuario.nome, count(playlist_id) as qtde FROM usuario LEFT JOIN usuario_playlist ON usuario.id = usuario_playlist.usuario_id group by usuario.id, usuario.nome ORDER BY qtde;


-- 31) select usuario.nome, playlist.nome FROM usuario RIGHT JOIN usuario_playlist ON usuario.id = usuario_playlist.usuario_id RIGHT JOIN playlist ON playlist.id = usuario_playlist.playlist_id;


-- 32)  select nome, to_char(quando, 'DD/MM/YYYY HH24:MI:SS') as quando FROM musica m JOIN reproducao r ON m.id = r.musica_id ORDER BY m.nome ASC;

-- 33) select count(*) from usuario;

-- 34) select count(*) from playlist;


-- 35) SELECT album.id, album.titulo, count(album_musica.musica_id) as qtde FROM album JOIN album_musica ON album.id = album_musica.album_id GROUP by album.id, album.titulo ORDER BY count(album_musica.musica_id) DESC;

-- 36) select artista_id, artista.nome, count(*) as qtde FROM album_artista INNER JOIN artista ON album_artista.artista_id = artista.id GROUP BY artista_id, artista.nome;

-- 37) select usuario.id, usuario.nome, count(playlist_id) FROM usuario_playlist RIGHT JOIN usuario ON usuario.id = usuario_playlist.usuario_id GROUP BY usuario.id, nome ORDER BY usuario.id;

-- 38)  SELECT to_char(AVG(duracao), 'HH24:MI:SS') AS media FROM musica;

-- 39) SELECT max(duracao), min(duracao), to_char(AVG(duracao), 'HH24:MI:SS') AS media FROM musica;

-- 40) SELECT artista.id, artista.nome, count(album_artista.album_id) as qtde_album, count(album_musica.musica_id) as qtde_musica, count(album.genero_id) as qtde_genero FROM artista JOIN album_artista ON artista.id = album_artista.artista_id JOIN album ON album.id = album_artista.album_id LEFT JOIN album_musica ON album.id = album_musica.musica_id GROUP BY artista.id, artista.nome;


-- 41) SELECT artista_id, artista.nome, count(*) FROM album_artista JOIN artista ON artista.id = album_artista.artista_id GROUP BY artista_id, artista.nome HAVING count(album_id) >= 2 ORDER BY artista_id; 


-- 42) select usuario_id, usuario.nome, count(playlist_id) FROM usuario INNER JOIN usuario_playlist ON usuario.id = usuario_playlist.usuario_id GROUP BY usuario_id, usuario.nome HAVING count(playlist_id) >= 2;

-- 43) select a.id, a.nome, count(am.musica_id) FROM artista a JOIN album_artista aa ON a.id = aa.artista_id JOIN album al ON al.id = aa.album_id JOIN album_musica am ON am.album_id = a.id GROUP BY a.id, a.nome, am.musica_id HAVING count(am.musica_id) >= 2; 


-- 44) jump

-- 45) jump

-- 46) select usuario.id, usuario.nome, to_char(data_nascimento, 'DD/MM/YYYY') as data_nascimento, EXTRACT(YEARS FROM AGE(usuario.data_nascimento)) AS idade from usuario ORDER BY idade;


-- 47) select AVG(EXTRACT(YEARS FROM AGE(usuario.data_nascimento)))::integer AS media from usuario;

-- 48) 

-- 49) select * from musica WHERE extract(year from data_hora_lancamento) between 1970 and 1980; 

-- 50) 
--select 
--            usuario_id, usuario.nome, 
--            musica_id, musica.nome, 
--      CASE 
--        WHEN extract(dow from quando) = 0 then 'domingo' 
--        WHEN extract(dow from quando) = 1 then 'segunda'
--        WHEN extract(dow from quando) = 2 then 'terça'
--        WHEN extract(dow from quando) = 3 then 'quarta'
--        WHEN extract(dow from quando) = 4 then 'quinta'
--        WHEN extract(dow from quando) = 5 then 'sexta'  
--        WHEN extract(dow from quando) = 6 then 'sabado'    
--     end as dia_da_semana
--     FROM reproducao INNER JOIN usuario ON usuario.id = reproducao.usuario_id INNER JOIN musica ON musica.id = reproducao.musica_id;


-- 54) SELECT initcap(usuario.nome) as nome FROM usuario ORDER BY initcap(usuario.nome) asc;

-- 55) SELECT CONCAT(id, ';', nome, ';', email, ';', COALESCE(data_nascimento::TEXT, 'NAO TEM')) FROM usuario;

-- 56) SELECT SUBSTRING(musica.nome,1,5)||'...' from musica;

-- 57) 

-- 60)select artista.nome, album.id, album.titulo, extract(year from data_lancamento), count(album_musica.musica_id) FROM album JOIN album_musica ON album.id = album_musica.album_id JOIN album_artista ON album.id = album_artista.album_id JOIN artista ON artista.id = album_artista.artista_id GROUP BY album.id, artista.nome HAVING count(album_musica.musica_id) >= 2;

-- 61) select * from usuario where id in (select usuario_id from reproducao);

-- 62) select * from musica where id in (select musica_id from album_musica);
--
--with aa AS (
--    select musica_id from album_musica
--)
--SELECT * FROM musica where id in (select musica_id from aa);

-- 63) SELECT artista.id, artista.nome FROM artista JOIN album_artista ON artista.id = album_artista.artista_id where album_artista.album_id IN (SELECT album_id FROM album where extract(year from data_lancamento) < (SELECT CAST(AVG(extract(year from data_lancamento)) AS INTEGER) FROM album)) ORDER BY artista.id, artista.nome;

-- 64) SELECT * FROM usuario where id not in (select usuario_id from reproducao);

-- SELECT * FROM usuario LEFT JOIN reproducao ON usuario.id = reproducao.usuario_id WHERE reproducao.usuario_id IS NULL;

-- SELECT * FROM usuario WHERE id in(SELECT usuario.id FROM usuario EXCEPT select usuario_id FROM reproducao);

-- SELECT * FROM usuario where id not in(SELECT usuario_id FROM reproducao GROUP BY usuario_id);

--SELECT * FROM reproducao RIGHT JOIN usuario ON usuario.id = reproducao.usuario_id WHERE reproducao.usuario_id IS NULL;

--select * from usuario usuario_externo where NOT EXISTS(SELECT * FROM reproducao where usuario_externo.id = reproducao.usuario_id);

-- 65) select * from playlist where id in (select playlist_id FROM playlist_musica GROUP By playlist_id HAVING count(*) > 0);

--CREATE VIEW playlist_com_musica AS select playlist_id FROM playlist_musica GROUP By playlist_id HAVING count(*) > 0;
--
--select * from playlist where id in (select playlist_id FROM playlist_com_musica);
--

-- 66) select * from artista where id in (SELECT artista_id FROM album_artista where album_id IN (SELECT album_id FROM album where genero_id in (select id from genero where nome = 'MPB')));

-- 67) select * from usuario fora where EXISTS(SELECT * FROM reproducao where fora.id = reproducao.usuario_id);

-- 68)  select * from usuario usuario_externo where NOT EXISTS(SELECT * FROM reproducao where usuario_externo.id = reproducao.usuario_id);

-- 69) 
--
--WITH musicas_por_playlist AS (
--    SELECT playlist_id, count(*) as qtde FROM playlist_musica GROUP BY playlist_id
--) SELECT * FROM playlist WHERE id IN (SELECT playlist_id FROM playlist_musica GROUP BY playlist_id HAVING count(*) >= (SELECT avg(qtde) as media FROM musicas_por_playlist));

-- 70) SELECT * FROM album WHERE data_lancamento <= (SELECT MIN(data_lancamento) FROM album);


