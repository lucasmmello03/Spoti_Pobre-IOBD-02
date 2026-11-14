package controller;

import io.javalin.Javalin;
import negocio.AlbumColetanea;
import persistencia.ColetaneaDAO;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.Map;

public class ColetaneaController {

    private ColetaneaDAO coletaneaDAO = new ColetaneaDAO();

    private String limpar(String s) {
        return s == null ? "" : s.trim();
    }

    private Integer lerInteiro(String s) {
        try {
            return Integer.parseInt(limpar(s));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public ColetaneaController(Javalin app) {

        app.get("/coletaneas", ctx -> {
            String visao = limpar(ctx.queryParam("visao"));
            String tema = limpar(ctx.queryParam("tema"));
            String anoTexto = limpar(ctx.queryParam("ano"));
            Integer ano = lerInteiro(anoTexto);

            Map<String, Object> map = new HashMap<>();
            map.put("totalComFilhas", coletaneaDAO.contarComFilhas());
            map.put("totalSomenteAlbuns", coletaneaDAO.contarSomenteAlbuns());
            map.put("totalColetaneas", coletaneaDAO.contarColetaneas());
            map.put("mensagem", ctx.queryParam("ok") != null ? "Coletânea cadastrada." : null);

            if ("todos".equals(visao)) {
                map.put("visaoTodos", true);
                map.put("albuns", coletaneaDAO.listarAlbunsComFilhas());
            } else if ("only".equals(visao)) {
                map.put("visaoOnly", true);
                map.put("albuns", coletaneaDAO.listarSomenteAlbuns());
            } else {
                map.put("visaoColetaneas", true);
                map.put("tema", tema);
                map.put("ano", anoTexto);
                map.put("coletaneas", coletaneaDAO.consultar(tema, ano));
            }
            ctx.render("/templates/coletaneas/lista.html", map);
        });

        app.get("/coletaneas/nova", ctx -> {
            String erro = ctx.queryParam("erro");
            String mensagemErro = null;
            if ("dados".equals(erro)) {
                mensagemErro = "Preencha título, tema e um ano de referência entre 1900 e 2100.";
            } else if ("falha".equals(erro)) {
                mensagemErro = "Não foi possível cadastrar a coletânea.";
            }

            Map<String, Object> map = new HashMap<>();
            map.put("generos", coletaneaDAO.listarGeneros());
            map.put("mensagemErro", mensagemErro);
            ctx.render("/templates/coletaneas/nova.html", map);
        });

        app.post("/coletaneas/nova", ctx -> {
            String titulo = limpar(ctx.formParam("titulo"));
            String tema = limpar(ctx.formParam("tema"));
            Integer ano = lerInteiro(ctx.formParam("ano_referencia"));

            if (titulo.isEmpty() || tema.isEmpty() || ano == null || ano < 1900 || ano > 2100) {
                ctx.redirect("/coletaneas/nova?erro=dados");
                return;
            }

            AlbumColetanea coletanea = new AlbumColetanea();
            coletanea.setTitulo(titulo);
            coletanea.setTema(tema);
            coletanea.setAnoReferencia(ano);

            String data = limpar(ctx.formParam("data_lancamento"));
            if (!data.isEmpty()) {
                try {
                    coletanea.setData_lancamento(LocalDate.parse(data));
                } catch (DateTimeParseException e) {
                    ctx.redirect("/coletaneas/nova?erro=dados");
                    return;
                }
            }

            Integer generoId = lerInteiro(ctx.formParam("genero_id"));
            if (generoId != null) {
                coletanea.setGenero_id(generoId);
            }

            if (coletaneaDAO.salvar(coletanea)) {
                ctx.redirect("/coletaneas?ok=1");
            } else {
                ctx.redirect("/coletaneas/nova?erro=falha");
            }
        });
    }
}
