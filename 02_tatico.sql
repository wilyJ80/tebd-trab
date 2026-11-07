-- =====================================================================
-- DASHBOARD TÁTICO (nível tático: gerência de operações da SEMOB / concessionárias)
-- Banco: olap.db  ·  Horizonte: meses e trimestres, agregado por linha/zona/empresa.
-- =====================================================================

-- @consulta T1
-- @titulo Ranking de pontualidade no horário de pico (3º trimestre/2026)
-- @enunciado Qual é o atraso médio por linha nos horários de pico (7h-9h e 17h-19h) no último trimestre fechado, comparado com o atraso fora do pico? Ordenar da linha com pior desempenho no pico para a melhor.
-- @grafico barra x=linha y=atraso_medio_pico
SELECT l.codigo_linha                                                         AS linha,
       l.zona_urbana                                                          AS zona,
       ROUND(AVG(CASE WHEN t.eh_horario_pico = 1 THEN f.atraso_minutos END), 1) AS atraso_medio_pico,
       ROUND(AVG(CASE WHEN t.eh_horario_pico = 0 THEN f.atraso_minutos END), 1) AS atraso_medio_fora_pico,
       ROUND(100.0 * SUM(CASE WHEN t.eh_horario_pico = 1 THEN f.flag_atraso END)
                   / SUM(CASE WHEN t.eh_horario_pico = 1 THEN 1 END), 1)       AS pct_atrasadas_pico
FROM fato_viagens_transporte f
JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo_partida
JOIN dim_linha l ON l.sk_linha = f.sk_linha
WHERE t.ano = 2026 AND t.trimestre = 3
GROUP BY l.codigo_linha, l.zona_urbana
ORDER BY atraso_medio_pico DESC;

-- @consulta T2
-- @titulo Linhas com superlotação sistemática (ago-out/2026)
-- @enunciado Quais linhas e períodos do dia apresentaram superlotação em pelo menos 15% das viagens nos últimos três meses e, portanto, precisam de reforço de frota? Estimar quantas viagens extras por dia seriam necessárias para absorver o excedente.
-- @grafico barra x=linha_periodo y=pct_superlotadas
SELECT l.codigo_linha || ' · ' || t.periodo_dia                     AS linha_periodo,
       l.codigo_linha                                             AS linha,
       t.periodo_dia,
       COUNT(*)                                                   AS viagens,
       ROUND(100.0 * AVG(f.flag_superlotacao), 1)                 AS pct_superlotadas,
       ROUND(100.0 * AVG(f.taxa_ocupacao), 1)                     AS ocupacao_media_pct,
       -- excedente médio diário de passageiros acima da capacidade / capacidade média
       ROUND(SUM(MAX(f.lotacao_maxima - f.capacidade_ofertada, 0)) * 1.0
             / COUNT(DISTINCT t.data_completa) / AVG(f.capacidade_ofertada), 1) AS viagens_extras_dia
FROM fato_viagens_transporte f
JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo_partida
JOIN dim_linha l ON l.sk_linha = f.sk_linha
WHERE t.data_completa BETWEEN '2026-08-01' AND '2026-10-31'
  AND t.eh_final_semana = 0
GROUP BY l.codigo_linha, t.periodo_dia
HAVING pct_superlotadas >= 15
ORDER BY pct_superlotadas DESC;

-- @consulta T3
-- @titulo Percentual de passageiros com tarifa subsidiada por zona (3º tri/2026)
-- @enunciado Qual é o percentual de passageiros que utilizam tarifas subsidiadas (estudantes, idosos e PcD) em cada zona urbana de embarque no último trimestre, e quanto isso representa em renúncia tarifária?
-- @grafico barra x=zona y=pct_subsidiados
SELECT lo.zona_urbana                                                       AS zona,
       SUM(b.quantidade_passageiros)                                        AS passageiros,
       SUM(CASE WHEN ta.eh_subsidiada = 1 THEN b.quantidade_passageiros END) AS subsidiados,
       ROUND(100.0 * SUM(CASE WHEN ta.eh_subsidiada = 1 THEN b.quantidade_passageiros END)
                   / SUM(b.quantidade_passageiros), 1)                      AS pct_subsidiados,
       ROUND(100.0 * SUM(CASE WHEN ta.tipo_tarifa LIKE 'Estudante%' THEN b.quantidade_passageiros END)
                   / SUM(b.quantidade_passageiros), 1)                      AS pct_estudantes,
       ROUND(100.0 * SUM(CASE WHEN ta.tipo_tarifa LIKE 'Idoso%' THEN b.quantidade_passageiros END)
                   / SUM(b.quantidade_passageiros), 1)                      AS pct_idosos,
       ROUND(SUM(b.valor_subsidio), 2)                                      AS renuncia_rs
FROM fato_bilhetagem b
JOIN dim_tempo t        ON t.sk_tempo        = b.sk_tempo_partida
JOIN dim_tarifa ta      ON ta.sk_tarifa      = b.sk_tarifa
JOIN dim_localizacao lo ON lo.sk_localizacao = b.sk_localizacao_partida
WHERE t.ano = 2026 AND t.trimestre = 3
GROUP BY lo.zona_urbana
ORDER BY pct_subsidiados DESC;

-- @consulta T4
-- @titulo Desempenho mensal das concessionárias em 2026
-- @enunciado Como evoluiu, mês a mês em 2026, o percentual de viagens pontuais de cada empresa concessionária, junto com o atraso médio e a taxa de superlotação, para a fiscalização do contrato de concessão?
-- @grafico linha x=mes y=pct_pontual cor=empresa
SELECT printf('%04d-%02d', t.ano, t.mes)                   AS mes,
       v.empresa_concessionaria                           AS empresa,
       COUNT(*)                                           AS viagens,
       ROUND(100.0 * (1 - AVG(f.flag_atraso)), 1)         AS pct_pontual,
       ROUND(AVG(f.atraso_minutos), 1)                    AS atraso_medio_min,
       ROUND(100.0 * AVG(f.flag_superlotacao), 1)         AS pct_superlotadas
FROM fato_viagens_transporte f
JOIN dim_tempo t   ON t.sk_tempo   = f.sk_tempo_partida
JOIN dim_veiculo v ON v.sk_veiculo = f.sk_veiculo
WHERE t.ano = 2026
GROUP BY t.ano, t.mes, v.empresa_concessionaria
ORDER BY mes, empresa;

-- @consulta T5
-- @titulo Demanda no período letivo x férias escolares (últimos 12 meses)
-- @enunciado Qual é a média diária de passageiros em dias úteis por zona da linha no período letivo e nas férias escolares (jan, jul, dez), nos últimos 12 meses, para ajustar o quadro de horários sazonalmente?
-- @grafico barra x=zona y=passageiros_dia cor=periodo_escolar
SELECT l.zona_urbana                                                   AS zona,
       t.periodo_escolar,
       COUNT(DISTINCT t.data_completa)                                 AS dias_uteis,
       ROUND(SUM(f.total_passageiros) * 1.0 / COUNT(DISTINCT t.data_completa), 0) AS passageiros_dia,
       ROUND(100.0 * AVG(f.taxa_ocupacao), 1)                          AS ocupacao_media_pct
FROM fato_viagens_transporte f
JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo_partida
JOIN dim_linha l ON l.sk_linha = f.sk_linha
WHERE t.data_completa BETWEEN '2025-11-01' AND '2026-10-31'
  AND t.eh_final_semana = 0
GROUP BY l.zona_urbana, t.periodo_escolar
ORDER BY zona, t.periodo_escolar DESC;
