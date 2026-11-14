package persistencia;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

import negocio.Album;
import negocio.AlbumColetanea;
import negocio.Genero;

public class ColetaneaDAO {

    public boolean salvar(AlbumColetanea c) {
        String sql = "INSERT INTO album_coletanea (titulo, data_lancamento, genero_id, tema, ano_referencia) " +
                "VALUES (?, ?, ?, ?, ?);";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql)) {

            stmt.setString(1, c.getTitulo());
            if (c.getData_lancamento() != null) {
                stmt.setDate(2, Date.valueOf(c.getData_lancamento()));
            } else {
                stmt.setNull(2, Types.DATE);
            }
            if (c.getGenero_id() > 0) {
                stmt.setInt(3, c.getGenero_id());
            } else {
                stmt.setNull(3, Types.INTEGER);
            }
            stmt.setString(4, c.getTema());
            stmt.setInt(5, c.getAnoReferencia());
            return stmt.executeUpdate() > 0;

        } catch (SQLException e) {
            System.out.println("Erro ao salvar coletanea: " + e.getMessage());
            return false;
        }
    }

    public List<AlbumColetanea> consultar(String tema, Integer ano) {
        List<AlbumColetanea> lista = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT c.id, c.titulo, c.data_lancamento, c.tema, c.ano_referencia, g.nome AS genero_nome, " +
                "(SELECT count(*) FROM coletanea_musica cm WHERE cm.coletanea_id = c.id) AS total_musicas " +
                "FROM album_coletanea c LEFT JOIN genero g ON g.id = c.genero_id WHERE 1 = 1");

        if (tema != null && !tema.isBlank()) {
            sql.append(" AND c.tema ILIKE ?");
        }
        if (ano != null) {
            sql.append(" AND c.ano_referencia = ?");
        }
        sql.append(" ORDER BY c.titulo;");

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql.toString())) {

            int posicao = 1;
            if (tema != null && !tema.isBlank()) {
                stmt.setString(posicao++, "%" + tema.trim() + "%");
            }
            if (ano != null) {
                stmt.setInt(posicao, ano);
            }

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    AlbumColetanea c = new AlbumColetanea();
                    c.setId(rs.getInt("id"));
                    c.setTitulo(rs.getString("titulo"));
                    Date lancamento = rs.getDate("data_lancamento");
                    if (lancamento != null) {
                        c.setData_lancamento(lancamento.toLocalDate());
                    }
                    c.setTema(rs.getString("tema"));
                    c.setAnoReferencia(rs.getInt("ano_referencia"));
                    c.setGeneroNome(rs.getString("genero_nome"));
                    c.setTotalMusicas(rs.getInt("total_musicas"));
                    lista.add(c);
                }
            }
        } catch (SQLException e) {
            System.out.println("Erro ao consultar coletaneas: " + e.getMessage());
        }
        return lista;
    }

    public List<Album> listarAlbunsComFilhas() {
        return listarAlbuns("SELECT a.id, a.titulo, a.tableoid::regclass::text AS origem FROM album a ORDER BY a.titulo;");
    }

    public List<Album> listarSomenteAlbuns() {
        return listarAlbuns("SELECT a.id, a.titulo, a.tableoid::regclass::text AS origem FROM ONLY album a ORDER BY a.titulo;");
    }

    private List<Album> listarAlbuns(String sql) {
        List<Album> albuns = new ArrayList<>();

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Album a = new Album();
                a.setId(rs.getInt("id"));
                a.setTitulo(rs.getString("titulo"));
                a.setOrigem(rs.getString("origem"));
                albuns.add(a);
            }
        } catch (SQLException e) {
            System.out.println("Erro ao listar albuns: " + e.getMessage());
        }
        return albuns;
    }

    public int contarComFilhas() {
        return contar("SELECT count(*) FROM album;");
    }

    public int contarSomenteAlbuns() {
        return contar("SELECT count(*) FROM ONLY album;");
    }

    public int contarColetaneas() {
        return contar("SELECT count(*) FROM album_coletanea;");
    }

    private int contar(String sql) {
        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.out.println("Erro ao contar albuns: " + e.getMessage());
        }
        return 0;
    }

    public List<Genero> listarGeneros() {
        List<Genero> generos = new ArrayList<>();
        String sql = "SELECT id, nome FROM genero ORDER BY nome;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
                PreparedStatement stmt = conexao.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Genero g = new Genero();
                g.setId(rs.getInt("id"));
                g.setNome(rs.getString("nome"));
                generos.add(g);
            }
        } catch (SQLException e) {
            System.out.println("Erro ao listar generos: " + e.getMessage());
        }
        return generos;
    }
}
