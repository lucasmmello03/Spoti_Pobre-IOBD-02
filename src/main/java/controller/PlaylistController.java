package controller;

import io.javalin.Javalin;
import negocio.Playlist;
import persistencia.PlaylistDAO;
import persistencia.UsuarioDAO;
import java.util.HashMap;
import java.util.Map;

public class PlaylistController {

    private PlaylistDAO playlistDAO = new PlaylistDAO();
    private UsuarioDAO usuarioDAO = new UsuarioDAO();

    public PlaylistController(Javalin app) {

        app.get("/playlists/tela_listagem", ctx -> {
            Map<String, Object> map = new HashMap<>();
            map.put("playlists", playlistDAO.listarTodas());
            ctx.render("/templates/playlists/tela_listagem.html", map);
        });

        app.get("/playlists/nova", ctx -> {
            Map<String, Object> map = new HashMap<>();
            map.put("usuarios", usuarioDAO.listarComuns());
            ctx.render("/templates/playlists/tela_adicionar.html", map);
        });

        app.post("/playlists/nova", ctx -> {
            String nome = ctx.formParam("nome");
            boolean publica = ctx.formParam("publica") != null;
            int usuarioId = Integer.parseInt(ctx.formParam("usuario_id"));

            Playlist novaPlaylist = new Playlist();
            novaPlaylist.setNome(nome);
            novaPlaylist.setPublica(publica);

            boolean resultado = playlistDAO.salvarComDono(novaPlaylist, usuarioId);

            if (resultado) {
                ctx.redirect("/playlists/tela_listagem");
            } else {
                ctx.html("Erro ao criar playlist.");
            }
        });

        app.get("/playlists/detalhe/{id}", ctx -> {

            int id;
            try {
                id = Integer.parseInt(ctx.pathParam("id"));
            } catch (NumberFormatException e) {
                ctx.redirect("/playlists/tela_listagem");
                return;
            }

            Playlist playlist = playlistDAO.buscarPorId(id);

            if (playlist == null) {
                ctx.redirect("/playlists/tela_listagem");
                return;
            }

            Map<String, Object> map = new HashMap<>();
            map.put("playlist", playlist);
            map.put("musicas", playlistDAO.listarMusicas(id));
            ctx.render("/templates/playlists/detalhe.html", map);
        });

        app.get("/playlists/tela_alterar/{id}", ctx -> {
            int id = Integer.parseInt(ctx.pathParam("id"));
            Playlist playlist = playlistDAO.buscarPorId(id);

            if (playlist == null) {
                ctx.redirect("/playlists/tela_listagem");
                return;
            }

            Map<String, Object> map = new HashMap<>();
            map.put("playlist", playlist);
            ctx.render("/templates/playlists/tela_alterar.html", map);
        });

        app.post("/playlists/alterar", ctx -> {
            Playlist playlist = new Playlist();
            playlist.setId(Integer.parseInt(ctx.formParam("id")));
            playlist.setNome(ctx.formParam("nome"));
            playlist.setPublica(ctx.formParam("publica") != null);

            if (playlistDAO.alterar(playlist)) {
                ctx.redirect("/playlists/tela_listagem");
            } else {
                ctx.html("Erro ao alterar playlist.");
            }
        });

        app.post("/playlists/excluir", ctx -> {
            int id = Integer.parseInt(ctx.formParam("id"));
            boolean resultado = playlistDAO.excluir(id);
            if (resultado) {
                ctx.redirect("/playlists/tela_listagem");
            } else {
                ctx.html("Erro ao excluir playlist.");
            }
        });
    }
}