package negocio;

public class AlbumColetanea extends Album {
    private String tema;
    private int anoReferencia;
    private int totalMusicas;
    private String generoNome;

    public String getTema() {
        return tema;
    }

    public void setTema(String tema) {
        this.tema = tema;
    }

    public int getAnoReferencia() {
        return anoReferencia;
    }

    public void setAnoReferencia(int anoReferencia) {
        this.anoReferencia = anoReferencia;
    }

    public int getTotalMusicas() {
        return totalMusicas;
    }

    public void setTotalMusicas(int totalMusicas) {
        this.totalMusicas = totalMusicas;
    }

    public String getGeneroNome() {
        return generoNome;
    }

    public void setGeneroNome(String generoNome) {
        this.generoNome = generoNome;
    }
}
