package persistencia;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConexaoPostgreSQL {

    private String valor(String variavel, String padrao) {
        String v = System.getenv(variavel);
        return (v == null || v.isBlank()) ? padrao : v;
    }

    public Connection getConexao() throws SQLException {
        String host = valor("SPOTI_DB_HOST", "localhost");
        String port = valor("SPOTI_DB_PORT", "5432");
        String dbname = valor("SPOTI_DB_NAME", "spoti_pobre");
        String username = valor("SPOTI_DB_USER", "spoti_admin");
        String password = valor("SPOTI_DB_PASSWORD", "senha_admin_teste");

        String url = "jdbc:postgresql://" + host + ":" + port + "/" + dbname;
        return DriverManager.getConnection(url, username, password);
    }
}
