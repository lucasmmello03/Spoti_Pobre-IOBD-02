package persistencia;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import negocio.Musica;
import negocio.Playlist;

public class PlaylistDAO {

    private static final String JSON_EXTRAS =
            "jsonb_build_object('descricao', ?::text, " +
            "'tags', to_jsonb(ARRAY(SELECT lower(btrim(t)) FROM unnest(string_to_array(?::text, ',')) AS t WHERE btrim(t) <> '')), " +
            "'clima', ?::text, 'destaque', ?::boolean)";

    // Lista de tags do JSON; se o campo nao for uma lista, trata como vazia.
    private static final String TAGS_ATUAIS =
            "(CASE WHEN jsonb_typeof(dados_extras->'tags') = 'array' THEN dados_extras->'tags' ELSE '[]'::jsonb END)";

    private static final String SELECT_COM_EXTRAS =
            "SELECT p.id, p.nome, p.publica, p.data_hora_criacao, u.nome AS dono_nome, " +
            "p.dados_extras->>'descricao' AS descricao, " +
            "p.dados_extras->>'clima' AS clima, " +
            "COALESCE(CASE WHEN jsonb_typeof(p.dados_extras->'destaque') = 'boolean' " +
            "THEN (p.dados_extras->>'destaque')::boolean END, false) AS destaque, " +
            "(SELECT string_agg(t, ', ') FROM jsonb_array_elements_text(" +
            "CASE WHEN jsonb_typeof(p.dados_extras->'tags') = 'array' THEN p.dados_extras->'tags' ELSE '[]'::jsonb END) AS t) AS tags, " +
            "jsonb_pretty(p.dados_extras) AS dados_json " +
            "FROM playlist p " +
            "LEFT JOIN usuario_playlist up ON p.id = up.playlist_id AND up.dono = true " +
            "LEFT JOIN usuario u ON up.usuario_id = u.id ";

    private String limpar(String s) {
        return s == null ? "" : s.trim();
    }

    private void definirExtras(PreparedStatement stmt, int inicio, Playlist p) throws SQLException {
        stmt.setString(inicio, limpar(p.getDescricao()));
        stmt.setString(inicio + 1, limpar(p.getTags()));
        stmt.setString(inicio + 2, limpar(p.getClima()).toLowerCase());
        stmt.setBoolean(inicio + 3, p.isDestaque());
    }

    private Playlist mapear(ResultSet rs) throws SQLException {
        Playlist p = new Playlist();
        p.setId(rs.getInt("id"));
        p.setNome(rs.getString("nome"));
        p.setPublica(rs.getBoolean("publica"));
        p.setDono_nome(rs.getString("dono_nome"));

        java.sql.Timestamp criacao = rs.getTimestamp("data_hora_criacao");
        if (criacao != null) {
            p.setDataHoraCriacao(criacao.toLocalDateTime());
        }

        p.setDescricao(rs.getString("descricao"));
        p.setClima(rs.getString("clima"));
        p.setDestaque(rs.getBoolean("destaque"));
        p.setTags(rs.getString("tags"));
        p.setDadosJson(rs.getString("dados_json"));
        return p;
    }

    public boolean salvarComDono(Playlist playlist, int usuarioId) {
        String sqlPlaylist = "INSERT INTO playlist (nome, publica, dados_extras) VALUES (?, ?, " + JSON_EXTRAS
                + ") RETURNING id;";
        String sqlVinculo = "INSERT INTO usuario_playlist (usuario_id, playlist_id, dono) VALUES (?, ?, true);";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao()) {
            conexao.setAutoCommit(false);

            try (PreparedStatement stmtPlaylist = conexao.prepareStatement(sqlPlaylist);
                    PreparedStatement stmtVinculo = conexao.prepareStatement(sqlVinculo)) {

                stmtPlaylist.setString(1, playlist.getNome());
                stmtPlaylist.setBoolean(2, playlist.isPublica());
                definirExtras(stmtPlaylist, 3, playlist);

                ResultSet rs = stmtPlaylist.executeQuery();

                if (rs.next()) {
                    int novaPlaylistId = rs.getInt("id");

                    stmtVinculo.setInt(1, usuarioId);
                    stmtVinculo.setInt(2, novaPlaylistId);
                    stmtVinculo.executeUpdate();
                }

                conexao.commit();
                return true;

            } catch (SQLException e) {
                conexao.rollback();
                System.out.println("Erro ao salvar playlist e vínculo: " + e.getMessage());
                return false;
            }

        } catch (SQLException e) {
            System.out.println("Erro de conexão na transação da playlist: " + e.getMessage());
            return false;
        }
    }

    public List<Playlist> listarTodas() {
        List<Playlist> playlists = new ArrayList<>();
        String sql = SELECT_COM_EXTRAS + "ORDER BY p.nome;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                playlists.add(mapear(rs));
            }
        } catch (SQLException e) {
            System.out.println("Erro ao listar playlists: " + e.getMessage());
        }
        return playlists;
    }

    public Playlist buscarPorId(int id) {
        Playlist playlist = null;
        String sql = SELECT_COM_EXTRAS + "WHERE p.id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    playlist = mapear(rs);
                }
            }
        } catch (SQLException e) {
            System.out.println("Erro ao buscar playlist: " + e.getMessage());
        }
        return playlist;
    }

    public List<Musica> listarMusicas(int playlistId) {
        List<Musica> musicas = new ArrayList<>();
        String sql = "SELECT m.id, m.nome, m.duracao " +
                "FROM playlist_musica pm " +
                "INNER JOIN musica m ON m.id = pm.musica_id " +
                "WHERE pm.playlist_id = ? " +
                "ORDER BY m.nome;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setInt(1, playlistId);
            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Musica m = new Musica();
                    m.setId(rs.getInt("id"));
                    m.setNome(rs.getString("nome"));
                    m.setDuracao(rs.getTime("duracao"));
                    musicas.add(m);
                }
            }
        } catch (SQLException e) {
            System.out.println("Erro ao listar músicas da playlist: " + e.getMessage());
        }
        return musicas;
    }

    public List<Playlist> buscarPorExtras(String tag, String clima, boolean apenasDestaque) {
        List<Playlist> playlists = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_COM_EXTRAS + "WHERE 1 = 1");
        List<String> parametros = new ArrayList<>();

        if (tag != null && !tag.isBlank()) {
            sql.append(" AND p.dados_extras @> jsonb_build_object('tags', jsonb_build_array(?::text))");
            parametros.add(tag.trim().toLowerCase());
        }
        if (clima != null && !clima.isBlank()) {
            sql.append(" AND p.dados_extras->>'clima' = ?");
            parametros.add(clima.trim().toLowerCase());
        }
        if (apenasDestaque) {
            sql.append(" AND p.dados_extras->>'destaque' = 'true'");
        }
        sql.append(" ORDER BY p.nome;");

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql.toString())) {

            for (int i = 0; i < parametros.size(); i++) {
                stmt.setString(i + 1, parametros.get(i));
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    playlists.add(mapear(rs));
                }
            }
        } catch (SQLException e) {
            System.out.println("Erro ao buscar playlists por extras: " + e.getMessage());
        }
        return playlists;
    }

    // Texto exibido na tela de busca para mostrar qual condicao JSONB esta sendo aplicada.
    public String descreverBusca(String tag, String clima, boolean apenasDestaque) {
        List<String> condicoes = new ArrayList<>();

        if (tag != null && !tag.isBlank()) {
            condicoes.add("dados_extras @> '{\"tags\": [\"" + tag.trim().toLowerCase() + "\"]}'");
        }
        if (clima != null && !clima.isBlank()) {
            condicoes.add("dados_extras->>'clima' = '" + clima.trim().toLowerCase() + "'");
        }
        if (apenasDestaque) {
            condicoes.add("dados_extras->>'destaque' = 'true'");
        }

        if (condicoes.isEmpty()) {
            return "Sem filtros: todas as playlists, sem condição JSONB.";
        }
        return "WHERE " + String.join("\n  AND ", condicoes);
    }

    public List<String> listarTags() {
        List<String> tags = new ArrayList<>();
        String sql = "SELECT DISTINCT jsonb_array_elements_text(dados_extras->'tags') AS tag " +
                "FROM playlist WHERE jsonb_typeof(dados_extras->'tags') = 'array' ORDER BY tag;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                tags.add(rs.getString("tag"));
            }
        } catch (SQLException e) {
            System.out.println("Erro ao listar tags: " + e.getMessage());
        }
        return tags;
    }

    public List<String> listarClimas() {
        List<String> climas = new ArrayList<>();
        String sql = "SELECT DISTINCT dados_extras->>'clima' AS clima FROM playlist " +
                "WHERE dados_extras->>'clima' IS NOT NULL AND dados_extras->>'clima' <> '' " +
                "ORDER BY clima;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                climas.add(rs.getString("clima"));
            }
        } catch (SQLException e) {
            System.out.println("Erro ao listar climas: " + e.getMessage());
        }
        return climas;
    }

    public boolean alterar(Playlist playlist) {
        String sql = "UPDATE playlist SET nome = ?, publica = ?, " +
                "dados_extras = COALESCE(dados_extras, '{}'::jsonb) || " + JSON_EXTRAS + " WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, playlist.getNome());
            stmt.setBoolean(2, playlist.isPublica());
            definirExtras(stmt, 3, playlist);
            stmt.setInt(7, playlist.getId());

            int linhasAfetadas = stmt.executeUpdate();
            return linhasAfetadas > 0;

        } catch (SQLException e) {
            System.out.println("Erro ao alterar playlist: " + e.getMessage());
            return false;
        }
    }

    // ---- Edicao direta do JSONB pela tela de detalhe ----

    // jsonb_set troca apenas a chave 'destaque', sem mexer nas demais.
    public boolean alternarDestaque(int id) {
        String sql = "UPDATE playlist SET dados_extras = jsonb_set(dados_extras, '{destaque}', " +
                "to_jsonb(NOT COALESCE(CASE WHEN jsonb_typeof(dados_extras->'destaque') = 'boolean' " +
                "THEN (dados_extras->>'destaque')::boolean END, false)), true) WHERE id = ?;";
        return executarAtualizacao(sql, null, id, "alternar destaque");
    }

    // jsonb_set troca apenas a chave 'clima'.
    public boolean definirClima(int id, String clima) {
        String sql = "UPDATE playlist SET dados_extras = jsonb_set(dados_extras, '{clima}', to_jsonb(?::text), true) " +
                "WHERE id = ?;";
        return executarAtualizacao(sql, limpar(clima).toLowerCase(), id, "definir clima");
    }

    // Acrescenta a tag na lista (com ||) se ela ainda nao existir (teste com @>).
    public boolean adicionarTag(int id, String tag) {
        String nova = limpar(tag).toLowerCase();
        if (nova.isEmpty()) {
            return false;
        }
        String sql = "UPDATE playlist SET dados_extras = jsonb_set(dados_extras, '{tags}', " +
                "CASE WHEN " + TAGS_ATUAIS + " @> jsonb_build_array(?::text) THEN " + TAGS_ATUAIS +
                " ELSE " + TAGS_ATUAIS + " || jsonb_build_array(?::text) END, true) WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, nova);
            stmt.setString(2, nova);
            stmt.setInt(3, id);
            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            System.out.println("Erro ao adicionar tag: " + e.getMessage());
            return false;
        }
    }

    // Reconstroi a lista de tags sem o valor removido (jsonb_array_elements + jsonb_agg).
    public boolean removerTag(int id, String tag) {
        String sql = "UPDATE playlist SET dados_extras = jsonb_set(dados_extras, '{tags}', " +
                "COALESCE((SELECT jsonb_agg(t) FROM jsonb_array_elements(" + TAGS_ATUAIS + ") AS t " +
                "WHERE t <> to_jsonb(?::text)), '[]'::jsonb), true) WHERE id = ?;";
        return executarAtualizacao(sql, limpar(tag).toLowerCase(), id, "remover tag");
    }

    // Substitui o JSON inteiro. Retorna null se salvou, ou a mensagem de erro para mostrar na tela.
    public String salvarJsonBruto(int id, String json) {
        String sqlValidar = "SELECT CASE " +
                "WHEN jsonb_typeof(j) <> 'object' THEN 'O JSON precisa ser um objeto, entre chaves { }.' " +
                "WHEN j->'tags' IS NOT NULL AND jsonb_typeof(j->'tags') <> 'array' " +
                "THEN 'O campo \"tags\" deve ser uma lista. Ex: [\"mpb\", \"rock\"].' " +
                "WHEN j->'destaque' IS NOT NULL AND jsonb_typeof(j->'destaque') <> 'boolean' " +
                "THEN 'O campo \"destaque\" deve ser true ou false.' " +
                "WHEN j->'clima' IS NOT NULL AND jsonb_typeof(j->'clima') <> 'string' " +
                "THEN 'O campo \"clima\" deve ser um texto.' " +
                "WHEN j->'descricao' IS NOT NULL AND jsonb_typeof(j->'descricao') <> 'string' " +
                "THEN 'O campo \"descricao\" deve ser um texto.' " +
                "END AS erro FROM (SELECT ?::jsonb AS j) AS x;";
        String sqlSalvar = "UPDATE playlist SET dados_extras = ?::jsonb WHERE id = ?;";

        String texto = limpar(json);
        if (texto.isEmpty()) {
            return "O JSON não pode ficar vazio.";
        }

        try (Connection conexao = new ConexaoPostgreSQL().getConexao()) {

            try (PreparedStatement stmtValidar = conexao.prepareStatement(sqlValidar)) {
                stmtValidar.setString(1, texto);
                try (ResultSet rs = stmtValidar.executeQuery()) {
                    if (rs.next() && rs.getString("erro") != null) {
                        return rs.getString("erro");
                    }
                }
            }

            try (PreparedStatement stmtSalvar = conexao.prepareStatement(sqlSalvar)) {
                stmtSalvar.setString(1, texto);
                stmtSalvar.setInt(2, id);
                if (stmtSalvar.executeUpdate() == 0) {
                    return "Playlist não encontrada.";
                }
            }
            return null;

        } catch (SQLException e) {
            System.out.println("Erro ao salvar JSON da playlist: " + e.getMessage());
            if ("22P02".equals(e.getSQLState())) {
                String detalhe = e.getMessage() == null ? "" : e.getMessage().replace('\n', ' ');
                return "JSON inválido. Confira aspas, vírgulas e chaves. (" + detalhe + ")";
            }
            return "Não foi possível salvar o JSON.";
        }
    }

    private boolean executarAtualizacao(String sql, String texto, int id, String operacao) {
        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            int posicao = 1;
            if (texto != null) {
                stmt.setString(posicao++, texto);
            }
            stmt.setInt(posicao, id);
            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            System.out.println("Erro ao " + operacao + ": " + e.getMessage());
            return false;
        }
    }

    public boolean excluir(int id) {
        String sqlUsuarioPlaylist = "DELETE FROM usuario_playlist WHERE playlist_id = ?;";
        String sqlPlaylistMusica = "DELETE FROM playlist_musica WHERE playlist_id = ?;";
        String sqlPlaylist = "DELETE FROM playlist WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao()) {
            conexao.setAutoCommit(false);

            try (PreparedStatement stmtVinculo = conexao.prepareStatement(sqlUsuarioPlaylist);
                    PreparedStatement stmtMusicas = conexao.prepareStatement(sqlPlaylistMusica);
                    PreparedStatement stmtPlaylist = conexao.prepareStatement(sqlPlaylist)) {

                stmtVinculo.setInt(1, id);
                stmtVinculo.executeUpdate();

                stmtMusicas.setInt(1, id);
                stmtMusicas.executeUpdate();

                stmtPlaylist.setInt(1, id);
                int linhasAfetadas = stmtPlaylist.executeUpdate();

                conexao.commit();
                return linhasAfetadas > 0;

            } catch (SQLException e) {
                conexao.rollback();
                System.out.println("Erro ao excluir playlist: " + e.getMessage());
                return false;
            }

        } catch (SQLException e) {
            System.out.println("Erro de conexão ao excluir playlist: " + e.getMessage());
            return false;
        }
    }
}