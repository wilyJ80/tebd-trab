--
-- depends:

-- =====================================================================
-- AMBIENTE OLAP - Data Warehouse de Mobilidade Urbana
-- Constelação de fatos (2 fatos que compartilham dimensões conformadas):
--   fato_viagens_transporte  -> grão: 1 viagem
--   fato_bilhetagem          -> grão: 1 viagem x 1 tipo de tarifa
-- =====================================================================

-- 1. Dimensão Tempo (grão: hora). Chave inteligente AAAAMMDDHH.
CREATE TABLE dim_tempo (
    sk_tempo INTEGER PRIMARY KEY,
    data_completa TEXT NOT NULL,
    ano INTEGER NOT NULL,
    trimestre INTEGER NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    mes INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
    nome_mes TEXT NOT NULL,
    dia INTEGER NOT NULL CHECK (dia BETWEEN 1 AND 31),
    dia_da_semana TEXT NOT NULL,
    eh_final_semana INTEGER NOT NULL CHECK (eh_final_semana IN (0, 1)),
    hora INTEGER NOT NULL CHECK (hora BETWEEN 0 AND 23),
    periodo_dia TEXT NOT NULL,
    eh_horario_pico INTEGER NOT NULL CHECK (eh_horario_pico IN (0, 1)),
    periodo_escolar TEXT NOT NULL CHECK (periodo_escolar IN ('Letivo', 'Férias')),
    eh_periodo_chuvoso INTEGER NOT NULL CHECK (eh_periodo_chuvoso IN (0, 1))
);

-- 2. Dimensão Geográfica (hierarquia Ponto -> Bairro -> Zona Urbana)
CREATE TABLE dim_localizacao (
    sk_localizacao INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_ponto TEXT UNIQUE NOT NULL,
    logradouro TEXT NOT NULL,
    bairro TEXT NOT NULL,
    zona_urbana TEXT NOT NULL,
    latitude REAL,
    longitude REAL
);

-- 3. Dimensão Linha
CREATE TABLE dim_linha (
    sk_linha INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_linha TEXT UNIQUE NOT NULL,
    nome_linha TEXT NOT NULL,
    tipo_servico TEXT NOT NULL,
    zona_urbana TEXT NOT NULL,
    tarifa_base REAL NOT NULL,
    extensao_km REAL NOT NULL
);

-- 4. Dimensão Veículo e Sustentabilidade
CREATE TABLE dim_veiculo (
    sk_veiculo INTEGER PRIMARY KEY AUTOINCREMENT,
    prefixo TEXT UNIQUE NOT NULL,
    placa TEXT NOT NULL,
    tipo_combustivel TEXT NOT NULL,
    capacidade_passageiros INTEGER NOT NULL,
    capacidade_faixa TEXT NOT NULL,
    ano_fabricacao INTEGER,
    empresa_concessionaria TEXT NOT NULL
);

-- 5. Dimensão Passageiro / Tarifa
CREATE TABLE dim_tarifa (
    sk_tarifa INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_tarifa TEXT UNIQUE NOT NULL,
    percentual_desconto REAL NOT NULL,
    categoria_gratuidade TEXT NOT NULL,
    eh_subsidiada INTEGER NOT NULL CHECK (eh_subsidiada IN (0, 1))
);

-- 6. Tabela Fato de Viagens (grão: uma viagem individualizada)
CREATE TABLE fato_viagens_transporte (
    id_viagem INTEGER PRIMARY KEY,          -- dimensão degenerada (origem OLTP)
    sk_tempo_partida INTEGER NOT NULL,
    sk_localizacao_partida INTEGER NOT NULL,
    sk_localizacao_chegada INTEGER NOT NULL,
    sk_linha INTEGER NOT NULL,
    sk_veiculo INTEGER NOT NULL,

    quantidade_viagens INTEGER NOT NULL DEFAULT 1,
    total_passageiros INTEGER NOT NULL,
    lotacao_maxima INTEGER NOT NULL,
    capacidade_ofertada INTEGER NOT NULL,
    taxa_ocupacao REAL NOT NULL,
    tempo_viagem_minutos INTEGER NOT NULL,
    atraso_minutos INTEGER NOT NULL,
    distancia_km REAL NOT NULL,
    emissao_co2_kg REAL NOT NULL,
    faturamento_bruto REAL NOT NULL,
    flag_atraso INTEGER NOT NULL CHECK (flag_atraso IN (0, 1)),
    flag_superlotacao INTEGER NOT NULL CHECK (flag_superlotacao IN (0, 1)),

    FOREIGN KEY (sk_tempo_partida) REFERENCES dim_tempo(sk_tempo),
    FOREIGN KEY (sk_localizacao_partida) REFERENCES dim_localizacao(sk_localizacao),
    FOREIGN KEY (sk_localizacao_chegada) REFERENCES dim_localizacao(sk_localizacao),
    FOREIGN KEY (sk_linha) REFERENCES dim_linha(sk_linha),
    FOREIGN KEY (sk_veiculo) REFERENCES dim_veiculo(sk_veiculo)
);

-- 7. Tabela Fato de Bilhetagem (grão: viagem x tipo de tarifa)
CREATE TABLE fato_bilhetagem (
    id_viagem INTEGER NOT NULL,             -- dimensão degenerada
    sk_tarifa INTEGER NOT NULL,
    sk_tempo_partida INTEGER NOT NULL,
    sk_localizacao_partida INTEGER NOT NULL,
    sk_linha INTEGER NOT NULL,
    sk_veiculo INTEGER NOT NULL,

    quantidade_passageiros INTEGER NOT NULL,
    faturamento REAL NOT NULL,
    valor_subsidio REAL NOT NULL,           -- renúncia tarifária (tarifa cheia - arrecadado)

    PRIMARY KEY (id_viagem, sk_tarifa),
    FOREIGN KEY (sk_tarifa) REFERENCES dim_tarifa(sk_tarifa),
    FOREIGN KEY (sk_tempo_partida) REFERENCES dim_tempo(sk_tempo),
    FOREIGN KEY (sk_localizacao_partida) REFERENCES dim_localizacao(sk_localizacao),
    FOREIGN KEY (sk_linha) REFERENCES dim_linha(sk_linha),
    FOREIGN KEY (sk_veiculo) REFERENCES dim_veiculo(sk_veiculo)
);

CREATE INDEX idx_fv_tempo ON fato_viagens_transporte(sk_tempo_partida);
CREATE INDEX idx_fv_linha ON fato_viagens_transporte(sk_linha);
CREATE INDEX idx_fv_veiculo ON fato_viagens_transporte(sk_veiculo);
CREATE INDEX idx_fb_tempo ON fato_bilhetagem(sk_tempo_partida);
CREATE INDEX idx_fb_tarifa ON fato_bilhetagem(sk_tarifa);
