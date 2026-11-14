package apresentacao;

import java.sql.SQLException;

import controller.AlbumController;
import controller.ColetaneaController;
import controller.DashboardController;
import controller.PlaylistController;
import controller.UsuarioController;
import io.javalin.Javalin;
import io.javalin.http.staticfiles.Location;
import io.javalin.rendering.template.JavalinMustache;

public class Main {
    public static void main(String[] args) throws SQLException {

        //Rota principal
        Javalin app = Javalin.create(config -> {
            config.fileRenderer(new JavalinMustache());
            config.staticFiles.add("/public", Location.CLASSPATH);
        }).start(7000);

        app.exception(Exception.class, (e, ctx) -> {
            System.out.println("Erro não tratado em " + ctx.method() + " " + ctx.path() + ": " + e);
            e.printStackTrace();
            ctx.status(500);
            ctx.html("<h1>Ocorreu um erro</h1><p>" + e.getClass().getSimpleName()
                    + (e.getMessage() != null ? ": " + e.getMessage() : "")
                    + "</p><p><a href=\"/\">Voltar ao início</a></p>");
        });

        app.get("/", ctx -> ctx.render("/templates/home.html"));

        //Rotas de usuario
        new UsuarioController(app);

        //Rotas de playlist
        new PlaylistController(app);

        //Rota de dashboard
        new DashboardController(app);

        //Rotas de capas de album (BYTEA)
        new AlbumController(app);

        //Rotas de coletaneas (heranca de tabelas)
        new ColetaneaController(app);

    }
}