package controller;

import io.javalin.Javalin;
import persistencia.DashboardDAO;
import persistencia.MusicaDAO;
import persistencia.UsuarioDAO;
import java.util.HashMap;
import java.util.Map;

public class DashboardController {

    private DashboardDAO dao = new DashboardDAO();
    private MusicaDAO musicaDAO = new MusicaDAO();
    private UsuarioDAO usuarioDAO = new UsuarioDAO();

    public DashboardController(Javalin app) {

        app.get("/dashboard", ctx -> {
            Map<String, Object> map = new HashMap<>();
            map.put("albuns", dao.listarCatalogo());
            map.put("usuarios", usuarioDAO.listarComuns());
            map.put("ouvida", ctx.queryParam("ok") != null);
            ctx.render("/templates/dashboard.html", map);
        });

        app.post("/reproduzir", ctx -> {
            int musicaId = Integer.parseInt(ctx.formParam("musica_id"));
            int usuarioId = Integer.parseInt(ctx.formParam("usuario_id"));

            boolean resultado = musicaDAO.registrarReproducao(musicaId, usuarioId);

            if (resultado) {
                ctx.redirect("/dashboard?ok=1#musica-" + musicaId);
            } else {
                ctx.html("Erro ao registrar reprodução.");
            }
        });
    }
}