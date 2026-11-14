package negocio;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class Album {
    private int id;
    private String titulo;
    private LocalDate data_lancamento;
    private int genero_id;
    private boolean temCapa;
    private long capaTamanho;
    private String origem;
    private List<Musica> musicas = new ArrayList<>();

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public LocalDate getData_lancamento() {
        return data_lancamento;
    }

    public void setData_lancamento(LocalDate data_lancamento) {
        this.data_lancamento = data_lancamento;
    }

    public int getGenero_id() {
        return genero_id;
    }

    public void setGenero_id(int genero_id) {
        this.genero_id = genero_id;
    }

    public boolean isTemCapa() {
        return temCapa;
    }

    public void setTemCapa(boolean temCapa) {
        this.temCapa = temCapa;
    }

    public long getCapaTamanho() {
        return capaTamanho;
    }

    public void setCapaTamanho(long capaTamanho) {
        this.capaTamanho = capaTamanho;
    }

    public String getCapaTamanhoFormatado() {
        if (capaTamanho < 1024) {
            return capaTamanho + " B";
        }
        return String.format(Locale.of("pt", "BR"), "%.1f KB", capaTamanho / 1024.0);
    }

    public String getOrigem() {
        return origem;
    }

    public void setOrigem(String origem) {
        this.origem = origem;
    }

    public boolean isDeColetanea() {
        return "album_coletanea".equals(origem);
    }

    public List<Musica> getMusicas() {
        return musicas;
    }

    public void setMusicas(List<Musica> musicas) {
        this.musicas = musicas;
    }
}
