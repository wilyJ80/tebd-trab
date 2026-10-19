# Dicionário de Dados - Sistema de Mobilidade Urbana (TEBD 2026.2)

Este documento apresenta o **Dicionário de Dados** do sistema de transporte público desenvolvido para a disciplina de Tecnologias de Banco de Dados (TEBD), alinhado ao **ODS 11 (Cidades e Comunidades Sustentáveis)**. 

O projeto é dividido em duas arquiteturas principais:
1. **OLTP (Transacional)**: Responsável pela operação diária, registro de bilhetagem, frotas, linhas, pontos e viagens.
2. **OLAP (Data Warehouse / Analítico)**: Modelado em *Star Schema* (Modelo Estrela) para suportar consultas analíticas de inteligência de negócios (BI), monitoramento de pontualidade, emissão de carbono, superlotação e perfil tarifário.

---

## 1. Camada OLTP (Banco Transacional)

As tabelas da camada OLTP refletem as entidades operacionais do sistema de transporte público urbano.

### 1.1. `empresas_onibus`
Armazena as informações das empresas concessionárias responsáveis pela operação das frotas de ônibus.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_empresa` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Identificador único da empresa concessionária. |
| `nome_fantasia` | `TEXT` | `NOT NULL` | Nome comercial / fantasia da empresa. |
| `cnpj` | `TEXT` | `UNIQUE NOT NULL` | Número do CNPJ da empresa (identificador fiscal). |
| `telefone` | `TEXT` | - | Número de contato telefônico da empresa. |

---

### 1.2. `veiculos`
Registra a frota de ônibus operada pelas empresas concessionárias, incluindo especificações técnicas e ambientais.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_veiculo` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Identificador único do veículo. |
| `id_empresa` | `INTEGER` | `FOREIGN KEY` | Referência à empresa concessionária proprietária/operadora (`empresas_onibus.id_empresa`). |
| `placa` | `TEXT` | `UNIQUE NOT NULL` | Placa oficial do veículo. |
| `prefixo` | `TEXT` | `NOT NULL` | Código de identificação interno / prefixo do ônibus na frota. |
| `capacidade_passageiros` | `INTEGER` | `NOT NULL` | Capacidade máxima total de passageiros suportada pelo veículo. |
| `tipo_combustivel` | `TEXT` | `NOT NULL` | Tipo de combustível ou tecnologia motora (ex: Diesel, Elétrico, Híbrido, GNV). |
| `ano_fabricacao` | `INTEGER` | - | Ano de fabricação do veículo. |

---

### 1.3. `linhas`
Gerencia as linhas de transporte público operadas no município, contendo tarifas e diretrizes de zona.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_linha` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Identificador único da linha de transporte. |
| `codigo_linha` | `TEXT` | `UNIQUE NOT NULL` | Código alfanumérico oficial da linha (ex: "0412", "L-101"). |
| `nome_linha` | `TEXT` | `NOT NULL` | Nome descritivo da linha (ex: "Pituba / Iguatemi - Lapa"). |
| `tarifa_base` | `REAL` | `NOT NULL` | Valor monetário da tarifa base cobrada na linha. |
| `zona_urbana` | `TEXT` | `NOT NULL` | Zona urbana principal atendida (ex: Centro, Orla, Subúrbio, Norte). |

---

### 1.4. `pontos_parada`
Representa os pontos de parada (pontos de ônibus e estações) geolocalizados pela cidade.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_ponto` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Identificador único do ponto de parada. |
| `codigo_ponto` | `TEXT` | `UNIQUE NOT NULL` | Código de identificação do ponto na rede física (ex: "PT-2039"). |
| `logradouro` | `TEXT` | `NOT NULL` | Nome da rua, avenida ou terminal onde o ponto está localizado. |
| `bairro` | `TEXT` | `NOT NULL` | Bairro em que o ponto está situado. |
| `latitude` | `REAL` | - | Coordenada geográfica de latitude. |
| `longitude` | `REAL` | - | Coordenada geográfica de longitude. |

---

### 1.5. `tipos_tarifa`
Categoriza os perfis tarifários e de passageiros (ex: Passagem Inteira, Meia-Passagem Estudantil, Idoso, Gratuidade).

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_tipo_tarifa` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Identificador único do tipo de tarifa. |
| `descricao` | `TEXT` | `NOT NULL` | Descrição da categoria do passageiro/tarifa (ex: Inteira, Estudante, Idoso). |
| `percentual_desconto` | `REAL` | `DEFAULT 0.00` | Percentual de desconto aplicado sobre a tarifa base (0.00 a 100.00). |

---

### 1.6. `viagens_diarias`
Tabela transacional central que registra as viagens realizadas, dados de bilhetagem e telemetria básica (GPS/horários).

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_viagem` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Identificador único da transação/viagem. |
| `id_veiculo` | `INTEGER` | `FOREIGN KEY` | Veículo que realizou a viagem (`veiculos.id_veiculo`). |
| `id_linha` | `INTEGER` | `FOREIGN KEY` | Linha operada na viagem (`linhas.id_linha`). |
| `id_ponto_partida` | `INTEGER` | `FOREIGN KEY` | Ponto de parada inicial (`pontos_parada.id_ponto`). |
| `id_ponto_chegada` | `INTEGER` | `FOREIGN KEY` | Ponto de parada final (`pontos_parada.id_ponto`). |
| `id_tipo_tarifa` | `INTEGER` | `FOREIGN KEY` | Perfil tarifário predominante/registrado (`tipos_tarifa.id_tipo_tarifa`). |
| `data_hora_partida` | `TEXT` | `NOT NULL` | Data e hora de partida programada/realizada. |
| `data_hora_chegada` | `TEXT` | - | Data e hora de chegada ao destino. |
| `atraso_minutos` | `INTEGER` | `DEFAULT 0` | Tempo de atraso verificado em minutos em relação ao horário planejado. |
| `passageiros_pagantes` | `INTEGER` | `NOT NULL` | Quantidade de passageiros transportados na viagem. |
| `co2_emitido_kg` | `REAL` | - | Estimativa de gás carbônico emitido durante o trajeto (em kg). |

---
---

## 2. Camada OLAP (Data Warehouse / Star Schema)

A camada analítica é estruturada em modelo estrela (*Star Schema*), contendo tabelas dimensionais e uma tabela fato de alto desempenho para análises multidimensionais de mobilidade urbana.

---

### 2.1. Dimensões (`dim_*`)

#### `dim_tempo`
Dimensão temporal detalhada para análises de sazonalidade, horários de pico, dias da semana e períodos do dia.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `sk_tempo` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Chave substituta (*Surrogate Key*) da dimensão tempo. |
| `data_completa` | `TEXT` | `NOT NULL` | Data no formato ISO (`YYYY-MM-DD`). |
| `ano` | `INTEGER` | `NOT NULL` | Ano civil da ocorrência. |
| `trimestre` | `INTEGER` | `NOT NULL` | Número do trimestre (1 a 4). |
| `mes` | `INTEGER` | `NOT NULL` | Número do mês (1 a 12). |
| `nome_mes` | `TEXT` | `NOT NULL` | Nome descritivo do mês (ex: "Janeiro", "Fevereiro"). |
| `dia` | `INTEGER` | `NOT NULL` | Dia do mês (1 a 31). |
| `dia_da_semana` | `TEXT` | `NOT NULL` | Nome do dia da semana (ex: "Segunda-feira"). |
| `eh_final_semana` | `INTEGER` | `NOT NULL` | Indicador booleano (1 para Sábado/Domingo, 0 para dias úteis). |
| `periodo_dia` | `TEXT` | `NOT NULL` | Período do dia classificado (ex: "Pico Manhã", "Vale", "Pico Tarde", "Noite"). |

---

#### `dim_localizacao`
Dimensão espacial para agregação e cruzamento geográfico dos pontos de parada, bairros e zonas urbanas.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `sk_localizacao` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Chave substituta da localização geográfica. |
| `codigo_ponto` | `TEXT` | - | Código oficial do ponto de parada associado. |
| `bairro` | `TEXT` | `NOT NULL` | Nome do bairro de origem ou destino. |
| `zona_urbana` | `TEXT` | `NOT NULL` | Zona urbana da cidade (ex: Centro, Orla, Subúrbio). |

---

#### `dim_linha`
Dimensão que consolida os atributos das linhas de transporte público.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | `PRIMARY KEY AUTOINCREMENT` | Chave substituta da linha de transporte. |
| `sk_linha` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Chave substituta da linha. |
| `codigo_linha` | `TEXT` | `NOT NULL` | Código identificador oficial da linha. |
| `nome_linha` | `TEXT` | `NOT NULL` | Nome descritivo da linha. |
| `tipo_servico` | `TEXT` | - | Categoria/tipo de serviço prestado (ex: Expresso, Parador, Circular). |

---

#### `dim_veiculo`
Dimensão que agrupa características dos veículos e critérios de sustentabilidade da frota.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `sk_veiculo` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Chave substituta do veículo. |
| `prefixo` | `TEXT` | `NOT NULL` | Prefixo ou identificação operacional do veículo. |
| `tipo_combustivel` | `TEXT` | `NOT NULL` | Matriz energética / combustível (Diesel, Elétrico, Híbrido, GNV). |
| `capacidade_faixa` | `TEXT` | `NOT NULL` | Faixa de capacidade de passageiros (ex: "Até 60", "61-90", "Acima de 90"). |
| `empresa_concessionaria` | `TEXT` | `NOT NULL` | Nome da empresa operadora da frota. |

---

#### `dim_tarifa`
Dimensão que categoriza os tipos de tarifas e políticas de gratuidade aplicadas aos passageiros.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `sk_tarifa` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Chave substituta do perfil tarifário. |
| `tipo_tarifa` | `TEXT` | `NOT NULL` | Descrição textual da tarifa (Inteira, Estudante, Idoso, Vale-Transporte). |
| `categoria_gratuidade` | `TEXT` | `NOT NULL` | Categoria de benefício ou gratuidade (ex: "Nenhuma", "Estudante 50%", "Isenção Total"). |

---

### 2.2. Tabela Fato (`fato_viagens_transporte`)

Armazena as métricas quantitativas e indicadores de desempenho (*KPIs*) de cada viagem realizada, cruzando todas as dimensões do modelo.

| Coluna | Tipo | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `sk_tempo_partida` | `INTEGER` | `FOREIGN KEY` | Chave estrangeira para `dim_tempo` (momento de partida). |
| `sk_localizacao_partida`| `INTEGER` | `FOREIGN KEY` | Chave estrangeira para `dim_localizacao` (ponto de partida). |
| `sk_localizacao_chegada`| `INTEGER` | `FOREIGN KEY` | Chave estrangeira para `dim_localizacao` (ponto de chegada). |
| `sk_linha` | `INTEGER` | `FOREIGN KEY` | Chave estrangeira para `dim_linha` (linha operada). |
| `sk_veiculo` | `INTEGER` | `FOREIGN KEY` | Chave estrangeira para `dim_veiculo` (veículo utilizado). |
| `sk_tarifa` | `INTEGER` | `FOREIGN KEY` | Chave estrangeira para `dim_tarifa` (perfil tarifário). |
| `quantidade_viagens` | `INTEGER` | `DEFAULT 1` | Métrica aditiva: contagem de viagens realizadas (valor padrão 1 por registro fato). |
| `total_passageiros` | `INTEGER` | `NOT NULL` | Métrica aditiva: total de passageiros transportados na viagem. |
| `tempo_viagem_minutos` | `INTEGER` | `NOT NULL` | Métrica aditiva / semi-aditiva: duração total da viagem em minutos. |
| `atraso_minutos` | `INTEGER` | `NOT NULL` | Métrica aditiva / média: tempo de atraso registrado em minutos. |
| `emissao_co2_kg` | `REAL` | `NOT NULL` | Métrica aditiva: volume total de gás carbônico emitido no trajeto (kg). |
| `faturamento_bruto` | `REAL` | `NOT NULL` | Métrica aditiva: receita bruta gerada no evento de transporte. |

> **Chave Primária Composta (Fato):**  
> `PRIMARY KEY (sk_tempo_partida, sk_localizacao_partida, sk_localizacao_chegada, sk_linha, sk_veiculo, sk_tarifa)`
