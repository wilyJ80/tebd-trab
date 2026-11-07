-- =====================================================================
-- ETL: OLTP (oltp.db, anexado como "oltp") -> OLAP (olap.db, banco principal)
-- Carga completa (full load): limpa o DW e recarrega dimensões e fatos.
-- Executado por src/tebd_trab/etl.py
-- =====================================================================

DELETE FROM fato_bilhetagem;
DELETE FROM fato_viagens_transporte;
DELETE FROM dim_tempo;
DELETE FROM dim_localizacao;
DELETE FROM dim_linha;
DELETE FROM dim_veiculo;
DELETE FROM dim_tarifa;
DELETE FROM sqlite_sequence;

-- ---------------------------------------------------------------------
-- dim_tempo: uma linha por hora, cobrindo todo o período das viagens
-- ---------------------------------------------------------------------
INSERT INTO dim_tempo
WITH RECURSIVE horas(ts) AS (
    SELECT (SELECT strftime('%Y-%m-%d 00:00:00', MIN(data_hora_partida_prevista)) FROM oltp.viagens_diarias)
    UNION ALL
    SELECT datetime(ts, '+1 hour') FROM horas
    WHERE ts < (SELECT strftime('%Y-%m-%d 23:00:00', MAX(data_hora_partida_prevista)) FROM oltp.viagens_diarias)
),
base AS (
    SELECT ts,
           CAST(strftime('%Y', ts) AS INTEGER) AS ano,
           CAST(strftime('%m', ts) AS INTEGER) AS mes,
           CAST(strftime('%d', ts) AS INTEGER) AS dia,
           CAST(strftime('%w', ts) AS INTEGER) AS dow,
           CAST(strftime('%H', ts) AS INTEGER) AS hora
    FROM horas
)
SELECT CAST(strftime('%Y%m%d%H', ts) AS INTEGER),
       date(ts), ano, (mes - 1) / 3 + 1, mes,
       CASE mes WHEN 1 THEN 'Janeiro' WHEN 2 THEN 'Fevereiro' WHEN 3 THEN 'Março' WHEN 4 THEN 'Abril'
                WHEN 5 THEN 'Maio' WHEN 6 THEN 'Junho' WHEN 7 THEN 'Julho' WHEN 8 THEN 'Agosto'
                WHEN 9 THEN 'Setembro' WHEN 10 THEN 'Outubro' WHEN 11 THEN 'Novembro' ELSE 'Dezembro' END,
       dia,
       CASE dow WHEN 0 THEN 'Domingo' WHEN 1 THEN 'Segunda-feira' WHEN 2 THEN 'Terça-feira'
                WHEN 3 THEN 'Quarta-feira' WHEN 4 THEN 'Quinta-feira' WHEN 5 THEN 'Sexta-feira'
                ELSE 'Sábado' END,
       CASE WHEN dow IN (0, 6) THEN 1 ELSE 0 END,
       hora,
       CASE WHEN hora < 5 THEN 'Madrugada'
            WHEN hora < 7 THEN 'Manhã'
            WHEN hora < 9 THEN 'Pico Manhã'
            WHEN hora < 17 THEN 'Vale'
            WHEN hora < 19 THEN 'Pico Tarde'
            ELSE 'Noite' END,
       CASE WHEN hora IN (7, 8, 17, 18) THEN 1 ELSE 0 END,
       CASE WHEN mes IN (1, 7, 12) THEN 'Férias' ELSE 'Letivo' END,
       CASE WHEN mes BETWEEN 4 AND 7 THEN 1 ELSE 0 END
FROM base;

-- ---------------------------------------------------------------------
-- Dimensões descritivas
-- ---------------------------------------------------------------------
INSERT INTO dim_localizacao (codigo_ponto, logradouro, bairro, zona_urbana, latitude, longitude)
SELECT p.codigo_ponto, p.logradouro, b.nome_bairro, b.zona_urbana, p.latitude, p.longitude
FROM oltp.pontos_parada p JOIN oltp.bairros b ON b.id_bairro = p.id_bairro
ORDER BY p.id_ponto;

INSERT INTO dim_linha (codigo_linha, nome_linha, tipo_servico, zona_urbana, tarifa_base, extensao_km)
SELECT codigo_linha, nome_linha, tipo_servico, zona_urbana, tarifa_base, extensao_km
FROM oltp.linhas ORDER BY id_linha;

INSERT INTO dim_veiculo (prefixo, placa, tipo_combustivel, capacidade_passageiros, capacidade_faixa,
                         ano_fabricacao, empresa_concessionaria)
SELECT v.prefixo, v.placa, v.tipo_combustivel, v.capacidade_passageiros,
       CASE WHEN v.capacidade_passageiros <= 70 THEN 'Até 70'
            WHEN v.capacidade_passageiros <= 90 THEN '71-90'
            ELSE 'Acima de 90' END,
       v.ano_fabricacao, e.nome_fantasia
FROM oltp.veiculos v JOIN oltp.empresas_onibus e ON e.id_empresa = v.id_empresa
ORDER BY v.id_veiculo;

INSERT INTO dim_tarifa (tipo_tarifa, percentual_desconto, categoria_gratuidade, eh_subsidiada)
SELECT descricao, percentual_desconto,
       CASE WHEN percentual_desconto = 0 THEN 'Nenhuma'
            WHEN percentual_desconto < 100 THEN 'Desconto parcial (' || CAST(percentual_desconto AS INTEGER) || '%)'
            ELSE 'Isenção total' END,
       eh_subsidiada
FROM oltp.tipos_tarifa ORDER BY id_tipo_tarifa;

-- ---------------------------------------------------------------------
-- Tabela de apoio: faturamento por viagem
-- ---------------------------------------------------------------------
CREATE TEMP TABLE tmp_fat AS
SELECT id_viagem, SUM(valor_arrecadado) AS faturamento
FROM oltp.validacoes_bilhetagem GROUP BY id_viagem;
CREATE INDEX temp.idx_tmp_fat ON tmp_fat(id_viagem);

-- ---------------------------------------------------------------------
-- fato_viagens_transporte (grão: viagem)
-- ---------------------------------------------------------------------
INSERT INTO fato_viagens_transporte
SELECT v.id_viagem,
       CAST(strftime('%Y%m%d%H', v.data_hora_partida_prevista) AS INTEGER),
       lp.sk_localizacao, lc.sk_localizacao, dl.sk_linha, dv.sk_veiculo,
       1,
       v.total_passageiros,
       v.lotacao_maxima,
       ve.capacidade_passageiros,
       ROUND(1.0 * v.lotacao_maxima / ve.capacidade_passageiros, 4),
       CAST(ROUND((julianday(v.data_hora_chegada) - julianday(v.data_hora_partida)) * 1440) AS INTEGER),
       v.atraso_minutos,
       v.distancia_km,
       v.co2_emitido_kg,
       COALESCE(f.faturamento, 0),
       CASE WHEN v.atraso_minutos > 10 THEN 1 ELSE 0 END,
       CASE WHEN v.lotacao_maxima > ve.capacidade_passageiros THEN 1 ELSE 0 END
FROM oltp.viagens_diarias v
JOIN oltp.veiculos ve ON ve.id_veiculo = v.id_veiculo
JOIN oltp.linhas l ON l.id_linha = v.id_linha
JOIN oltp.pontos_parada pp ON pp.id_ponto = v.id_ponto_partida
JOIN oltp.pontos_parada pc ON pc.id_ponto = v.id_ponto_chegada
JOIN dim_localizacao lp ON lp.codigo_ponto = pp.codigo_ponto
JOIN dim_localizacao lc ON lc.codigo_ponto = pc.codigo_ponto
JOIN dim_linha dl ON dl.codigo_linha = l.codigo_linha
JOIN dim_veiculo dv ON dv.prefixo = ve.prefixo
LEFT JOIN tmp_fat f ON f.id_viagem = v.id_viagem;

-- ---------------------------------------------------------------------
-- fato_bilhetagem (grão: viagem x tipo de tarifa)
-- valor_subsidio = quanto deixou de ser arrecadado em relação à tarifa cheia
-- ---------------------------------------------------------------------
INSERT INTO fato_bilhetagem
SELECT b.id_viagem, dt.sk_tarifa,
       fv.sk_tempo_partida, fv.sk_localizacao_partida, fv.sk_linha, fv.sk_veiculo,
       b.quantidade_validacoes,
       b.valor_arrecadado,
       ROUND(b.quantidade_validacoes * dl.tarifa_base - b.valor_arrecadado, 2)
FROM oltp.validacoes_bilhetagem b
JOIN oltp.tipos_tarifa t ON t.id_tipo_tarifa = b.id_tipo_tarifa
JOIN dim_tarifa dt ON dt.tipo_tarifa = t.descricao
JOIN fato_viagens_transporte fv ON fv.id_viagem = b.id_viagem
JOIN dim_linha dl ON dl.sk_linha = fv.sk_linha;
