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

    public boolean salvarComDono(Playlist playlist, int usuarioId) {
        String sqlPlaylist = "INSERT INTO playlist (nome, publica) VALUES (?, ?) RETURNING id;";
        String sqlVinculo = "INSERT INTO usuario_playlist (usuario_id, playlist_id, dono) VALUES (?, ?, true);";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao()) {
            conexao.setAutoCommit(false);

            try (PreparedStatement stmtPlaylist = conexao.prepareStatement(sqlPlaylist);
                    PreparedStatement stmtVinculo = conexao.prepareStatement(sqlVinculo)) {

                stmtPlaylist.setString(1, playlist.getNome());
                stmtPlaylist.setBoolean(2, playlist.isPublica());

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
        String sql = "SELECT p.id, p.nome, p.publica, p.data_hora_criacao, u.nome AS dono_nome " +
                "FROM playlist p " +
                "LEFT JOIN usuario_playlist up ON p.id = up.playlist_id AND up.dono = true " +
                "LEFT JOIN usuario u ON up.usuario_id = u.id " +
                "WHERE p.id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    playlist = new Playlist();
                    playlist.setId(rs.getInt("id"));
                    playlist.setNome(rs.getString("nome"));
                    playlist.setPublica(rs.getBoolean("publica"));
                    playlist.setDono_nome(rs.getString("dono_nome"));

                    java.sql.Timestamp criacao = rs.getTimestamp("data_hora_criacao");
                    if (criacao != null) {
                        playlist.setDataHoraCriacao(criacao.toLocalDateTime());
                    }
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

    public boolean alterar(Playlist playlist) {
        String sql = "UPDATE playlist SET nome = ?, publica = ? WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, playlist.getNome());
            stmt.setBoolean(2, playlist.isPublica());
            stmt.setInt(3, playlist.getId());

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