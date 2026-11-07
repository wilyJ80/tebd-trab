-- =====================================================================
-- DASHBOARD OPERACIONAL (nível operacional: supervisores de tráfego / CCO)
-- Banco: oltp.db  ·  Horizonte: o dia corrente, nível de detalhe da viagem.
-- "Hoje" = último dia com registros (em produção: date('now', 'localtime')).
-- =====================================================================

-- @consulta O1
-- @titulo Viagens com atraso crítico hoje
-- @enunciado Listar as viagens de hoje que partiram com mais de 20 minutos de atraso, com linha, veículo, horário previsto e real, para que o Centro de Controle Operacional acione a fiscalização e informe os passageiros.
-- @grafico tabela
SELECT l.codigo_linha                         AS linha,
       l.nome_linha,
       ve.prefixo                             AS veiculo,
       ve.tipo_combustivel                    AS combustivel,
       time(v.data_hora_partida_prevista)     AS partida_prevista,
       time(v.data_hora_partida)              AS partida_real,
       v.atraso_minutos
FROM viagens_diarias v
JOIN linhas l   ON l.id_linha   = v.id_linha
JOIN veiculos ve ON ve.id_veiculo = v.id_veiculo
WHERE date(v.data_hora_partida_prevista) = (SELECT MAX(date(data_hora_partida_prevista)) FROM viagens_diarias)
  AND v.atraso_minutos > 20
ORDER BY v.atraso_minutos DESC;

-- @consulta O2
-- @titulo Viagens superlotadas hoje
-- @enunciado Identificar as viagens de hoje em que a lotação máxima a bordo superou a capacidade do veículo, mostrando o percentual de ocupação, para remanejar veículos ainda no mesmo dia.
-- @grafico tabela
SELECT l.codigo_linha                         AS linha,
       time(v.data_hora_partida_prevista)     AS horario,
       ve.prefixo                             AS veiculo,
       ve.capacidade_passageiros              AS capacidade,
       v.lotacao_maxima,
       ROUND(100.0 * v.lotacao_maxima / ve.capacidade_passageiros, 1) AS ocupacao_pct
FROM viagens_diarias v
JOIN linhas l    ON l.id_linha   = v.id_linha
JOIN veiculos ve ON ve.id_veiculo = v.id_veiculo
WHERE date(v.data_hora_partida_prevista) = (SELECT MAX(date(data_hora_partida_prevista)) FROM viagens_diarias)
  AND v.lotacao_maxima > ve.capacidade_passageiros
ORDER BY ocupacao_pct DESC;

-- @consulta O3
-- @titulo Pontualidade de cada linha hoje
-- @enunciado Para cada linha, mostrar quantas viagens foram feitas hoje, o atraso médio e o percentual de viagens pontuais (atraso de até 10 min), ordenando da pior para a melhor.
-- @grafico barra x=linha y=pct_pontual
SELECT l.codigo_linha                                         AS linha,
       COUNT(*)                                               AS viagens,
       ROUND(AVG(v.atraso_minutos), 1)                        AS atraso_medio_min,
       ROUND(100.0 * SUM(v.atraso_minutos <= 10) / COUNT(*), 1) AS pct_pontual
FROM viagens_diarias v
JOIN linhas l ON l.id_linha = v.id_linha
WHERE date(v.data_hora_partida_prevista) = (SELECT MAX(date(data_hora_partida_prevista)) FROM viagens_diarias)
GROUP BY l.codigo_linha
ORDER BY pct_pontual ASC, atraso_medio_min DESC;

-- @consulta O4
-- @titulo Passageiros e arrecadação hoje por tipo de tarifa
-- @enunciado Totalizar, para o dia de hoje, o número de validações e o valor arrecadado por tipo de tarifa, para o fechamento de caixa diário da bilhetagem.
-- @grafico barra x=tipo_tarifa y=passageiros
SELECT t.descricao                         AS tipo_tarifa,
       SUM(b.quantidade_validacoes)        AS passageiros,
       ROUND(SUM(b.valor_arrecadado), 2)   AS arrecadado_rs
FROM validacoes_bilhetagem b
JOIN tipos_tarifa t    ON t.id_tipo_tarifa = b.id_tipo_tarifa
JOIN viagens_diarias v ON v.id_viagem      = b.id_viagem
WHERE date(v.data_hora_partida_prevista) = (SELECT MAX(date(data_hora_partida_prevista)) FROM viagens_diarias)
GROUP BY t.id_tipo_tarifa
ORDER BY passageiros DESC;

-- @consulta O5
-- @titulo Utilização da frota hoje por empresa
-- @enunciado Para cada empresa e tipo de combustível, mostrar quantos veículos rodaram hoje, quantas viagens e quantos km fizeram e quanto CO₂ emitiram, para controle diário da escala de frota.
-- @grafico barra x=empresa y=km_rodados cor=combustivel
SELECT e.nome_fantasia                         AS empresa,
       ve.tipo_combustivel                     AS combustivel,
       COUNT(DISTINCT v.id_veiculo)            AS veiculos_em_operacao,
       COUNT(*)                                AS viagens,
       ROUND(SUM(v.distancia_km), 1)           AS km_rodados,
       ROUND(SUM(v.co2_emitido_kg), 1)         AS co2_kg
FROM viagens_diarias v
JOIN veiculos ve       ON ve.id_veiculo = v.id_veiculo
JOIN empresas_onibus e ON e.id_empresa  = ve.id_empresa
WHERE date(v.data_hora_partida_prevista) = (SELECT MAX(date(data_hora_partida_prevista)) FROM viagens_diarias)
GROUP BY e.nome_fantasia, ve.tipo_combustivel
ORDER BY e.nome_fantasia, km_rodados DESC;
