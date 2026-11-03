package negocio;

import java.time.LocalDateTime;

public class Playlist {

    private int id;
    private String nome;
    private LocalDateTime dataHoraCriacao;
    private boolean publica;
    private String donoNome;

    public String getDono_nome() {
        return donoNome;
    }

    public void setDono_nome(String donoNome) {
        this.donoNome = donoNome;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public LocalDateTime getDataHoraCriacao() {
        return dataHoraCriacao;
    }

    public void setDataHoraCriacao(LocalDateTime dataHoraCriacao) {
        this.dataHoraCriacao = dataHoraCriacao;
    }

    public boolean isPublica() {
        return publica;
    }

    public void setPublica(boolean publica) {
        this.publica = publica;
    }

    public String getDataCriacaoFormatada() {
        if (dataHoraCriacao == null) {
            return "";
        }
        return dataHoraCriacao.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
    }
}