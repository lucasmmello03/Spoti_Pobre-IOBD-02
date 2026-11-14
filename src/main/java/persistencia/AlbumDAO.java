package persistencia;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import negocio.Album;
import negocio.CapaAlbum;

public class AlbumDAO {

    private static final String SELECT_SEM_BYTES =
            "SELECT id, titulo, data_lancamento, " +
            "capa IS NOT NULL AS tem_capa, " +
            "COALESCE(octet_length(capa), 0) AS capa_tamanho " +
            "FROM album ";

    private Album mapear(ResultSet rs) throws SQLException {
        Album album = new Album();
        album.setId(rs.getInt("id"));
        album.setTitulo(rs.getString("titulo"));

        Date lancamento = rs.getDate("data_lancamento");
        if (lancamento != null) {
            album.setData_lancamento(lancamento.toLocalDate());
        }

        album.setTemCapa(rs.getBoolean("tem_capa"));
        album.setCapaTamanho(rs.getLong("capa_tamanho"));
        return album;
    }

    public List<Album> listar() {
        List<Album> albuns = new ArrayList<>();
        String sql = SELECT_SEM_BYTES + "ORDER BY titulo;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                albuns.add(mapear(rs));
            }
        } catch (SQLException e) {
            System.out.println("Erro ao listar albuns: " + e.getMessage());
        }
        return albuns;
    }

    public Album buscarPorId(int id) {
        String sql = SELECT_SEM_BYTES + "WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setInt(1, id);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return mapear(rs);
                }
            }
        } catch (SQLException e) {
            System.out.println("Erro ao buscar album: " + e.getMessage());
        }
        return null;
    }

    public boolean salvarCapa(int albumId, byte[] bytes, String tipo) {
        String sql = "UPDATE album SET capa = ?, capa_tipo = ? WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setBytes(1, bytes);
            stmt.setString(2, tipo);
            stmt.setInt(3, albumId);
            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            System.out.println("Erro ao salvar capa: " + e.getMessage());
            return false;
        }
    }

    public CapaAlbum obterCapa(int albumId) {
        String sql = "SELECT capa, capa_tipo FROM album WHERE id = ? AND capa IS NOT NULL;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setInt(1, albumId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return new CapaAlbum(rs.getBytes("capa"), rs.getString("capa_tipo"));
                }
            }
        } catch (SQLException e) {
            System.out.println("Erro ao obter capa: " + e.getMessage());
        }
        return null;
    }

    public boolean excluirCapa(int albumId) {
        String sql = "UPDATE album SET capa = NULL, capa_tipo = NULL WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setInt(1, albumId);
            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            System.out.println("Erro ao excluir capa: " + e.getMessage());
            return false;
        }
    }
}
