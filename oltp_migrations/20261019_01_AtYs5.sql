-- 
-- depends: 

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
    id_empresa INTEGER,
    placa TEXT UNIQUE NOT NULL,
    prefixo TEXT NOT NULL,
    capacidade_passageiros INTEGER NOT NULL,
    tipo_combustivel TEXT NOT NULL,
    ano_fabricacao INTEGER,
    FOREIGN KEY (id_empresa) REFERENCES empresas_onibus(id_empresa)
);

-- 3. Entidade Linha de Transporte
CREATE TABLE linhas (
    id_linha INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_linha TEXT UNIQUE NOT NULL,
    nome_linha TEXT NOT NULL,
    tarifa_base REAL NOT NULL,
    zona_urbana TEXT NOT NULL
);

-- 4. Entidade Ponto de Parada
CREATE TABLE pontos_parada (
    id_ponto INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_ponto TEXT UNIQUE NOT NULL,
    logradouro TEXT NOT NULL,
    bairro TEXT NOT NULL,
    latitude REAL,
    longitude REAL
);

-- 5. Entidade Tipo de Tarifa / Passageiro
CREATE TABLE tipos_tarifa (
    id_tipo_tarifa INTEGER PRIMARY KEY AUTOINCREMENT,
    descricao TEXT NOT NULL,
    percentual_desconto REAL DEFAULT 0.00
);

-- 6. Entidade Transação de Viagem (Registro de Bilhetagem / GPS)
CREATE TABLE viagens_diarias (
    id_viagem INTEGER PRIMARY KEY AUTOINCREMENT,
    id_veiculo INTEGER,
    id_linha INTEGER,
    id_ponto_partida INTEGER,
    id_ponto_chegada INTEGER,
    id_tipo_tarifa INTEGER,
    data_hora_partida TEXT NOT NULL,
    data_hora_chegada TEXT,
    atraso_minutos INTEGER DEFAULT 0,
    passageiros_pagantes INTEGER NOT NULL,
    co2_emitido_kg REAL,
    FOREIGN KEY (id_veiculo) REFERENCES veiculos(id_veiculo),
    FOREIGN KEY (id_linha) REFERENCES linhas(id_linha),
    FOREIGN KEY (id_ponto_partida) REFERENCES pontos_parada(id_ponto),
    FOREIGN KEY (id_ponto_chegada) REFERENCES pontos_parada(id_ponto),
    FOREIGN KEY (id_tipo_tarifa) REFERENCES tipos_tarifa(id_tipo_tarifa)
);
