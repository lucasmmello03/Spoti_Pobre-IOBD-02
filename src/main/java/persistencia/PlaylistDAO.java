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

    private static final String SELECT_COM_EXTRAS =
            "SELECT p.id, p.nome, p.publica, p.data_hora_criacao, u.nome AS dono_nome, " +
            "p.dados_extras->>'descricao' AS descricao, " +
            "p.dados_extras->>'clima' AS clima, " +
            "COALESCE((p.dados_extras->>'destaque')::boolean, false) AS destaque, " +
            "(SELECT string_agg(t, ', ') FROM jsonb_array_elements_text(p.dados_extras->'tags') AS t) AS tags, " +
            "p.dados_extras::text AS dados_json " +
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
        String sql = "SELECT p.id, p.nome, p.publica, u.nome AS dono_nome " +
                "FROM playlist p " +
                "LEFT JOIN usuario_playlist up ON p.id = up.playlist_id AND up.dono = true " +
                "LEFT JOIN usuario u ON up.usuario_id = u.id " +
                "ORDER BY p.nome;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Playlist p = new Playlist();
                p.setId(rs.getInt("id"));
                p.setNome(rs.getString("nome"));
                p.setPublica(rs.getBoolean("publica"));
                p.setDono_nome(rs.getString("dono_nome"));
                playlists.add(p);
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

    public List<String> listarTags() {
        List<String> tags = new ArrayList<>();
        String sql = "SELECT DISTINCT jsonb_array_elements_text(dados_extras->'tags') AS tag " +
                "FROM playlist ORDER BY tag;";

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