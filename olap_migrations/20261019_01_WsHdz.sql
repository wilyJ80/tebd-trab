-- 
-- depends: 

-- 1. Dimensão Tempo
CREATE TABLE dim_tempo (
    sk_tempo INTEGER PRIMARY KEY AUTOINCREMENT,
    data_completa TEXT NOT NULL,
    ano INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    nome_mes TEXT NOT NULL,
    dia INTEGER NOT NULL,
    dia_da_semana TEXT NOT NULL,
    eh_final_semana INTEGER NOT NULL,
    periodo_dia TEXT NOT NULL
);

-- 2. Dimensão Geográfica
CREATE TABLE dim_localizacao (
    sk_localizacao INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_ponto TEXT,
    bairro TEXT NOT NULL,
    zona_urbana TEXT NOT NULL
);

-- 3. Dimensão Linha
CREATE TABLE dim_linha (
    sk_linha INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_linha TEXT NOT NULL,
    nome_linha TEXT NOT NULL,
    tipo_servico TEXT
);

-- 4. Dimensão Veículo e Sustentabilidade
CREATE TABLE dim_veiculo (
    sk_veiculo INTEGER PRIMARY KEY AUTOINCREMENT,
    prefixo TEXT NOT NULL,
    tipo_combustivel TEXT NOT NULL,
    capacidade_faixa TEXT NOT NULL,
    empresa_concessionaria TEXT NOT NULL
);

-- 5. Dimensão Passageiro / Tarifa
CREATE TABLE dim_tarifa (
    sk_tarifa INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_tarifa TEXT NOT NULL,
    categoria_gratuidade TEXT NOT NULL
);

-- 6. Tabela Fato
CREATE TABLE fato_viagens_transporte (
    sk_tempo_partida INTEGER,
    sk_localizacao_partida INTEGER,
    sk_localizacao_chegada INTEGER,
    sk_linha INTEGER,
    sk_veiculo INTEGER,
    sk_tarifa INTEGER,
    
    quantidade_viagens INTEGER DEFAULT 1,
    total_passageiros INTEGER NOT NULL,
    tempo_viagem_minutos INTEGER NOT NULL,
    atraso_minutos INTEGER NOT NULL,
    emissao_co2_kg REAL NOT NULL,
    faturamento_bruto REAL NOT NULL,
    
    PRIMARY KEY (sk_tempo_partida, sk_localizacao_partida, sk_localizacao_chegada, sk_linha, sk_veiculo, sk_tarifa),
    
    FOREIGN KEY (sk_tempo_partida) REFERENCES dim_tempo(sk_tempo),
    FOREIGN KEY (sk_localizacao_partida) REFERENCES dim_localizacao(sk_localizacao),
    FOREIGN KEY (sk_localizacao_chegada) REFERENCES dim_localizacao(sk_localizacao),
    FOREIGN KEY (sk_linha) REFERENCES dim_linha(sk_linha),
    FOREIGN KEY (sk_veiculo) REFERENCES dim_veiculo(sk_veiculo),
    FOREIGN KEY (sk_tarifa) REFERENCES dim_tarifa(sk_tarifa)
);
