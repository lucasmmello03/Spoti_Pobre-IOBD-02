package persistencia;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;

import negocio.Usuario;

public class UsuarioDAO {

    public ArrayList<Usuario> listar() {
        ArrayList<Usuario> listaDeUsuarios = new ArrayList<>();
        String sql = "SELECT * FROM usuario ORDER BY id;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
             PreparedStatement instrucaoSQL = conexao.prepareStatement(sql);
             ResultSet rs = instrucaoSQL.executeQuery()) {

            while (rs.next()) {
                Usuario usuario = new Usuario();
                usuario.setId(rs.getInt("id"));
                usuario.setDataNascimento(
                        (rs.getDate("data_nascimento") != null) ? rs.getDate("data_nascimento").toLocalDate() : null);
                usuario.setEmail(rs.getString("email"));
                usuario.setNome(rs.getString("nome"));
                listaDeUsuarios.add(usuario);
            }
        } catch (SQLException e) {
            System.out.println("Erro ao listar usuários: " + e.getMessage());
        }
        return listaDeUsuarios;
    }


    public ArrayList<Usuario> listarComuns() {
        ArrayList<Usuario> listaDeUsuarios = new ArrayList<>();
        String sql = "SELECT * FROM ONLY usuario ORDER BY id;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
             PreparedStatement instrucaoSQL = conexao.prepareStatement(sql);
             ResultSet rs = instrucaoSQL.executeQuery()) {

            while (rs.next()) {
                Usuario usuario = new Usuario();
                usuario.setId(rs.getInt("id"));
                usuario.setDataNascimento(
                        (rs.getDate("data_nascimento") != null) ? rs.getDate("data_nascimento").toLocalDate() : null);
                usuario.setEmail(rs.getString("email"));
                usuario.setNome(rs.getString("nome"));
                listaDeUsuarios.add(usuario);
            }
        } catch (SQLException e) {
            System.out.println("Erro ao listar usuários: " + e.getMessage());
        }
        return listaDeUsuarios;
    }

    public Usuario obter(int id) {
        String sql = "SELECT * FROM usuario WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
             PreparedStatement instrucaoSQL = conexao.prepareStatement(sql)) {

            instrucaoSQL.setInt(1, id);
            try (ResultSet rs = instrucaoSQL.executeQuery()) {
                if (rs.next()) {
                    Usuario usuario = new Usuario();
                    usuario.setId(rs.getInt("id"));
                    usuario.setDataNascimento(
                            (rs.getDate("data_nascimento") != null) ? rs.getDate("data_nascimento").toLocalDate() : null);
                    usuario.setEmail(rs.getString("email"));
                    usuario.setNome(rs.getString("nome"));
                    usuario.setSenha(rs.getString("senha"));
                    return usuario;
                }
            }
        } catch (SQLException e) {
            System.out.println("Erro ao buscar usuário: " + e.getMessage());
        }
        return null;
    }

    public boolean salvar(Usuario usuario) {
        String sql = "INSERT INTO usuario (email, senha, nome, data_nascimento) VALUES (?, md5(?), ?, ?);";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
             PreparedStatement instrucaoSQL = conexao.prepareStatement(sql)) {

            instrucaoSQL.setString(1, usuario.getEmail());
            instrucaoSQL.setString(2, usuario.getSenha());
            instrucaoSQL.setString(3, usuario.getNome());

            if (usuario.getDataNascimento() != null) {
                instrucaoSQL.setDate(4, Date.valueOf(usuario.getDataNascimento()));
            } else {
                instrucaoSQL.setNull(4, Types.DATE);
            }

            instrucaoSQL.executeUpdate();
            return true;

        } catch (SQLException e) {
            System.out.println("Erro ao salvar usuário: " + e.getMessage());
            return false;
        }
    }

    public boolean deletar(int id) {
        String sql1 = "DELETE FROM reproducao WHERE usuario_id = ?;";
        String sql2 = "DELETE FROM usuario_playlist WHERE usuario_id = ?;";
        String sql3 = "DELETE FROM usuario WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao()) {
            conexao.setAutoCommit(false);

            try (PreparedStatement s1 = conexao.prepareStatement(sql1);
                 PreparedStatement s2 = conexao.prepareStatement(sql2);
                 PreparedStatement s3 = conexao.prepareStatement(sql3)) {

                s1.setInt(1, id);
                s1.executeUpdate();

                s2.setInt(1, id);
                s2.executeUpdate();

                s3.setInt(1, id);
                int linhasAfetadas = s3.executeUpdate();

                conexao.commit();
                return linhasAfetadas > 0;

            } catch (SQLException e) {
                conexao.rollback();
                System.out.println("Erro ao excluir usuário: " + e.getMessage());
                return false;
            }

        } catch (SQLException e) {
            System.out.println("Erro de conexão ao excluir usuário: " + e.getMessage());
            return false;
        }
    }

    public boolean atualizar(Usuario usuario) {
        String sql = "UPDATE usuario SET email = ?, "
                + ((usuario.getSenha() == null) ? "" : "senha = md5(?), ")
                + "nome = ?, data_nascimento = ? WHERE id = ?;";

        try (Connection conexao = new ConexaoPostgreSQL().getConexao();
             PreparedStatement instrucaoSQL = conexao.prepareStatement(sql)) {

            int index = 1;
            instrucaoSQL.setString(index++, usuario.getEmail());

            if (usuario.getSenha() != null) {
                instrucaoSQL.setString(index++, usuario.getSenha());
            }

            instrucaoSQL.setString(index++, usuario.getNome());

            if (usuario.getDataNascimento() != null) {
                instrucaoSQL.setDate(index++, Date.valueOf(usuario.getDataNascimento()));
            } else {
                instrucaoSQL.setNull(index++, Types.DATE);
            }

            instrucaoSQL.setInt(index, usuario.getId());
            instrucaoSQL.executeUpdate();

            return true;

        } catch (SQLException e) {
            System.out.println("Erro ao atualizar usuário: " + e.getMessage());
            return false;
        }
    }
}