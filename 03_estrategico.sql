-- =====================================================================
-- DASHBOARD ESTRATÉGICO (nível estratégico: Prefeito, Secretário de Mobilidade, Câmara)
-- Banco: olap.db  ·  Horizonte: anos (2022-2026), indicadores ligados à ODS 11.
-- Para comparar anos de forma justa com 2026 (dados até 06/nov), as séries anuais
-- usam o acumulado de janeiro a outubro de cada ano.
-- =====================================================================

-- @consulta E1
-- @titulo Emissão de CO₂ por km rodado, por zona urbana e ano
-- @enunciado Qual é a emissão média de carbono por quilômetro rodado (kg CO₂/km) nas diferentes zonas urbanas, ano a ano, para acompanhar a meta de descarbonização do transporte público?
-- @grafico linha x=ano y=kg_co2_por_km cor=zona
SELECT t.ano,
       l.zona_urbana                                         AS zona,
       ROUND(SUM(f.distancia_km), 0)                         AS km_rodados,
       ROUND(SUM(f.emissao_co2_kg) / 1000, 1)                AS co2_toneladas,
       ROUND(SUM(f.emissao_co2_kg) / SUM(f.distancia_km), 3) AS kg_co2_por_km
FROM fato_viagens_transporte f
JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo_partida
JOIN dim_linha l ON l.sk_linha = f.sk_linha
WHERE t.mes <= 10
GROUP BY t.ano, l.zona_urbana
ORDER BY t.ano, zona;

-- @consulta E2
-- @titulo Transição energética da frota e CO₂ evitado
-- @enunciado Qual a participação de cada matriz energética nos km rodados a cada ano e quantas toneladas de CO₂ foram evitadas em relação a um cenário em que todos esses km fossem rodados pela frota a diesel (usando a emissão média por km do diesel naquele ano)?
-- @grafico barra_empilhada x=ano y=pct_km cor=combustivel
WITH km AS (
    SELECT t.ano, v.tipo_combustivel AS combustivel,
           SUM(f.distancia_km) AS km, SUM(f.emissao_co2_kg) AS co2
    FROM fato_viagens_transporte f
    JOIN dim_tempo t   ON t.sk_tempo   = f.sk_tempo_partida
    JOIN dim_veiculo v ON v.sk_veiculo = f.sk_veiculo
    WHERE t.mes <= 10
    GROUP BY t.ano, v.tipo_combustivel
),
fator_diesel AS (
    SELECT ano, co2 / km AS kg_km_diesel FROM km WHERE combustivel = 'Diesel'
)
SELECT k.ano,
       k.combustivel,
       ROUND(k.km, 0)                                                    AS km_rodados,
       ROUND(100.0 * k.km / SUM(k.km) OVER (PARTITION BY k.ano), 1)      AS pct_km,
       ROUND(SUM(k.km * d.kg_km_diesel - k.co2) OVER (PARTITION BY k.ano) / 1000, 1) AS co2_evitado_ano_t
FROM km k
JOIN fator_diesel d ON d.ano = k.ano
ORDER BY k.ano, k.combustivel;

-- @consulta E3
-- @titulo Evolução anual da demanda e da pontualidade
-- @enunciado Como evoluíram ano a ano o total de passageiros transportados, a variação percentual em relação ao ano anterior e o índice de pontualidade do sistema (jan-out de cada ano)?
-- @grafico linha x=ano y=pct_pontual
WITH anual AS (
    SELECT t.ano,
           SUM(f.total_passageiros)                   AS passageiros,
           COUNT(*)                                   AS viagens,
           ROUND(100.0 * (1 - AVG(f.flag_atraso)), 1) AS pct_pontual,
           ROUND(100.0 * AVG(f.flag_superlotacao), 1) AS pct_superlotadas
    FROM fato_viagens_transporte f
    JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo_partida
    WHERE t.mes <= 10
    GROUP BY t.ano
)
SELECT ano, passageiros, viagens,
       ROUND(100.0 * (passageiros - LAG(passageiros) OVER (ORDER BY ano))
             / LAG(passageiros) OVER (ORDER BY ano), 1) AS variacao_passageiros_pct,
       pct_pontual,
       pct_superlotadas
FROM anual
ORDER BY ano;

-- @consulta E4
-- @titulo Receita tarifária x custo das gratuidades e descontos
-- @enunciado Qual é, por ano, a receita tarifária arrecadada, o valor da renúncia tarifária com gratuidades e meia-passagem (custo da política social) e o peso dessa renúncia sobre a receita potencial?
-- @grafico barra x=ano y=renuncia_milhoes_rs
SELECT t.ano,
       ROUND(SUM(b.faturamento) / 1e6, 2)                                   AS receita_milhoes_rs,
       ROUND(SUM(b.valor_subsidio) / 1e6, 2)                                AS renuncia_milhoes_rs,
       ROUND(100.0 * SUM(b.valor_subsidio) / SUM(b.faturamento + b.valor_subsidio), 1) AS pct_renuncia,
       ROUND(100.0 * SUM(CASE WHEN ta.eh_subsidiada = 1 THEN b.quantidade_passageiros END)
                   / SUM(b.quantidade_passageiros), 1)                      AS pct_passageiros_subsidiados
FROM fato_bilhetagem b
JOIN dim_tempo t   ON t.sk_tempo   = b.sk_tempo_partida
JOIN dim_tarifa ta ON ta.sk_tarifa = b.sk_tarifa
WHERE t.mes <= 10
GROUP BY t.ano
ORDER BY t.ano;

-- @consulta E5
-- @titulo Equidade territorial do serviço (2026)
-- @enunciado As zonas periféricas recebem um serviço pior? Comparar, por zona da linha em 2026, o tempo médio de viagem, a tarifa efetiva paga por km, a taxa de atraso, a taxa de superlotação, a idade média da frota e a participação de veículos elétricos.
-- @grafico tabela
SELECT l.zona_urbana                                                        AS zona,
       ROUND(AVG(f.tempo_viagem_minutos), 1)                                AS tempo_medio_viagem_min,
       ROUND(SUM(f.faturamento_bruto) / SUM(f.total_passageiros * l.extensao_km), 3) AS tarifa_por_km_rs,
       ROUND(100.0 * AVG(f.flag_atraso), 1)                                 AS pct_atrasadas,
       ROUND(100.0 * AVG(f.flag_superlotacao), 1)                           AS pct_superlotadas,
       ROUND(AVG(t.ano - v.ano_fabricacao), 1)                              AS idade_media_frota,
       ROUND(100.0 * SUM(CASE WHEN v.tipo_combustivel = 'Elétrico' THEN f.distancia_km ELSE 0 END)
                   / SUM(f.distancia_km), 1)                                AS pct_km_eletrico
FROM fato_viagens_transporte f
JOIN dim_tempo t   ON t.sk_tempo   = f.sk_tempo_partida
JOIN dim_linha l   ON l.sk_linha   = f.sk_linha
JOIN dim_veiculo v ON v.sk_veiculo = f.sk_veiculo
WHERE t.ano = 2026
GROUP BY l.zona_urbana
ORDER BY pct_atrasadas DESC;
