package persistencia;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import negocio.Album;
import negocio.Musica;

public class DashboardDAO {

    public List<Album> listarCatalogo() {
        Map<Integer, Album> mapaAlbuns = new LinkedHashMap<>();

        String sql = "SELECT a.id AS album_id, a.titulo, a.data_lancamento, a.capa IS NOT NULL AS tem_capa, " +
                     "m.id AS musica_id, m.nome, m.duracao " +
                     "FROM album a " +
                     "JOIN album_musica am ON a.id = am.album_id " +
                     "JOIN musica m ON am.musica_id = m.id " +
                     "ORDER BY a.titulo, m.nome;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
             PreparedStatement stmt = conexao.prepareStatement(sql);
             ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                int albumId = rs.getInt("album_id");

                if (!mapaAlbuns.containsKey(albumId)) {
                    Album album = new Album();
                    album.setId(albumId);
                    album.setTitulo(rs.getString("titulo"));
                    album.setTemCapa(rs.getBoolean("tem_capa"));
                    
                    if (rs.getDate("data_lancamento") != null) {
                        album.setData_lancamento(rs.getDate("data_lancamento").toLocalDate());
                    }
                    mapaAlbuns.put(albumId, album);
                }

                Musica musica = new Musica();
                musica.setId(rs.getInt("musica_id"));
                musica.setNome(rs.getString("nome"));
                musica.setDuracao(rs.getTime("duracao"));

                mapaAlbuns.get(albumId).getMusicas().add(musica);
            }

        } catch (SQLException e) {
            System.out.println("Erro ao carregar o Dashboard: " + e.getMessage());
        }

        return new ArrayList<>(mapaAlbuns.values());
    }
}