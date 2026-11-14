package controller;

import io.javalin.Javalin;
import io.javalin.http.Context;
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

    private int lerId(Context ctx) {
        try {
            return Integer.parseInt(ctx.pathParam("id"));
        } catch (NumberFormatException e) {
            return -1;
        }
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

    private String mensagemSucesso(String ok) {
        if (ok == null) {
            return null;
        }
        switch (ok) {
            case "json":
                return "JSON salvo.";
            case "destaque":
                return "Destaque alterado.";
            case "clima":
                return "Clima alterado.";
            case "tag_add":
                return "Tag adicionada.";
            case "tag_rm":
                return "Tag removida.";
            default:
                return null;
        }
    }

    private String mensagemErroRapido(String erro) {
        if (erro == null) {
            return null;
        }
        switch (erro) {
            case "tag_vazia":
                return "Digite uma tag antes de adicionar.";
            case "falha":
                return "Não foi possível alterar o JSON da playlist.";
            default:
                return null;
        }
    }

    // Monta a tela de detalhe; usada tambem para reexibir o editor com o JSON digitado quando ele e invalido.
    private void renderizarDetalhe(Context ctx, int id, String jsonEditado, String erroJson) {
        Playlist playlist = playlistDAO.buscarPorId(id);

        if (playlist == null) {
            ctx.redirect("/playlists/tela_listagem");
            return;
        }

        String erroRapido = mensagemErroRapido(ctx.queryParam("erro"));

        Map<String, Object> map = new HashMap<>();
        map.put("playlist", playlist);
        map.put("playlistId", id);
        map.put("musicas", playlistDAO.listarMusicas(id));
        map.put("climas", playlistDAO.listarClimas());
        map.put("jsonEditor", jsonEditado != null ? jsonEditado : playlist.getDadosJson());
        map.put("erroJson", erroJson != null ? erroJson : erroRapido);
        map.put("mensagem", mensagemSucesso(ctx.queryParam("ok")));
        ctx.render("/templates/playlists/detalhe.html", map);
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
            map.put("condicaoJsonb", playlistDAO.descreverBusca(tag, clima, destaque));
            ctx.render("/templates/playlists/busca.html", map);
        });

        app.get("/playlists/detalhe/{id}", ctx -> {
            int id = lerId(ctx);
            if (id < 0) {
                ctx.redirect("/playlists/tela_listagem");
                return;
            }
            renderizarDetalhe(ctx, id, null, null);
        });

        // ---- Edicao direta do JSONB (tela de detalhe) ----

        app.post("/playlists/jsonb/destaque/{id}", ctx -> {
            int id = lerId(ctx);
            if (id < 0) {
                ctx.redirect("/playlists/tela_listagem");
                return;
            }
            boolean ok = playlistDAO.alternarDestaque(id);
            ctx.redirect("/playlists/detalhe/" + id + (ok ? "?ok=destaque" : "?erro=falha") + "#jsonb");
        });

        app.post("/playlists/jsonb/clima/{id}", ctx -> {
            int id = lerId(ctx);
            if (id < 0) {
                ctx.redirect("/playlists/tela_listagem");
                return;
            }
            boolean ok = playlistDAO.definirClima(id, ctx.formParam("clima"));
            ctx.redirect("/playlists/detalhe/" + id + (ok ? "?ok=clima" : "?erro=falha") + "#jsonb");
        });

        app.post("/playlists/jsonb/tag/{id}", ctx -> {
            int id = lerId(ctx);
            if (id < 0) {
                ctx.redirect("/playlists/tela_listagem");
                return;
            }
            String tag = limpar(ctx.formParam("tag"));
            if (tag.isEmpty()) {
                ctx.redirect("/playlists/detalhe/" + id + "?erro=tag_vazia#jsonb");
                return;
            }
            boolean ok = playlistDAO.adicionarTag(id, tag);
            ctx.redirect("/playlists/detalhe/" + id + (ok ? "?ok=tag_add" : "?erro=falha") + "#jsonb");
        });

        app.post("/playlists/jsonb/tag/remover/{id}", ctx -> {
            int id = lerId(ctx);
            if (id < 0) {
                ctx.redirect("/playlists/tela_listagem");
                return;
            }
            boolean ok = playlistDAO.removerTag(id, ctx.formParam("tag"));
            ctx.redirect("/playlists/detalhe/" + id + (ok ? "?ok=tag_rm" : "?erro=falha") + "#jsonb");
        });

        app.post("/playlists/jsonb/editar/{id}", ctx -> {
            int id = lerId(ctx);
            if (id < 0) {
                ctx.redirect("/playlists/tela_listagem");
                return;
            }
            String json = ctx.formParam("json");
            String erro = playlistDAO.salvarJsonBruto(id, json);

            if (erro == null) {
                ctx.redirect("/playlists/detalhe/" + id + "?ok=json#jsonb");
            } else {
                renderizarDetalhe(ctx, id, json, erro);
            }
        });

        // ---- CRUD da playlist ----

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