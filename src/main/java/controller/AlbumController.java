package controller;

import io.javalin.Javalin;
import io.javalin.http.UploadedFile;
import negocio.Album;
import negocio.CapaAlbum;
import persistencia.AlbumDAO;
import java.util.HashMap;
import java.util.Map;

public class AlbumController {

    private static final long TAMANHO_MAXIMO = 2L * 1024 * 1024;

    private AlbumDAO albumDAO = new AlbumDAO();

    private String detectarTipo(byte[] b) {
        if (b.length >= 8 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') {
            return "image/png";
        }
        if (b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) {
            return "image/jpeg";
        }
        if (b.length >= 6 && b[0] == 'G' && b[1] == 'I' && b[2] == 'F' && b[3] == '8') {
            return "image/gif";
        }
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') {
            return "image/webp";
        }
        return null;
    }

    public AlbumController(Javalin app) {

        app.get("/albuns", ctx -> {
            String ok = ctx.queryParam("ok");
            String erro = ctx.queryParam("erro");

            String mensagem = null;
            if ("enviada".equals(ok)) {
                mensagem = "Capa salva com sucesso.";
            } else if ("removida".equals(ok)) {
                mensagem = "Capa removida. O álbum foi mantido.";
            }

            String mensagemErro = null;
            if ("sem_arquivo".equals(erro)) {
                mensagemErro = "Escolha um arquivo de imagem antes de enviar.";
            } else if ("muito_grande".equals(erro)) {
                mensagemErro = "A imagem passa de 2 MB. Escolha um arquivo menor.";
            } else if ("formato".equals(erro)) {
                mensagemErro = "Formato inválido. Envie uma imagem PNG, JPEG, GIF ou WEBP.";
            } else if ("falha".equals(erro)) {
                mensagemErro = "Não foi possível salvar a capa.";
            }

            Map<String, Object> map = new HashMap<>();
            map.put("albuns", albumDAO.listar());
            map.put("mensagem", mensagem);
            map.put("mensagemErro", mensagemErro);
            ctx.render("/templates/albuns/lista.html", map);
        });

        app.get("/albuns/capa/{id}", ctx -> {
            int id;
            try {
                id = Integer.parseInt(ctx.pathParam("id"));
            } catch (NumberFormatException e) {
                ctx.status(404);
                return;
            }

            CapaAlbum capa = albumDAO.obterCapa(id);
            if (capa == null) {
                ctx.status(404);
                return;
            }

            ctx.header("Cache-Control", "no-cache");
            ctx.header("X-Content-Type-Options", "nosniff");
            ctx.contentType(capa.tipo());
            ctx.result(capa.bytes());
        });

        app.post("/albuns/capa/{id}", ctx -> {
            int id;
            try {
                id = Integer.parseInt(ctx.pathParam("id"));
            } catch (NumberFormatException e) {
                ctx.redirect("/albuns");
                return;
            }

            Album album = albumDAO.buscarPorId(id);
            if (album == null) {
                ctx.redirect("/albuns");
                return;
            }

            UploadedFile arquivo = ctx.uploadedFile("capa");
            if (arquivo == null || arquivo.size() == 0) {
                ctx.redirect("/albuns?erro=sem_arquivo#album-" + id);
                return;
            }
            if (arquivo.size() > TAMANHO_MAXIMO) {
                ctx.redirect("/albuns?erro=muito_grande#album-" + id);
                return;
            }

            byte[] bytes = arquivo.content().readAllBytes();
            String tipo = detectarTipo(bytes);
            if (tipo == null) {
                ctx.redirect("/albuns?erro=formato#album-" + id);
                return;
            }

            if (albumDAO.salvarCapa(id, bytes, tipo)) {
                ctx.redirect("/albuns?ok=enviada#album-" + id);
            } else {
                ctx.redirect("/albuns?erro=falha#album-" + id);
            }
        });

        app.post("/albuns/capa/excluir/{id}", ctx -> {
            int id;
            try {
                id = Integer.parseInt(ctx.pathParam("id"));
            } catch (NumberFormatException e) {
                ctx.redirect("/albuns");
                return;
            }

            if (albumDAO.excluirCapa(id)) {
                ctx.redirect("/albuns?ok=removida#album-" + id);
            } else {
                ctx.redirect("/albuns?erro=falha#album-" + id);
            }
        });
    }
}
