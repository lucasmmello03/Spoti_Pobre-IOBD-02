package controller;

import io.javalin.Javalin;
import negocio.Playlist;
import persistencia.PlaylistDAO;
import persistencia.UsuarioDAO;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class PlaylistController {

    private PlaylistDAO playlistDAO = new PlaylistDAO();
    private UsuarioDAO usuarioDAO = new UsuarioDAO();

    private String limpar(String s) {
        return s == null ? "" : s.trim();
    }

    private String montarUrlBusca(String tag, String clima, boolean destaque) {
        List<String> partes = new ArrayList<>();
        if (!tag.isEmpty()) {
            partes.add("tag=" + URLEncoder.encode(tag, StandardCharsets.UTF_8));
        }
        if (!clima.isEmpty()) {
            partes.add("clima=" + URLEncoder.encode(clima, StandardCharsets.UTF_8));
        }
        if (destaque) {
            partes.add("destaque=on");
        }
        return "/playlists/busca" + (partes.isEmpty() ? "" : "?" + String.join("&", partes));
    }

    public PlaylistController(Javalin app) {

        app.get("/playlists/tela_listagem", ctx -> {
            Map<String, Object> map = new HashMap<>();
            map.put("playlists", playlistDAO.listarTodas());
            ctx.render("/templates/playlists/tela_listagem.html", map);
        });

        app.get("/playlists/busca", ctx -> {
            String tag = limpar(ctx.queryParam("tag"));
            String clima = limpar(ctx.queryParam("clima")).toLowerCase();
            boolean destaque = ctx.queryParam("destaque") != null;

            List<Playlist> resultado = playlistDAO.buscarPorExtras(tag, clima, destaque);

            List<Map<String, Object>> climas = new ArrayList<>();
            for (String c : playlistDAO.listarClimas()) {
                boolean ativo = c.equals(clima);
                Map<String, Object> item = new HashMap<>();
                item.put("nome", c);
                item.put("ativo", ativo);
                item.put("url", montarUrlBusca(tag, ativo ? "" : c, destaque));
                climas.add(item);
            }

            Map<String, Object> map = new HashMap<>();
            map.put("tag", tag);
            map.put("clima", clima);
            map.put("destaque", destaque);
            map.put("playlists", resultado);
            map.put("total", resultado.size());
            map.put("tagsDisponiveis", playlistDAO.listarTags());
            map.put("climas", climas);
            map.put("destaqueUrl", montarUrlBusca(tag, clima, !destaque));
            map.put("temFiltro", !tag.isEmpty() || !clima.isEmpty() || destaque);
            ctx.render("/templates/playlists/busca.html", map);
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
            novaPlaylist.setDescricao(ctx.formParam("descricao"));
            novaPlaylist.setTags(ctx.formParam("tags"));
            novaPlaylist.setClima(ctx.formParam("clima"));
            novaPlaylist.setDestaque(ctx.formParam("destaque") != null);

            boolean resultado = playlistDAO.salvarComDono(novaPlaylist, usuarioId);

            if (resultado) {
                ctx.redirect("/playlists/tela_listagem");
            } else {
                ctx.html("Erro ao criar playlist.");
            }
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
            playlist.setDescricao(ctx.formParam("descricao"));
            playlist.setTags(ctx.formParam("tags"));
            playlist.setClima(ctx.formParam("clima"));
            playlist.setDestaque(ctx.formParam("destaque") != null);

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