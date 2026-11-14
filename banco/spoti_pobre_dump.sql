-- SpotiPobre - Trabalho 2: banco completo (estrutura, dados de teste e DCL)
--
-- Como restaurar (como superusuario, a partir de qualquer banco):
--   psql -h localhost -U postgres -f spoti_pobre_dump.sql
--
-- Este script apaga e recria o banco spoti_pobre e cria os papeis
-- spoti_admin (usado pela aplicacao) e spoti_consulta (somente leitura).
-- As senhas abaixo sao apenas de teste.

DROP DATABASE IF EXISTS spoti_pobre WITH (FORCE);

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

--
-- PostgreSQL database dump
--

\restrict 0IdwFPX4dBBCe5AdojlR0lAR7v520DHOCWTwv8rAe4nNFRqHZOhFWNa0w6eeedx

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: spoti_pobre; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE spoti_pobre WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C.UTF-8';


\unrestrict 0IdwFPX4dBBCe5AdojlR0lAR7v520DHOCWTwv8rAe4nNFRqHZOhFWNa0w6eeedx
\connect spoti_pobre
\restrict 0IdwFPX4dBBCe5AdojlR0lAR7v520DHOCWTwv8rAe4nNFRqHZOhFWNa0w6eeedx

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: backup; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA backup;


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: log; Type: TABLE; Schema: backup; Owner: -
--

CREATE TABLE backup.log (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    comentario text NOT NULL,
    detalhes jsonb,
    data_hora timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: album; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.album (
    id integer NOT NULL,
    titulo text NOT NULL,
    data_lancamento date,
    genero_id integer,
    capa bytea,
    capa_tipo text,
    CONSTRAINT album_capa_coerente CHECK ((((capa IS NULL) AND (capa_tipo IS NULL)) OR ((capa IS NOT NULL) AND (capa_tipo IS NOT NULL) AND (capa_tipo = ANY (ARRAY['image/jpeg'::text, 'image/png'::text, 'image/gif'::text, 'image/webp'::text])))))
);


--
-- Name: album_artista; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.album_artista (
    album_id integer NOT NULL,
    artista_id integer NOT NULL
);


--
-- Name: album_coletanea; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.album_coletanea (
    tema text NOT NULL,
    ano_referencia integer NOT NULL,
    CONSTRAINT album_coletanea_ano_referencia_check CHECK (((ano_referencia >= 1900) AND (ano_referencia <= 2100)))
)
INHERITS (public.album);


--
-- Name: album_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.album_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: album_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.album_id_seq OWNED BY public.album.id;


--
-- Name: album_musica; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.album_musica (
    album_id integer NOT NULL,
    musica_id integer NOT NULL
);


--
-- Name: artista; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.artista (
    id integer NOT NULL,
    nome text NOT NULL
);


--
-- Name: artista_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.artista_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: artista_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.artista_id_seq OWNED BY public.artista.id;


--
-- Name: coletanea_musica; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coletanea_musica (
    coletanea_id integer NOT NULL,
    musica_id integer NOT NULL
);


--
-- Name: genero; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.genero (
    id integer NOT NULL,
    nome text NOT NULL
);


--
-- Name: genero_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.genero_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genero_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.genero_id_seq OWNED BY public.genero.id;


--
-- Name: musica; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.musica (
    id integer NOT NULL,
    nome text NOT NULL,
    duracao time without time zone,
    data_hora_lancamento timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: musica_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.musica_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: musica_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.musica_id_seq OWNED BY public.musica.id;


--
-- Name: playlist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.playlist (
    id integer NOT NULL,
    nome text NOT NULL,
    data_hora_criacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    publica boolean DEFAULT true,
    dados_extras jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: playlist_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.playlist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: playlist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.playlist_id_seq OWNED BY public.playlist.id;


--
-- Name: playlist_musica; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.playlist_musica (
    playlist_id integer NOT NULL,
    musica_id integer NOT NULL
);


--
-- Name: reproducao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reproducao (
    id integer NOT NULL,
    musica_id integer,
    usuario_id integer,
    quando timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: reproducao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reproducao_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reproducao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reproducao_id_seq OWNED BY public.reproducao.id;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario (
    id integer NOT NULL,
    email character varying(200) NOT NULL,
    senha character varying(200) NOT NULL,
    nome character varying(200) NOT NULL,
    data_nascimento date,
    hash_id uuid DEFAULT public.uuid_generate_v4()
);


--
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuario_id_seq OWNED BY public.usuario.id;


--
-- Name: usuario_playlist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario_playlist (
    id integer NOT NULL,
    usuario_id integer,
    playlist_id integer,
    dono boolean DEFAULT false,
    colaborador boolean DEFAULT false,
    usuario_premium_id integer
);


--
-- Name: usuario_playlist_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuario_playlist_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuario_playlist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuario_playlist_id_seq OWNED BY public.usuario_playlist.id;


--
-- Name: usuario_premium; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuario_premium (
    plano text DEFAULT 'individual'::text NOT NULL,
    valor_mensal numeric(8,2) DEFAULT 19.90 NOT NULL,
    validade date DEFAULT (CURRENT_DATE + '30 days'::interval)
)
INHERITS (public.usuario);


--
-- Name: album id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album ALTER COLUMN id SET DEFAULT nextval('public.album_id_seq'::regclass);


--
-- Name: album_coletanea id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album_coletanea ALTER COLUMN id SET DEFAULT nextval('public.album_id_seq'::regclass);


--
-- Name: artista id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artista ALTER COLUMN id SET DEFAULT nextval('public.artista_id_seq'::regclass);


--
-- Name: genero id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genero ALTER COLUMN id SET DEFAULT nextval('public.genero_id_seq'::regclass);


--
-- Name: musica id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.musica ALTER COLUMN id SET DEFAULT nextval('public.musica_id_seq'::regclass);


--
-- Name: playlist id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.playlist ALTER COLUMN id SET DEFAULT nextval('public.playlist_id_seq'::regclass);


--
-- Name: reproducao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reproducao ALTER COLUMN id SET DEFAULT nextval('public.reproducao_id_seq'::regclass);


--
-- Name: usuario id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id SET DEFAULT nextval('public.usuario_id_seq'::regclass);


--
-- Name: usuario_playlist id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_playlist ALTER COLUMN id SET DEFAULT nextval('public.usuario_playlist_id_seq'::regclass);


--
-- Name: usuario_premium id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_premium ALTER COLUMN id SET DEFAULT nextval('public.usuario_id_seq'::regclass);


--
-- Name: usuario_premium hash_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_premium ALTER COLUMN hash_id SET DEFAULT public.uuid_generate_v4();


--
-- Data for Name: log; Type: TABLE DATA; Schema: backup; Owner: -
--

COPY backup.log (id, comentario, detalhes, data_hora) FROM stdin;
\.


--
-- Data for Name: album; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.album (id, titulo, data_lancamento, genero_id, capa, capa_tipo) FROM stdin;
5	A Tábua de Esmeralda	1974-05-15	2	\N	\N
6	Sobrevivendo no Inferno	1997-12-20	9	\N	\N
7	Dois	1986-04-20	5	\N	\N
8	Preço Curto... Prazo Longo	1999-03-06	17	\N	\N
9	Racional Vol. 1	1975-01-01	2	\N	\N
10	Construção	1971-12-01	2	\N	\N
11	Evidências	1989-12-01	3	\N	\N
12	Zeca Pagodinho Ao Vivo	1999-10-10	6	\N	\N
13	O Canto da Ema	1956-06-01	14	\N	\N
14	Fruto Proibido	1975-06-01	5	\N	\N
15	Luz	1982-08-10	2	\N	\N
16	MM	1989-01-15	2	\N	\N
17	Refazenda	1975-05-01	2	\N	\N
18	Faia D'Água	1979-04-12	1	\N	\N
19	Ideologia	1988-04-01	17	\N	\N
20	Tropicalia ou Panis et Circencis	1968-07-01	11	\N	\N
21	AS MELHORES DO IGOR	\N	\N	\N	\N
22	DJAVAN - Só romanticas	\N	\N	\N	\N
23	DJAVAN - Só novelas	\N	\N	\N	\N
1	Clube da Esquina	1972-03-01	2	\\x89504e470d0a1a0a0000000d49484452000000c8000000c804030000005f76b3ad00000018504c5445fbbf24f8ad20f59c1cf28b18ef7a14ec6910ea580c0d0d12bdaa680a000006634944415478daed5c4b6ee436102d960521b3236fe02318c8857ae543cdaa2f142040d6017c03723910306616b13d92587fcac10489366e93221fdf2bb2aa48a93b3d03c07607e22a205dbd51a5cfe4bdc861241983a9ffca82501825837691b7dc1990cd2dd53b190265a34108b1920983beef2b0972378d9093cc24186e3318140a21589ac300807a2e586fd4ec9ac218b98c541e663100be7c3b15fcf1a430f1638c6d368549096040fae59b4c05e731468d3749ae04c12bc96b05e78cce48b0f1362910bf4e66395a65b188f58362350ab631959c58e7f26a5af98765bf282ba410257450cc8da582a258b4cf674af9098692586c78242b0a6b95077e6649a12b0d0e6b9861bb09b6b0622913ba8c9661a72772562f81089f19bd90194389e41189313dd24482d90a4305492225e67d39ab3c507d96702439fcff31bf90c077787cb1e9b6675226c2fc170b151c47e38b2ad9a0020eb795b9d09b09bdf08ced0ec152fbfb3b489ecd89f40e10a6732261a2bce98509a6f395a4e985793a813cb71afb584c448a1cdf792a1b019295305f189cdc44a66a06798e8f64e44dec50ef03482620b2a1e8d472d00b03bb2ea23489aaa34484cb568814839d96f72388277415914ae29964cfe22f22957c340adae28fbe874ba6299c7da16ba8cf0ce29dcf85f5f098b2990a1ad500cb39036714a47b4d938124914c52209748d681a1d15b5b04cbf4e73b6d93143d8b9099a458e8e20349da5b1e152f3a19130fbeae449389ca1de3ee3eafa8bb373b95645f8c79e65485ac5894757450b06ae19d8ef5db32f49bf945479d13b04aef0051e7bf8f8f9e9878b24996e28496ad241d11fd5b5cbfcf417ea5723d26b3f7359ea666ef8e846c8bc79e9229972826ef6bb4499af4be0c8831ac983635690f921ccf2dd4aaa433b13bcaec51efb8c5b637e5bd09f11143198fd3f6e8f410a17b317e406f17007d0ec27573526d9267b2d481498e7691cdc578c5e3138df72765f5c74e16ba6372ff58f91c42065c92fd414fe11f9fc804d1a256a1fd620aba7a6d6cb153247a1f9fb8989e38172ac669ccd7a4bbe2c4c499ed5440ae6c4a0d98fc294d193ec1fc2368847fe05237a6d955c9ac78af5af808f09bd96fb6905cf80800bf3afd0a2af3e32cc82300003cf9dc36864cf87081e1f9513dbefd7d72b9488c0de9e1ca75923e6f9da86a91a6ff1957fcff20ff79907efcf7e5e3d3efff0e26ec13aad7f70fdf49a217317989a8b503a147d5482adf1dec033679d1897437c8b9c5eb0b3862bc9448ec7b6ea708f6fa67b369b4abff39567cf75858076164683c6807656e9a67579f2602a8376af2fc34ac18d4c933cf127881438bb147c5ea3248a31f9254704af7b618bbed514c915e82d4a0177a7177f5fde623dd1e5a8c2d346403488f3b8e26962253dfa31d53c50851bd7ad041364f1f8e9b71c6120ac14e32e90ebd3cf76254f3e68b279c9b6b66225d6985b6a632116d32a3d059757c8b421c194a4a375b577d2a91e85356ef0710de9b5693584d8347798ccd40b09bdc4a173a20507ab3f99766cf851b98be6aa61b5e12b59f0c509bd1bf7461768d0aefbbed3532d3967130c34154afc2eb0b1627b10c1d77dfe26f86c98c73fed5148ddede5be910cd279a21e327a770bb96c807480b526916ff7243aadf1623d25d5eb8cfe574a72ed60f9016a162dd84214ddc16309ac9bfdc7ec8d5fc8235ab769f94d5771aa47b1d7a6f366fbcee99341fca50df224751ce0c92f54c37ee44424bbb884ae379579f49ee5897b19e66579362a2149235e727ef1969eb13a5bc016fd24eeb7dcccd50a47925d4c6a3662bb2375e01ceefed71efd315d71726ebf9abff8b49da3a171f71fec84c72ae2b75a816da0aab6105bb4b186f58b9d1aebe5d74aeb2536b3c5be99362d1672b1da60413c3ca8ddac70704935aaffc16dbb5cba9d62d768b1f32c987ec3766cfe8334b17c7b7b2db390fca282c49e46f900e211462d32af9ae164121264823d502e4465003181d48b5c8fd891ce0856a8608a03d26aa755d7b09c2fc053641cbcafd1c0eca7949b5979e7fb4807a20d0b9315b7f18a10363f67d8c6f9995dff0130fe7b9b3322fa64cfc20c608ff6ccd852742d7ca662b0d2e7bb671e373e1769558ab334d0d85959b94dcd5204613899c53a27a05c6998876641bca25566d1f1f307e05850871d0d96631d63132de26512aa8440057802bf32e8a082001ec40a960200248fc48951813b5fb9ee96c6505b82a25a23b03a4096a69047b0bd517fc05c7fdec2f3ea0391c0000000049454e44ae426082	image/png
2	Transa	1972-01-01	11	\\x89504e470d0a1a0a0000000d49484452000000c8000000c804030000005f76b3ad00000018504c54450ea5e91c9aea2a90eb3885ed467bee5470ef6366f10d0d12ac0e1088000006584944415478daed5c4b8ee4360ca5d80523b3930e324080b950010dcca17ae50b050830079196130301b3e8e96adbe257f2a431486ad170f943ea51d47ba4edae040000cb1dba4f05ff27e57edfcbfbe61300003ccff900f8ebb76ed7e73f1f9b0800b0ccfa006addaee588840956d0078be5cb1f7b27cf17f8e0bc3c02865cb0467c30115b76489e2ff1c1617983823d101af4d15fb83cc275b713c5fbe942f0c3367640c67df4d7fe30fef47cd184f0d3f23a2b37ff843ce2c8918870f9f2bee21dc1aab53e0e51add51bb03b83a47a49a30a78a8e51ecacd0e96906e5459379c09348355c574a3ea08d8fdeca47a0d690338015f4e4ec81d2af5387550500d5635572687b483821a903ac4253d145480d441c6ea2ca10cc44d305587b2c0d317c97d80c4be7f5229ec334a4068867d4f5050382fa62addd98d9d139a53aef3f9c43a6993ca451a14e4814c8b22314edab4cc93120be446de2ea855a873d2aea88964281867de0823bf7e6efdd09b451fc515303a39698e60d5c326efe7a8efefdf6e3e20b5fb5e0250d0530870cac4ea9910693c1f6ade5282f32cc4044f4728504a30cef9d9450b8896d0fd311e0a1a33a22f9afe68e3e78454f58996446cecf16097c28b5f97abe629535b5c48d85a98941386ea2e2632d8028da6af8ae88fa18fac0785844961baa6b8ebe32517dc342a57643441831a4c867f74684e144a5390b4f162421e1f69553dcd1411cd39276df2decdc1d0cd900286a7d8cefa20efc4552b2e2075a762c50f85f6e10ae9a3a5894d98135d1fcf56496fe1e8680b5dd3581d8da2922a6c13e46a1fab36b276d88f433d74b07345596accc469a65a298bd1db11918fb61bd7cef93b22e5cce6a37a0f89351fe5a0318848714746636a17cd1e9ccdc8aed182c513b0861c0d046c686ce24442735597d862d34c99dab43efee77e0801bce4e0881729e1a2b9b5665e8cca2503057793ef48c46e6c94f0a4dc94b008da757e1040661895e72724c93a55ef35d1143e7061f099148e959e2dc40b783c89c6dba9ce7b73202155566a643de168f3d9c6e7a4b9e94258b5348ea4cd351738f920d6456ae89977b24e689139a1081bfbf7e23899d3fc8a6fd7b48c6e246d761cb768ce2cf7c3cb35de7051d4077c0dd284fd80f93888fbee2fc1d0536c732a1700f6bda07605419e5edfe85e1199ceaec6bc53b384d2ebdfa820834eeeccd6af89e47f27ff51272bb3f50b21d9350adb71234f3a497abc567920a6137368db09916f74280e9abf6cddfd4dde3847277e5b21aef1e142627bb930bbb23d53d94a930f5c272992cec98a808d2499999ddda98f9ed59102f8b8133e82bb8410643d5ac9c0e7439206a2e57292f49cc901ca43075aee395689ac6174e948e73d8522e7ceae1cd304d5499606780858f15d7370923d834fa5df72b24e84eacbd43d486158dd1053b10067395cc935d9b192637f316a865334edd2878b5676b3899b7df6348243f10ece1bea3218d333c90cc21c943c46f52962c4757246634125d54bcaae858ca36b2d42c668b249760f204bc98c36fb66e73fb32573e2b35305158c594c660fad94d06e0589ca26c5e343b180ae8c2a0e1c59ce0ef4b149c9967c69f50b3a8b9ca3d5a2177be76416343e37263eda0b4bc9a7f107bb7cb350062ac1a4d04aac7a33d81aa55a2ee624abfc829714a2c60011ae8092757ec1591af70c0865f61d05d2f30bca66dd0458ac10a093bbfdc162a803e7aa2edf58502b65cb40b03812435548723cb338a2d56fe024bb82ccae1b38aa90585ebae36cb5878690448a3b918dd142ab79e98f89dd6f8e6862441f1fdfd0513497ec95308163114c28bcbd92fd6c7cf3c83b4039bd0f53421471f30a49b1ff854a64e35b3ff8dc60ac2e158b7c346ed58cff6245d2cbd434e624fbfbf8817a881f5ad65aecc1809daf49bd32e6e980696c8c26d6b16025ab9d1b08982e2b382c5701594151aea6b2373b9aa0e0ad46bded820d95166ed8c7c9d68a4a7ccaa88f1310b97518aebb184ba84e75b14b22531f6155aafab192a8b7b3a955bdd98c0a483b2047aa2f6e43ca005207c4f3143b95c8eeb38db52b249238e4ea4dbc643f1028554e54cf8fba74c736ae24ca0d6253602c9195d3f8417d972e7f7d0501d7715e742c9b57ebb8015c504508d76e6fb4b2025c5276715158df9c6c70d5b424e1dd1040e68d9d72d1843c2c23f7124ab9c6c7b6a7faf50a2fcc54aefb5f22fbfbdbefe7e39fbecffb78398ad606b358181f3ba3ff003490edd3e1e5d5670000000049454e44ae426082	image/png
3	Elis & Tom	1974-08-01	4	\\x89504e470d0a1a0a0000000d49484452000000c8000000c804030000005f76b3ad00000018504c5445a78bfab27fe9be74d9d55eb9e053a9ec4899c969c90d0d12ee262067000006da4944415478daed5c3d8eeb361026473290d75155da1cc1882fa0c207d8e6dd730fe0421730e02304a9d289e5062b8329f6c72239bf9436ef01898ab55726f5cdf7cd901c52a2fc77e79c73eef5d915870faee998ab33dfe1fdcb6e186ea8ce3cbf83bcee8681a0bc0241a41d03a90b3891610346ad02a044bcdb7494d57b8c08e7908109a347a1b90679563a24071f9c4b91724b2c415e756221fcfc40c0f8ca27cf1ab1fc60399d470ed44482e15af44f21077996c51ad866e3074130d034f5c1de9564e7a0542be80c55500d2b9067412c5d2f8685de034422a2ed29917281b0bc2a6ae88deb2633e38edf8081940d2888df34aad432a02061dba8e2092ac015328f2a038e0a8ce10d23d78052019a88df61e8f51548d86198f7182890bf370ef303020a94e57ea75c2564207ea79c08f1ac2778d2629ddf3f2fca4435450a8468eafd98fdbb4c8a4e6c0d52652222040d3317ff793d91336af64541c56b892034683205151404217266e2e9225099018b581b06f2631ec60190b3de8681fd9c99e94143e42c35c0b39ca64a43cf596ee667960ad4d70d768cba90af41823483918f91cf85f95e946c1f423baa7261cf105162d48c430112f4550d8231728526b190b23e0761d4326054ac03c924b48a559be43390d020b3c981c0b5762391d2a8b002f1945afd6805c96b78dc58af10eb7e7bfb3cc9827d2c19f86c18cc462b94c875f5bd3b0ae3e4c7d805a664eb7ea5ff6352b09e4e154796c6db898a4c2f4697678b6386d7e74674121408b546c2e102bb5e9a047144088c1a050917f0845a65d91be9de1b635de099483e57707c30215c52a87567039bd6cbb34c468bb157218a89e95caf7508f6fbc8cc19d57a980b1073c6d144a428d133135352adab82eb8d0b7f90a7bbf74d8a0692c96813ab2cd54b29d1571c80f9bd37ab55141b73cf832d70dacaf598df4796c880df73b8134e095166521a380cf9a7860a1893ec41b78c34e2204115ff0333dbbf93d9040866dcb8659d81d4ab6f6f27836b5b090543f47b6105ed2e81789cea4d48fd3ca5d7b8ae065beeb76a0503b55a5e5e72bceb4146e5cd5616bbc740c2a67e8b2deff53ef1eadbc91ab97ae3b5bcdcb180d2ef5eb5da7c67996cbc6dcd1f015a6fe45b16dc8113f36636fa86ba1636c6962abefee56c850daea0a479ff714c7a95ac3e5f21b8b20f2bd4b5ad4cba23b5e261f189b032745cfd55af1881ad4fedb20f6d3f0cb6f67e2c3e756ddee693aefab247b6f2f58d9172bbd6f53f3393ff41fea320b7b691f9276212cb812f1f01d3be4c6e4d794c05b238aeebb84bab148f3a53bb4f6e2d0919e4a21347ca17b6ae84cba8dae6fb30f7eb97b593a8e3d900d2d96deeb63049cd347190699f56be68991c55d626e784511994bedb72446d634c1b5c82c8b5e0b11235f01dee5a75b792da897c82c4af7349c2984c78b04405c3231ac1865e3835ab258074fc2686f264278024bcad4a4693e130adab8136c3c6af18e9d27a9f74fcae8f59d76b034f95df5b32abbac7154854e8555c76e6cb3e4406c18c8ee63233d24edb9eb598a95b1b9c67bf7d7cfbf638f9e76f8fefbffe5556797979797979a92ff5fb4a8b3fb20084b651db5610b0905f34c1cf85c894372e703b51e9cc7dd7b45f1291832455d7e2aca522c96431ebd5714200ded965c54eca6530ccc4a41eb48e1b4b00de932fb600ebc8b0891c93c944e5c8c5560e12692a3cca89b4ef4d1d889b9b9aac2650c3ebc419cbd15ceae11992b2d51eb5913509dd4a640a936e3931c6a50f9048e8b53815ca890bcb28662b25ef0ef14b756ec1d7ead7e6477ecdfe543e5374d265b6a0efb02bc3316a13713f61fd5ce2203f6cc93e07993fc93fe3207edb239d39c6e723fc90c75492bdc81d139e2883a19279d85d8344324d5fb61049642291365059a8690594178e9abd329a3d22493f675c5ac5aa3ac8c84ca7a656afc70284d14b2d58592eb119646a136c626693505b1f155b8b9cb46527d583566227b9173b466e2968e6eb17334612d7859333a25c043bd195bb6843b908c1937edc66b07db7b53d40343b0d1b37e83df6ce69a8b46d355cef02fc019b26b7bcae62ae780115b7b17d5db3ba1039fb6d5ef38ef57556738bbf7fc99750beedf2ba9548cf199b054bd8ffc013dd2a563d314d4ebbfaa7162bd5f3bdc22b76b7cc383160058adb1cf271229fb99654ea13b6d72fa033ad24d7b360247c0e5e5baee682d8f339757812c256cb0529f779313848aed6a160a556f313898a4b8af632b37724c01de4a89dedef87aaa60eb23a337f8359ba7d03aed00befb2120d43fc5424dc075533a7ae45a19709f7932e9c90ebd104e7f2aec3417ba32acdcad7381597f0df5dfd1a32bfe5c55a8801e0302a71578cf7107e723b651178f5379083db3e283242bc37c627e7764abbb0baef2007b79f5b2a150eff00ad63f044197cd5a80000000049454e44ae426082	image/png
4	Cartola	1976-01-01	1	\\x89504e470d0a1a0a0000000d49484452000000c8000000c804030000005f76b3ad00000018504c544522c55e1eb7601baa63189d6615906812836b0f766e0d0d1296ed6358000006194944415478daed5c3b92e33a0c24502ac7e40d15eda136f20dc9d80936988f450a7f69abded43e2733638b041a20bb015a1a28dfaf5f657ed128175fedf3e7f6fdce63bd44b3d14f1371af513f7e8208a44b434f08a14a977e7eb24940c8c4f0beb44b786841e203d2cdf873505000c2ce465dc9d29043fb65647704ababcb8df7800e461ef6cad260284e8c774e7e99c1eaa19d31a705954511b7c1aebdaf703dac6075ef26ef5cc090493be56d7097d287110b488f10d6f9e2810e20211bcce584fca2bb60831980a7689193c434f6658cecda15195559c7a00124a75ccb2834a026d5915623bb0624abbc6336f2503ccfcbfc34125520174a89e34c9b362bd97b41d6f7f1fe647bc8b34ac13abe4f5d525e7a5bd97619c8f0152b45a823480a97192c1e1d6fe61bca264f3b22d54a679243ec661c1690eea792e37c1800a29712d44528e8cf88b933bb040525df478917f95df01405dfa9641a89ce43412710278b75160a3a33e265b1c1fd8dfcbc699d5f11d36c64dca3f3c440410fe890acf4b351e43ca0724556ce028e8e89821a7cbe1c6d5fc21adcf9aa5e8d565c83075bd52735d81730fad693e1de5e73489aa5ef82329209e490a5ce9612c4b40ef3bbc39495a1fcc9c91f9edeb4809ce754e4ca10ad50d7d5ad32558d163915f8048f0248dc24464319896a4a0224a611b7de9f8c80aa7479220c505d0f73fcd108b94884a2d2eb4332624429122b2ec3651176c87c176ca217086538fe60c495929113450b09255465d8adc37cd148c82389adc348c7c1195514e7a294ce53a83f512b4a2f94777f42b6c3e34ad5a574bfe46a1f9b5e4490d9627b4e5799de9ad8c40ff6f3e1ec41f5b3f5e1d278ceb7b55a3171a363624bbaba954db417977dce669df66174d172b50419452ea6f93b50d962705f5366b7a2e91a45cfd9ce1516a6c828283ec2d9ca0833be467b184ac2c85d87e9e3e5c00b2361a1446947ca5194adfa016dc0724d8f5c2ee05d15846610034e8d2c19e0b82b5abeaa7e5c2c21f2ddef85d6c13072eb06a5d812be79c79b946f06746437e3df4272cf6b7387e333008fbd94dfc1e51545f2d8cbf9f69354b886bc37f6c2dc1ba2831a51248fc2df777453e26982b08748013340a250fe83fb64677efb9948fe37f28f1a7932bffd3824504a29afafbf5efc45f51624cf4cb42c23ab6b2f15c80a5c35522d282120c71bfba07840bd9e45d678300b09e7ebf5fb676e4628ee70ceb9acff107741092e6c6d184c466a6a668f3dcc0e8c388435b275934ea0311de4c2352f662cb7c5ab7a90d86baa7a5d800bfb049219c3dc428a398610f1bee6aec3d0c683dcfac6189f569779584660cc7be9064e505d417ee34130603a428cb249b54dc3653de1020635a0277cbac10c583548021d1baf1a0f4d34cb0b8c3351699355688a4f7036e26593e3bcadba34be26d8b7b5f9a7ce2f5b967d5b805f50ba0092e504c72fe8ca045c2b04b068cc1687029c452c615ef503810392eaf0b85e11680c3a952253f46ef41a07024724704b911a68b1e58dde4af479b33a19a92ee7a3ad038848948d1eadeaeb6c044af6e93bdfc7584c35705a69724c305431d6c0eaabab91ea1c693e17cb0f453d7d55d1445991d79118ade59a2fe7c62991c52667a73978dc89440d1023acd54ab57462338971b0d58a7e7bf592d82d498c2d32084d62cc9c492c11c7788d1e177ab4377abd0ac4d33a404d3ee07fde27b5449a8540d68fc71ee06c38a21a0cdec38250c0180d461731423a584b63aa568c2ddb5256adb80bc8553143804e6274a6856fedd0cbf12e2b82cea39be31d569a103cf4979ca69526ad340c1023346f4bac55f52631b610c301fbfd89cdf14dba47b16901c76023c02a3ad7ce1f9d84c75ec47b29c9f77871b3e2b7bd4a98e3a1799ec5aee2775a4b6d5247b2c25fcbd4e75d1c2f8fc4e58bc95aca2da7d06b05a941f94b5fd2d43b02b68cc2f58b5c28d7ad00738cfed439fe62423e8de850fcd26bd75d4aaedb451b1f469e99eeca6f03b09cbfc3af57ac705d17160f14bf15eedff97ce6c484e2b5d28c3b0b2cb9aab143e9e36470b829b0841ff274a0857755fff250960e4628338e05f7d3f5adb79219c183a9e07ef912dd82ef7fb0184cb76ae69e595538b4cdf2fb72f3e251e28db50deb5c2b94f83f3d1229ff0f9858d784d0cbf4680000000049454e44ae426082	image/png
\.


--
-- Data for Name: album_artista; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.album_artista (album_id, artista_id) FROM stdin;
1	7
2	1
3	3
3	6
4	5
5	17
6	11
7	9
8	10
9	8
10	4
11	13
12	14
13	15
14	16
15	18
16	12
17	2
18	6
19	20
21	21
22	18
23	18
\.


--
-- Data for Name: album_coletanea; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.album_coletanea (id, titulo, data_lancamento, genero_id, capa, capa_tipo, tema, ano_referencia) FROM stdin;
24	Os Melhores do Samba	2018-03-10	1	\N	\N	Samba de roda	2018
25	MPB para Ouvir na Chuva	2021-06-01	2	\N	\N	Tardes de chuva	2021
26	Rock Brasil Anos 80	1995-09-15	5	\N	\N	Geracao 80	1985
\.


--
-- Data for Name: album_musica; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.album_musica (album_id, musica_id) FROM stdin;
1	1
2	2
3	3
4	4
5	5
6	6
7	7
8	8
9	9
10	10
11	11
12	12
13	13
14	14
15	15
16	16
17	17
3	18
19	19
20	20
21	21
1	2
\.


--
-- Data for Name: artista; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.artista (id, nome) FROM stdin;
1	Caetano Veloso
2	Gilberto Gil
3	Elis Regina
4	Chico Buarque
5	Cartola
6	Tom Jobim
7	Milton Nascimento
8	Tim Maia
9	Legião Urbana
10	Charlie Brown Jr.
11	Racionais MC's
12	Marisa Monte
13	Chitãozinho & Xororó
14	Zeca Pagodinho
15	Luiz Gonzaga
16	Rita Lee
17	Jorge Ben Jor
18	Djavan
19	Gal Costa
20	Cazuza
21	IGOR VOZ E VIOLÃO
\.


--
-- Data for Name: coletanea_musica; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.coletanea_musica (coletanea_id, musica_id) FROM stdin;
24	13
24	14
24	15
25	1
25	2
25	3
26	4
26	5
26	6
\.


--
-- Data for Name: genero; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.genero (id, nome) FROM stdin;
1	Samba
2	MPB
3	Sertanejo
4	Bossa Nova
5	Rock Nacional
6	Pagode
7	Funk
8	Forró
9	Rap Nacional
10	Axé
11	Tropicalismo
12	Choro
13	Maracatu
14	Baião
15	Frevo
16	Samba-Enredo
17	Pop Rock Brasil
18	Reggae Nacional
19	Nova MPB
20	Sertanejo Universitário
\.


--
-- Data for Name: musica; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.musica (id, nome, duracao, data_hora_lancamento) FROM stdin;
1	Tudo O Que Você Podia Ser	00:02:56	1972-03-01 00:00:00
2	You Don't Know Me	00:03:50	1972-01-01 00:00:00
3	Águas de Março	00:03:32	1974-08-01 00:00:00
4	O Mundo É Um Moinho	00:03:54	1976-01-01 00:00:00
5	Os Alquimistas Estão Chegando os Alquimistas	00:03:15	1974-05-15 00:00:00
6	Diário de um Detento	00:07:31	1997-12-20 00:00:00
7	Tempo Perdido	00:05:00	1986-04-20 00:00:00
8	Zica do Bagui	00:03:05	1999-03-06 00:00:00
9	Imunização Racional (Que Beleza)	00:05:10	1975-01-01 00:00:00
10	Construção	00:06:24	1971-12-01 00:00:00
11	Evidências	00:04:39	1989-12-01 00:00:00
12	Deixa a Vida Me Levar	00:04:35	1999-10-10 00:00:00
13	Asa Branca	00:03:04	1956-06-01 00:00:00
14	O Ovelha Negra	00:05:07	1975-06-01 00:00:00
15	Sina	00:05:33	1982-08-10 00:00:00
16	Bem Que Se Quis	00:02:55	1989-01-15 00:00:00
17	Refazenda	00:03:20	1975-05-01 00:00:00
18	Garota de Ipanema	00:05:19	1964-03-01 00:00:00
19	Ideologia	00:04:06	1988-04-01 00:00:00
20	Alegria, Alegria	00:02:43	1968-07-01 00:00:00
21	Samba Elis e Tom	00:05:00	2026-11-14 15:28:40.164442
22	musica	00:02:00	2026-11-14 15:28:40.164722
23	musica	00:02:00	2026-11-14 15:28:40.164956
24	musica	00:02:00	2026-11-14 15:28:40.165198
\.


--
-- Data for Name: playlist; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.playlist (id, nome, data_hora_criacao, publica, dados_extras) FROM stdin;
1	PLAYLIST DO TOM HARDY	2026-11-14 15:28:40.128359	t	{}
2	playlist sem dono	2023-01-10 14:00:00	t	{}
7	Rap e Poesia do Brasil	2023-04-05 10:45:00	t	{}
9	Pagode Retrô	2023-05-01 23:00:00	t	{}
10	Grandes Vozes Femininas da MPB	2023-05-18 09:30:00	t	{}
11	Viagem no Tempo: Anos 70	2023-06-02 11:10:00	t	{}
14	Nostalgia Brasil	2023-07-19 13:40:00	t	{}
15	Clube da Esquina & Amigos	2023-08-08 17:50:00	t	{}
17	Brasil Secreto	2023-09-12 12:00:00	f	{}
18	Para Cantar na Estrada	2023-10-01 15:30:00	t	{}
20	Música Popular da Bahia	2023-11-05 19:00:00	t	{}
21	Soul & Funk Raiz BR	2023-11-28 01:20:00	t	{}
22	Festival MPB Ao Vivo	2023-12-15 14:15:00	t	{}
3	MPB Essencial	2023-01-10 14:00:00	t	{"tags": ["mpb", "brasil", "classicos"], "clima": "nostalgico", "destaque": true, "descricao": "Selecao de classicos da MPB"}
4	Clássicos do Samba	2023-02-15 18:30:00	t	{"tags": ["samba", "brasil", "classicos"], "clima": "animado", "destaque": true, "descricao": "Os sambas que todo mundo canta junto"}
5	Rock Nacional Anos 80 e 90	2023-03-01 08:00:00	t	{"tags": ["rock", "brasil", "anos80"], "clima": "energetico", "destaque": false, "descricao": "Rock brasileiro de duas decadas"}
6	Bossa Nova & Café	2023-03-12 21:15:00	t	{"tags": ["bossa nova", "cafe"], "clima": "relaxante", "destaque": false, "descricao": "Para uma tarde tranquila"}
8	Churrasco com Sertanejo	2023-04-20 16:20:00	t	{"tags": ["sertanejo", "festa"], "clima": "animado", "destaque": false, "descricao": "Trilha para o fim de semana"}
12	Samba de Raiz	2023-06-25 20:00:00	t	{"tags": ["samba", "raiz", "classicos"], "clima": "nostalgico", "destaque": true, "descricao": "Samba tradicional, de roda de quintal"}
13	Forró Pé de Serra	2023-07-04 07:00:00	t	{"tags": ["forro", "nordeste", "festa"], "clima": "animado", "destaque": false, "descricao": "Forro raiz do Nordeste"}
16	Músicas para Trabalhar	2023-08-30 22:10:00	f	{"tags": ["foco", "trabalho"], "clima": "focado", "destaque": false, "descricao": "Para manter o foco"}
19	Baladas Românticas Nacionais	2023-10-22 06:30:00	t	{"tags": ["romantico", "brasil"], "clima": "romantico", "destaque": false, "descricao": "Para ouvir a dois"}
\.


--
-- Data for Name: playlist_musica; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.playlist_musica (playlist_id, musica_id) FROM stdin;
1	3
1	10
1	15
2	4
2	12
3	7
3	8
3	14
3	19
4	3
4	18
5	6
6	11
7	12
8	3
8	14
8	16
9	1
9	2
9	5
\.


--
-- Data for Name: reproducao; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reproducao (id, musica_id, usuario_id, quando) FROM stdin;
\.


--
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuario (id, email, senha, nome, data_nascimento, hash_id) FROM stdin;
2	rafael.betito@riogrande.ifrs.edu.br	202cb962ac59075b964b07152d234b70	Rafael Betito	1995-03-15	f81bfe62-0262-4054-8fcf-2ff409cd81a8
3	joao.silva@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	João Silva	1995-03-15	78b8e368-da07-499b-96cc-79565fcd727d
4	maria.oliveira@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Maria Oliveira	1998-07-22	3e80ea14-8bae-4d7d-8090-a5c5d72fd788
5	carlos.eduardo@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Carlos Eduardo	1990-11-05	fbfeb0de-5fd6-4ff3-9b6a-4d9e04500d10
6	ana.beatriz@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Ana Beatriz	2001-01-30	434f8374-7e22-42d7-998d-57debd1a0d36
7	lucas.mendonca@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Lucas Mendonça	1997-09-12	389bd862-cedd-4909-bf06-69e9807a690c
8	jessica.lima@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Jéssica Lima	1993-05-18	9adee512-47b8-412e-9f64-9f152d903b24
9	rodrigo.santos@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Rodrigo Santos	1988-12-01	d1b91ee4-d3b7-4cc9-ac37-43be9b0eccc2
10	camila.rocha@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Camila Rocha	2002-04-10	e637503b-810a-436f-a05e-086a0a85b6d1
11	felipe.alves@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Felipe Alves	1996-08-25	0f521b0e-aae0-403e-9b92-eb304bbf1791
12	larissa.ferreira@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Larissa Ferreira	1999-02-14	85b25da9-a234-4fc5-a5de-b2cef6b817dc
13	bruno.costa@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Bruno Costa	1992-06-30	9b9c71e3-4bf1-4319-8f51-1eb3d1346e1f
14	patricia.gomes@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Patrícia Gomes	1985-10-20	9da82395-9166-4e2c-a6f9-9a77bcb4e160
15	gabriel.souza@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Gabriel Souza	2000-11-11	4c7134be-1a7c-4069-9650-f31410e811c5
16	amanda.martins@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Amanda Martins	1994-03-08	a578aeef-76be-4c70-9e68-9b7b6a5aba09
17	rafael.barbosa@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Rafael Barbosa	1991-07-04	54b74c54-8167-4185-8cfa-d656e35abac3
18	fernanda.lima@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Fernanda Lima	1997-12-24	acc7d422-a60f-4ef4-954b-79430226a5d6
19	diego.ribeiro@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Diego Ribeiro	1989-01-19	7e90ad97-9eb3-4c1b-a6a8-2acf93fa1eb5
20	juliana.carvalho@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Juliana Carvalho	2003-05-02	85e584c1-78c4-4438-8379-1fe40cbb5b73
21	marcelo.dias@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Marcelo Dias	1996-10-15	a8ff95c9-5f5d-4b41-8a44-31603c9b900b
22	vanessa.nunes@email.com	$2a$12$eImiTXuWVxfM37uY4JANjO	Vanessa Nunes	1998-08-09	1f9f4dbe-0cd3-49e9-b5b0-33073f9cbddc
\.


--
-- Data for Name: usuario_playlist; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuario_playlist (id, usuario_id, playlist_id, dono, colaborador, usuario_premium_id) FROM stdin;
2	21	21	f	t	\N
\.


--
-- Data for Name: usuario_premium; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuario_premium (id, email, senha, nome, data_nascimento, hash_id, plano, valor_mensal, validade) FROM stdin;
1	tomhardy@terradamafia.com.br	202cb962ac59075b964b07152d234b70	Tom Hardy	1970-01-01	d43a2b60-05d7-4035-ad10-b8797ea5fa2b	individual	19.90	2026-12-14
\.


--
-- Name: album_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.album_id_seq', 26, true);


--
-- Name: artista_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.artista_id_seq', 21, true);


--
-- Name: genero_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.genero_id_seq', 20, true);


--
-- Name: musica_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.musica_id_seq', 24, true);


--
-- Name: playlist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.playlist_id_seq', 22, true);


--
-- Name: reproducao_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reproducao_id_seq', 21, true);


--
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuario_id_seq', 22, true);


--
-- Name: usuario_playlist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuario_playlist_id_seq', 22, true);


--
-- Name: log log_pkey; Type: CONSTRAINT; Schema: backup; Owner: -
--

ALTER TABLE ONLY backup.log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


--
-- Name: album_artista album_artista_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album_artista
    ADD CONSTRAINT album_artista_pkey PRIMARY KEY (album_id, artista_id);


--
-- Name: album_coletanea album_coletanea_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album_coletanea
    ADD CONSTRAINT album_coletanea_pkey PRIMARY KEY (id);


--
-- Name: album_musica album_musica_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album_musica
    ADD CONSTRAINT album_musica_pkey PRIMARY KEY (album_id, musica_id);


--
-- Name: album album_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album
    ADD CONSTRAINT album_pkey PRIMARY KEY (id);


--
-- Name: artista artista_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.artista
    ADD CONSTRAINT artista_pkey PRIMARY KEY (id);


--
-- Name: coletanea_musica coletanea_musica_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coletanea_musica
    ADD CONSTRAINT coletanea_musica_pkey PRIMARY KEY (coletanea_id, musica_id);


--
-- Name: genero genero_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.genero
    ADD CONSTRAINT genero_pkey PRIMARY KEY (id);


--
-- Name: musica musica_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.musica
    ADD CONSTRAINT musica_pkey PRIMARY KEY (id);


--
-- Name: playlist_musica playlist_musica_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.playlist_musica
    ADD CONSTRAINT playlist_musica_pkey PRIMARY KEY (playlist_id, musica_id);


--
-- Name: playlist playlist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.playlist
    ADD CONSTRAINT playlist_pkey PRIMARY KEY (id);


--
-- Name: reproducao reproducao_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reproducao
    ADD CONSTRAINT reproducao_pkey PRIMARY KEY (id);


--
-- Name: reproducao reproducao_usuario_id_quando_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reproducao
    ADD CONSTRAINT reproducao_usuario_id_quando_key UNIQUE (usuario_id, quando);


--
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- Name: usuario usuario_hash_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_hash_id_key UNIQUE (hash_id);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: usuario_premium usuario_premium_email_unico; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_premium
    ADD CONSTRAINT usuario_premium_email_unico UNIQUE (email);


--
-- Name: usuario_premium usuario_premium_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_premium
    ADD CONSTRAINT usuario_premium_pkey PRIMARY KEY (id);


--
-- Name: playlist_dados_extras_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX playlist_dados_extras_gin ON public.playlist USING gin (dados_extras jsonb_path_ops);


--
-- Name: usuario_hash_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX usuario_hash_id ON public.usuario USING hash (hash_id);


--
-- Name: album_artista album_artista_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album_artista
    ADD CONSTRAINT album_artista_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.album(id);


--
-- Name: album_artista album_artista_artista_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album_artista
    ADD CONSTRAINT album_artista_artista_id_fkey FOREIGN KEY (artista_id) REFERENCES public.artista(id);


--
-- Name: album_coletanea album_coletanea_genero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album_coletanea
    ADD CONSTRAINT album_coletanea_genero_id_fkey FOREIGN KEY (genero_id) REFERENCES public.genero(id);


--
-- Name: album album_genero_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album
    ADD CONSTRAINT album_genero_id_fkey FOREIGN KEY (genero_id) REFERENCES public.genero(id);


--
-- Name: album_musica album_musica_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album_musica
    ADD CONSTRAINT album_musica_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.album(id);


--
-- Name: album_musica album_musica_musica_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.album_musica
    ADD CONSTRAINT album_musica_musica_id_fkey FOREIGN KEY (musica_id) REFERENCES public.musica(id);


--
-- Name: coletanea_musica coletanea_musica_coletanea_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coletanea_musica
    ADD CONSTRAINT coletanea_musica_coletanea_id_fkey FOREIGN KEY (coletanea_id) REFERENCES public.album_coletanea(id);


--
-- Name: coletanea_musica coletanea_musica_musica_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coletanea_musica
    ADD CONSTRAINT coletanea_musica_musica_id_fkey FOREIGN KEY (musica_id) REFERENCES public.musica(id);


--
-- Name: playlist_musica playlist_musica_musica_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.playlist_musica
    ADD CONSTRAINT playlist_musica_musica_id_fkey FOREIGN KEY (musica_id) REFERENCES public.musica(id);


--
-- Name: playlist_musica playlist_musica_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.playlist_musica
    ADD CONSTRAINT playlist_musica_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlist(id);


--
-- Name: reproducao reproducao_musica_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reproducao
    ADD CONSTRAINT reproducao_musica_id_fkey FOREIGN KEY (musica_id) REFERENCES public.musica(id);


--
-- Name: reproducao reproducao_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reproducao
    ADD CONSTRAINT reproducao_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: usuario_playlist usuario_playlist_playlist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_playlist
    ADD CONSTRAINT usuario_playlist_playlist_id_fkey FOREIGN KEY (playlist_id) REFERENCES public.playlist(id);


--
-- Name: usuario_playlist usuario_playlist_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_playlist
    ADD CONSTRAINT usuario_playlist_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: usuario_playlist usuario_playlist_usuario_premium_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuario_playlist
    ADD CONSTRAINT usuario_playlist_usuario_premium_id_fkey FOREIGN KEY (usuario_premium_id) REFERENCES public.usuario_premium(id);


--
-- Name: DATABASE spoti_pobre; Type: ACL; Schema: -; Owner: -
--

REVOKE CONNECT,TEMPORARY ON DATABASE spoti_pobre FROM PUBLIC;
GRANT CONNECT ON DATABASE spoti_pobre TO spoti_admin;
GRANT CONNECT ON DATABASE spoti_pobre TO spoti_consulta;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA public TO spoti_admin;
GRANT USAGE ON SCHEMA public TO spoti_consulta;


--
-- Name: TABLE album; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.album TO spoti_admin;
GRANT SELECT ON TABLE public.album TO spoti_consulta;


--
-- Name: TABLE album_artista; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.album_artista TO spoti_admin;
GRANT SELECT ON TABLE public.album_artista TO spoti_consulta;


--
-- Name: TABLE album_coletanea; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.album_coletanea TO spoti_admin;
GRANT SELECT ON TABLE public.album_coletanea TO spoti_consulta;


--
-- Name: SEQUENCE album_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.album_id_seq TO spoti_admin;


--
-- Name: TABLE album_musica; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.album_musica TO spoti_admin;
GRANT SELECT ON TABLE public.album_musica TO spoti_consulta;


--
-- Name: TABLE artista; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.artista TO spoti_admin;
GRANT SELECT ON TABLE public.artista TO spoti_consulta;


--
-- Name: SEQUENCE artista_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.artista_id_seq TO spoti_admin;


--
-- Name: TABLE coletanea_musica; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.coletanea_musica TO spoti_admin;
GRANT SELECT ON TABLE public.coletanea_musica TO spoti_consulta;


--
-- Name: TABLE genero; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.genero TO spoti_admin;
GRANT SELECT ON TABLE public.genero TO spoti_consulta;


--
-- Name: SEQUENCE genero_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.genero_id_seq TO spoti_admin;


--
-- Name: TABLE musica; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.musica TO spoti_admin;
GRANT SELECT ON TABLE public.musica TO spoti_consulta;


--
-- Name: SEQUENCE musica_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.musica_id_seq TO spoti_admin;


--
-- Name: TABLE playlist; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.playlist TO spoti_admin;
GRANT SELECT ON TABLE public.playlist TO spoti_consulta;


--
-- Name: SEQUENCE playlist_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.playlist_id_seq TO spoti_admin;


--
-- Name: TABLE playlist_musica; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.playlist_musica TO spoti_admin;
GRANT SELECT ON TABLE public.playlist_musica TO spoti_consulta;


--
-- Name: TABLE reproducao; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reproducao TO spoti_admin;
GRANT SELECT ON TABLE public.reproducao TO spoti_consulta;


--
-- Name: SEQUENCE reproducao_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.reproducao_id_seq TO spoti_admin;


--
-- Name: TABLE usuario; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.usuario TO spoti_admin;


--
-- Name: COLUMN usuario.id; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(id) ON TABLE public.usuario TO spoti_consulta;


--
-- Name: COLUMN usuario.email; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(email) ON TABLE public.usuario TO spoti_consulta;


--
-- Name: COLUMN usuario.nome; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(nome) ON TABLE public.usuario TO spoti_consulta;


--
-- Name: COLUMN usuario.data_nascimento; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(data_nascimento) ON TABLE public.usuario TO spoti_consulta;


--
-- Name: SEQUENCE usuario_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.usuario_id_seq TO spoti_admin;


--
-- Name: TABLE usuario_playlist; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.usuario_playlist TO spoti_admin;
GRANT SELECT ON TABLE public.usuario_playlist TO spoti_consulta;


--
-- Name: SEQUENCE usuario_playlist_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.usuario_playlist_id_seq TO spoti_admin;


--
-- Name: TABLE usuario_premium; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.usuario_premium TO spoti_admin;


--
-- Name: COLUMN usuario_premium.id; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(id) ON TABLE public.usuario_premium TO spoti_consulta;


--
-- Name: COLUMN usuario_premium.email; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(email) ON TABLE public.usuario_premium TO spoti_consulta;


--
-- Name: COLUMN usuario_premium.nome; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(nome) ON TABLE public.usuario_premium TO spoti_consulta;


--
-- Name: COLUMN usuario_premium.data_nascimento; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(data_nascimento) ON TABLE public.usuario_premium TO spoti_consulta;


--
-- Name: COLUMN usuario_premium.plano; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(plano) ON TABLE public.usuario_premium TO spoti_consulta;


--
-- Name: COLUMN usuario_premium.valor_mensal; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(valor_mensal) ON TABLE public.usuario_premium TO spoti_consulta;


--
-- Name: COLUMN usuario_premium.validade; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(validade) ON TABLE public.usuario_premium TO spoti_consulta;


--
-- PostgreSQL database dump complete
--

\unrestrict 0IdwFPX4dBBCe5AdojlR0lAR7v520DHOCWTwv8rAe4nNFRqHZOhFWNa0w6eeedx

