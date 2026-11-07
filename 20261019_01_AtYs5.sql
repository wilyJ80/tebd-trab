--
-- depends:

-- =====================================================================
-- AMBIENTE OLTP - Sistema transacional de transporte público
-- 8 entidades: empresas_onibus, veiculos, linhas, bairros, pontos_parada,
--              tipos_tarifa, viagens_diarias, validacoes_bilhetagem
-- =====================================================================

-- 1. Entidade Empresa Concessionária
CREATE TABLE empresas_onibus (
    id_empresa INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_fantasia TEXT NOT NULL,
    cnpj TEXT UNIQUE NOT NULL,
    telefone TEXT
);

-- 2. Entidade Veículo
CREATE TABLE veiculos (
    id_veiculo INTEGER PRIMARY KEY AUTOINCREMENT,
    id_empresa INTEGER NOT NULL,
    placa TEXT UNIQUE NOT NULL,
    prefixo TEXT UNIQUE NOT NULL,
    capacidade_passageiros INTEGER NOT NULL CHECK (capacidade_passageiros > 0),
    tipo_combustivel TEXT NOT NULL
        CHECK (tipo_combustivel IN ('Diesel', 'GNV', 'Híbrido', 'Elétrico')),
    ano_fabricacao INTEGER,
    data_inicio_operacao TEXT NOT NULL,
    FOREIGN KEY (id_empresa) REFERENCES empresas_onibus(id_empresa)
);

-- 3. Entidade Linha de Transporte
CREATE TABLE linhas (
    id_linha INTEGER PRIMARY KEY AUTOINCREMENT,
    id_empresa INTEGER NOT NULL,
    codigo_linha TEXT UNIQUE NOT NULL,
    nome_linha TEXT NOT NULL,
    tipo_servico TEXT NOT NULL
        CHECK (tipo_servico IN ('Convencional', 'Expresso', 'Circular', 'Alimentadora')),
    tarifa_base REAL NOT NULL CHECK (tarifa_base >= 0),
    extensao_km REAL NOT NULL CHECK (extensao_km > 0),
    zona_urbana TEXT NOT NULL,
    FOREIGN KEY (id_empresa) REFERENCES empresas_onibus(id_empresa)
);

-- 4. Entidade Bairro (hierarquia espacial Bairro -> Zona Urbana)
CREATE TABLE bairros (
    id_bairro INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_bairro TEXT UNIQUE NOT NULL,
    zona_urbana TEXT NOT NULL
);

-- 5. Entidade Ponto de Parada
CREATE TABLE pontos_parada (
    id_ponto INTEGER PRIMARY KEY AUTOINCREMENT,
    id_bairro INTEGER NOT NULL,
    codigo_ponto TEXT UNIQUE NOT NULL,
    logradouro TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    FOREIGN KEY (id_bairro) REFERENCES bairros(id_bairro)
);

-- 6. Entidade Tipo de Tarifa / Passageiro
CREATE TABLE tipos_tarifa (
    id_tipo_tarifa INTEGER PRIMARY KEY AUTOINCREMENT,
    descricao TEXT UNIQUE NOT NULL,
    percentual_desconto REAL NOT NULL DEFAULT 0.00
        CHECK (percentual_desconto BETWEEN 0 AND 100),
    eh_subsidiada INTEGER NOT NULL DEFAULT 0 CHECK (eh_subsidiada IN (0, 1))
);

-- 7. Entidade Transação de Viagem (Registro de GPS / telemetria)
CREATE TABLE viagens_diarias (
    id_viagem INTEGER PRIMARY KEY AUTOINCREMENT,
    id_veiculo INTEGER NOT NULL,
    id_linha INTEGER NOT NULL,
    id_ponto_partida INTEGER NOT NULL,
    id_ponto_chegada INTEGER NOT NULL,
    data_hora_partida_prevista TEXT NOT NULL,
    data_hora_partida TEXT NOT NULL,
    data_hora_chegada TEXT,
    atraso_minutos INTEGER NOT NULL DEFAULT 0,
    distancia_km REAL NOT NULL CHECK (distancia_km > 0),
    total_passageiros INTEGER NOT NULL CHECK (total_passageiros >= 0),
    lotacao_maxima INTEGER NOT NULL CHECK (lotacao_maxima >= 0),
    co2_emitido_kg REAL NOT NULL DEFAULT 0,
    FOREIGN KEY (id_veiculo) REFERENCES veiculos(id_veiculo),
    FOREIGN KEY (id_linha) REFERENCES linhas(id_linha),
    FOREIGN KEY (id_ponto_partida) REFERENCES pontos_parada(id_ponto),
    FOREIGN KEY (id_ponto_chegada) REFERENCES pontos_parada(id_ponto)
);

-- 8. Entidade Validação de Bilhetagem (passageiros por tipo de tarifa em cada viagem)
CREATE TABLE validacoes_bilhetagem (
    id_validacao INTEGER PRIMARY KEY AUTOINCREMENT,
    id_viagem INTEGER NOT NULL,
    id_tipo_tarifa INTEGER NOT NULL,
    quantidade_validacoes INTEGER NOT NULL CHECK (quantidade_validacoes >= 0),
    valor_arrecadado REAL NOT NULL CHECK (valor_arrecadado >= 0),
    UNIQUE (id_viagem, id_tipo_tarifa),
    FOREIGN KEY (id_viagem) REFERENCES viagens_diarias(id_viagem),
    FOREIGN KEY (id_tipo_tarifa) REFERENCES tipos_tarifa(id_tipo_tarifa)
);

-- Índices para as consultas operacionais
CREATE INDEX idx_viagens_partida ON viagens_diarias(data_hora_partida);
CREATE INDEX idx_viagens_linha ON viagens_diarias(id_linha);
CREATE INDEX idx_validacoes_viagem ON validacoes_bilhetagem(id_viagem);
