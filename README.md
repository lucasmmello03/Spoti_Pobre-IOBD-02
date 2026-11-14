# SpotiPobre - Trabalho 2

Evolução do sistema SpotiPobre (Interação Web / IOBD, IFRS). Aplicação web em Java com Javalin, Mustache, JDBC puro e PostgreSQL, usando o padrão DAO. Não há ORM e nenhuma rota contém SQL: todo o SQL está em `src/main/java/persistencia`.

## Requisitos do ambiente

- Java 21
- Maven 3.9 ou superior
- PostgreSQL 16 (o usuário `postgres` precisa poder criar bancos e papéis)

## Como executar (2 comandos)

Abra no terminal a pasta do projeto (a que contém `pom.xml` e `banco/`). A primeira execução do Maven baixa as dependências e exige internet.


```bash
psql -h localhost -U postgres -f banco/spoti_pobre_dump.sql
mvn compile exec:java
```

Depois, abra <http://localhost:7000>.

O primeiro comando pede a senha do usuário `postgres`. Ele apaga e recria o banco `spoti_pobre` e cria os papéis `spoti_admin` e `spoti_consulta`. Pode ser executado mais de uma vez. O arquivo `banco/spoti_pobre_dump.sql` contém tudo: estrutura, dados de teste e controle de acesso (DCL).

A aplicação conecta no banco `spoti_pobre` em `localhost:5432` como `spoti_admin` (senha de teste `senha_admin_teste`). Esses são os valores padrão, então não é preciso configurar nada. Se o PostgreSQL estiver em outra porta ou outro usuário for desejado, defina antes de iniciar:

| Variável | Padrão |
|---|---|
| `SPOTI_DB_HOST` | `localhost` |
| `SPOTI_DB_PORT` | `5432` |
| `SPOTI_DB_NAME` | `spoti_pobre` |
| `SPOTI_DB_USER` | `spoti_admin` |
| `SPOTI_DB_PASSWORD` | `senha_admin_teste` |

Também é possível executar a classe `apresentacao.Main` pela IDE.

## Roteiro de verificação por requisito

### Requisito 1: JSONB

Coluna `playlist.dados_extras` (JSONB) com índice GIN. Exemplo de conteúdo:

```json
{"descricao": "Os sambas que todo mundo canta junto", "tags": ["samba", "brasil", "classicos"], "clima": "animado", "destaque": true}
```

| O que verificar | Onde |
|---|---|
| Inserir JSON pela interface (descrição, tags, clima, destaque) | `/playlists/nova`, com pré-visualização do JSON |
| Atualizar o JSON | `/playlists/tela_alterar/{id}` e, no detalhe, o painel **Editar dados da playlist** |
| Editar campo a campo (`jsonb_set`, `\|\|`, `jsonb_agg`) ou o JSON completo, com validação | `/playlists/detalhe/4`, painel de edição (abas Campos e JSON completo) |
| Consultar e exibir o JSONB | `/playlists/detalhe/4` e `/playlists/tela_listagem` |
| Busca com operadores JSON (`@>` por tag, `->>` por clima e destaque) | `/playlists/busca`, que mostra a condição JSONB aplicada |

### Requisito 2: BYTEA

Coluna `album.capa` (BYTEA) mais `album.capa_tipo` e uma regra de integridade que exige o tipo da imagem junto com os bytes. O banco já traz 4 capas de teste.

| Operação | Onde |
|---|---|
| Inserir (upload) e atualizar (trocar) a capa | `/albuns` |
| Visualizar a capa, lida dos bytes do banco | `/albuns` e `/dashboard` (rota `GET /albuns/capa/{id}`) |
| Excluir só a capa, mantendo o álbum | `/albuns`, botão **Remover** |

O upload aceita PNG, JPEG, GIF e WEBP de até 2 MB e confere os primeiros bytes do arquivo. A gravação usa `PreparedStatement.setBytes` e a leitura usa `getBytes` (`AlbumDAO`).

### Requisito 3: Herança de tabelas

Tabela `album_coletanea` herda de `album` (`INHERITS`) e acrescenta `tema` e `ano_referencia`. Em Java, `AlbumColetanea extends Album`. Particularidades tratadas:

- `PRIMARY KEY` e `FOREIGN KEY` não são herdadas e foram refeitas na filha; `NOT NULL` e `CHECK` são herdados.
- A chave estrangeira de `album_musica` não enxerga linhas da tabela filha. Por isso as músicas das coletâneas ficam em `coletanea_musica`, que referencia `album_coletanea`.
- `SELECT FROM album` inclui as coletâneas e `FROM ONLY album` não inclui. A coluna `tableoid` mostra a tabela de origem de cada linha.

| Operação | Onde |
|---|---|
| Cadastrar coletânea | `/coletaneas/nova` |
| Consultar coletâneas (filtro por tema e ano) | `/coletaneas`, aba **Coletâneas** |
| Ver a diferença entre consultar o pai e só o pai | `/coletaneas`, abas **Tabela pai e filhas** (`FROM album`) e **Só a tabela pai** (`FROM ONLY album`) |

### Requisito 4: Aplicação web

Javalin (rotas nos pacotes `controller`), Mustache (`src/main/resources/templates`), JDBC e DAO (`persistencia`), na porta 7000. CRUD completo da entidade **playlist**:

| Operação | Rota |
|---|---|
| Listagem | `GET /playlists/tela_listagem` |
| Cadastro | `GET` e `POST /playlists/nova` |
| Consulta individual | `GET /playlists/detalhe/{id}` |
| Edição | `GET /playlists/tela_alterar/{id}` e `POST /playlists/alterar` |
| Remoção | `POST /playlists/excluir` |

Os demais requisitos estão integrados à mesma aplicação (telas acima). O catálogo (`/dashboard`), os usuários (`/usuarios`) e o registro de reproduções também funcionam.

### Requisito 5: DCL

Definido no próprio `banco/spoti_pobre_dump.sql` (comandos `GRANT` e `REVOKE` ao final do arquivo):

| Papel | Permissões |
|---|---|
| `spoti_admin` (usado pela aplicação) | `SELECT`, `INSERT`, `UPDATE`, `DELETE` em todas as tabelas do sistema, incluindo as tabelas filhas, e uso das sequences. Não é dono das tabelas, então não pode apagá-las. |
| `spoti_consulta` (somente leitura) | `SELECT` nas tabelas. Em `usuario` e `usuario_premium` enxerga apenas as colunas sem a senha. Sem `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE` e sem acesso às sequences. Não acessa o schema `backup`. |

Também há `REVOKE ALL ON DATABASE ... FROM PUBLIC`, para que só os dois papéis consigam conectar (além do superusuário).

**Teste com o usuário somente leitura** (senha `senha_consulta_teste`):

```bash
psql -h localhost -U spoti_consulta -d spoti_pobre
```

```sql
SELECT count(*) FROM album;                 -- funciona
SELECT nome, email FROM usuario LIMIT 3;    -- funciona
SELECT senha FROM usuario LIMIT 1;          -- ERROR: permission denied for table usuario
INSERT INTO playlist (nome) VALUES ('x');   -- ERROR: permission denied for table playlist
UPDATE album SET titulo = 'x';              -- ERROR: permission denied for table album
DELETE FROM album_coletanea;                -- ERROR: permission denied for table album_coletanea
```

**Teste com o usuário da aplicação** (senha `senha_admin_teste`):

```bash
psql -h localhost -U spoti_admin -d spoti_pobre
```

```sql
SELECT count(*) FROM playlist;   -- funciona
DROP TABLE album_musica;         -- ERROR: must be owner of table album_musica
```

## Credenciais de teste

Apenas para uso local. Não há senhas reais no projeto.

| Papel | Senha |
|---|---|
| `spoti_admin` | `senha_admin_teste` |
| `spoti_consulta` | `senha_consulta_teste` |

## Estrutura do projeto

```
banco/spoti_pobre_dump.sql   banco completo: estrutura, dados de teste e DCL
src/main/java/
  apresentacao/Main.java     inicia o Javalin (porta 7000) e registra as rotas
  controller/                rotas HTTP, sem SQL
  negocio/                   classes de domínio (Album, AlbumColetanea, Playlist, ...)
  persistencia/              DAOs e conexão JDBC (todo o SQL)
src/main/resources/
  public/app.css             estilos
  templates/                 páginas Mustache
```