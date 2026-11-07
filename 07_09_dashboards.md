# 7, 8 e 9. Dashboards Operacional, Tático e Estratégico

> Gerado automaticamente por `src/tebd_trab/dashboard.py` a partir de `consultas/*.sql`. Dashboard interativo: `dashboard/index.html`.

> Dados sintéticos (ver `src/tebd_trab/gerar_dados.py`). Resultados limitados às primeiras linhas.

## 7. Dashboard Operacional

*Centro de Controle Operacional · o que está acontecendo hoje (dados de 06/11/2026, banco OLTP)* — consultas em `consultas/01_operacional.sql`.

### O1 — Viagens com atraso crítico hoje

**Enunciado:** Listar as viagens de hoje que partiram com mais de 20 minutos de atraso, com linha, veículo, horário previsto e real, para que o Centro de Controle Operacional acione a fiscalização e informe os passageiros.

```sql
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
```

**Resultado** (21 linhas):

| linha | nome_linha | veiculo | combustivel | partida_prevista | partida_real | atraso_minutos |
|---|---|---|---|---|---|---|
| L301 | Paripe - Comércio | 30086 | Diesel | 08:00:00 | 09:02:00 | 62 |
| L204 | Cabula - Barris | 20069 | Diesel | 08:12:00 | 08:54:00 | 42 |
| L302 | Periperi - Lapa | 30112 | Diesel | 15:56:00 | 16:32:00 | 36 |
| L301 | Paripe - Comércio | 30176 | Híbrido | 08:17:00 | 08:51:00 | 34 |
| L205 | Tancredo Neves - Caminho das Árvores | 20056 | Diesel | 18:17:00 | 18:49:00 | 32 |
| L303 | Plataforma - Campo Grande | 30118 | Diesel | 20:19:00 | 20:49:00 | 30 |
| L203 | Pau da Lima - Pituba | 20066 | Diesel | 05:59:00 | 06:28:00 | 29 |
| L305 | Paripe - Caminho das Árvores (Expresso) | 30099 | Diesel | 21:18:00 | 21:47:00 | 29 |
| L303 | Plataforma - Campo Grande | 30120 | Diesel | 08:56:00 | 09:24:00 | 28 |
| L201 | Cajazeiras - Lapa | 20058 | Diesel | 08:08:00 | 08:35:00 | 27 |
| L302 | Periperi - Lapa | 30088 | Diesel | 13:30:00 | 13:57:00 | 27 |
| L205 | Tancredo Neves - Caminho das Árvores | 20159 | Híbrido | 07:15:00 | 07:41:00 | 26 |
| L201 | Cajazeiras - Lapa | 20172 | Elétrico | 08:12:00 | 08:38:00 | 26 |
| L204 | Cabula - Barris | 20072 | Diesel | 18:37:00 | 19:03:00 | 26 |
| L104 | Rio Vermelho - Campo Grande | 10126 | Elétrico | 07:06:00 | 07:30:00 | 24 |
| L205 | Tancredo Neves - Caminho das Árvores | 20072 | Diesel | 07:35:00 | 07:59:00 | 24 |
| L305 | Paripe - Caminho das Árvores (Expresso) | 30119 | Diesel | 07:42:00 | 08:06:00 | 24 |
| L304 | Fazenda Coutos - Lobato | 30120 | Diesel | 12:52:00 | 13:16:00 | 24 |
| L303 | Plataforma - Campo Grande | 30093 | Diesel | 07:57:00 | 08:20:00 | 23 |
| L302 | Periperi - Lapa | 30108 | Diesel | 06:01:00 | 06:23:00 | 22 |

### O2 — Viagens superlotadas hoje

**Enunciado:** Identificar as viagens de hoje em que a lotação máxima a bordo superou a capacidade do veículo, mostrando o percentual de ocupação, para remanejar veículos ainda no mesmo dia.

```sql
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
```

**Resultado** (34 linhas):

| linha | horario | veiculo | capacidade | lotacao_maxima | ocupacao_pct |
|---|---|---|---|---|---|
| L201 | 17:46:00 | 20077 | 70 | 148 | 211,4 |
| L301 | 08:00:00 | 30086 | 90 | 147 | 163,3 |
| L301 | 08:17:00 | 30176 | 90 | 146 | 162,2 |
| L201 | 08:08:00 | 20058 | 80 | 128 | 160 |
| L202 | 17:23:00 | 20077 | 70 | 105 | 150 |
| L301 | 18:09:00 | 30175 | 90 | 134 | 148,9 |
| L301 | 08:04:00 | 30101 | 90 | 133 | 147,8 |
| L101 | 17:54:00 | 10139 | 80 | 118 | 147,5 |
| L205 | 07:35:00 | 20072 | 70 | 103 | 147,1 |
| L202 | 08:41:00 | 20159 | 80 | 113 | 141,3 |
| L205 | 18:17:00 | 20056 | 90 | 127 | 141,1 |
| L103 | 08:17:00 | 10036 | 80 | 111 | 138,8 |
| L203 | 18:59:00 | 20058 | 80 | 110 | 137,5 |
| L201 | 08:12:00 | 20172 | 80 | 106 | 132,5 |
| L204 | 08:12:00 | 20069 | 70 | 88 | 125,7 |
| L202 | 18:50:00 | 20056 | 90 | 113 | 125,6 |
| L204 | 07:35:00 | 20172 | 80 | 100 | 125 |
| L302 | 18:35:00 | 30107 | 80 | 98 | 122,5 |
| L305 | 08:22:00 | 30093 | 80 | 97 | 121,3 |
| L203 | 07:53:00 | 20070 | 80 | 95 | 118,8 |

### O3 — Pontualidade de cada linha hoje

**Enunciado:** Para cada linha, mostrar quantas viagens foram feitas hoje, o atraso médio e o percentual de viagens pontuais (atraso de até 10 min), ordenando da pior para a melhor.

```sql
SELECT l.codigo_linha                                         AS linha,
       COUNT(*)                                               AS viagens,
       ROUND(AVG(v.atraso_minutos), 1)                        AS atraso_medio_min,
       ROUND(100.0 * SUM(v.atraso_minutos <= 10) / COUNT(*), 1) AS pct_pontual
FROM viagens_diarias v
JOIN linhas l ON l.id_linha = v.id_linha
WHERE date(v.data_hora_partida_prevista) = (SELECT MAX(date(data_hora_partida_prevista)) FROM viagens_diarias)
GROUP BY l.codigo_linha
ORDER BY pct_pontual ASC, atraso_medio_min DESC;
```

**Resultado** (18 linhas):

| linha | viagens | atraso_medio_min | pct_pontual |
|---|---|---|---|
| L303 | 9 | 17,9 | 22,2 |
| L305 | 7 | 15,4 | 28,6 |
| L302 | 9 | 16,7 | 33,3 |
| L301 | 10 | 18,1 | 40 |
| L205 | 9 | 13 | 55,6 |
| L203 | 10 | 11,7 | 60 |
| L206 | 10 | 10,7 | 60 |
| L304 | 8 | 9,8 | 62,5 |
| L204 | 9 | 11,4 | 66,7 |
| L202 | 10 | 8,8 | 70 |
| L101 | 11 | 7,1 | 72,7 |
| L201 | 12 | 9,6 | 75 |
| L104 | 9 | 6 | 88,9 |
| L107 | 9 | 4,7 | 88,9 |
| L103 | 9 | 5,9 | 100 |
| L106 | 10 | 5,1 | 100 |
| L105 | 8 | 4,6 | 100 |
| L102 | 10 | 4 | 100 |

### O4 — Passageiros e arrecadação hoje por tipo de tarifa

**Enunciado:** Totalizar, para o dia de hoje, o número de validações e o valor arrecadado por tipo de tarifa, para o fechamento de caixa diário da bilhetagem.

```sql
SELECT t.descricao                         AS tipo_tarifa,
       SUM(b.quantidade_validacoes)        AS passageiros,
       ROUND(SUM(b.valor_arrecadado), 2)   AS arrecadado_rs
FROM validacoes_bilhetagem b
JOIN tipos_tarifa t    ON t.id_tipo_tarifa = b.id_tipo_tarifa
JOIN viagens_diarias v ON v.id_viagem      = b.id_viagem
WHERE date(v.data_hora_partida_prevista) = (SELECT MAX(date(data_hora_partida_prevista)) FROM viagens_diarias)
GROUP BY t.id_tipo_tarifa
ORDER BY passageiros DESC;
```

**Resultado** (5 linhas):

| tipo_tarifa | passageiros | arrecadado_rs |
|---|---|---|
| Inteira | 4.296 | 23.853,2 |
| Vale-Transporte | 3.388 | 18.915,4 |
| Estudante (Meia) | 2.533 | 6.981,8 |
| Idoso (Gratuidade) | 1.656 | 0 |
| Pessoa com Deficiência (Gratuidade) | 574 | 0 |

### O5 — Utilização da frota hoje por empresa

**Enunciado:** Para cada empresa e tipo de combustível, mostrar quantos veículos rodaram hoje, quantas viagens e quantos km fizeram e quanto CO₂ emitiram, para controle diário da escala de frota.

```sql
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
```

**Resultado** (8 linhas):

| empresa | combustivel | veiculos_em_operacao | viagens | km_rodados | co2_kg |
|---|---|---|---|---|---|
| Consórcio Miolo Integrado | Diesel | 16 | 34 | 468,7 | 694,9 |
| Consórcio Miolo Integrado | Elétrico | 7 | 15 | 206,8 | 20,8 |
| Consórcio Miolo Integrado | Híbrido | 4 | 8 | 124,1 | 108,6 |
| Consórcio Miolo Integrado | GNV | 2 | 3 | 36,7 | 44,6 |
| Transportes Enseada do Subúrbio | Diesel | 23 | 40 | 858,3 | 1.374,2 |
| Transportes Enseada do Subúrbio | Híbrido | 2 | 3 | 64,9 | 56 |
| Viação Brisa do Mar | Elétrico | 31 | 56 | 821,2 | 84,1 |
| Viação Brisa do Mar | Diesel | 6 | 10 | 110,1 | 154,2 |

## 8. Dashboard Tático

*Gerência de operações · desempenho por linha, zona e empresa em meses/trimestres (Data Warehouse)* — consultas em `consultas/02_tatico.sql`.

### T1 — Ranking de pontualidade no horário de pico (3º trimestre/2026)

**Enunciado:** Qual é o atraso médio por linha nos horários de pico (7h-9h e 17h-19h) no último trimestre fechado, comparado com o atraso fora do pico? Ordenar da linha com pior desempenho no pico para a melhor.

```sql
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
```

**Resultado** (18 linhas):

| linha | zona | atraso_medio_pico | atraso_medio_fora_pico | pct_atrasadas_pico |
|---|---|---|---|---|
| L302 | Subúrbio | 19,4 | 10,9 | 65,3 |
| L301 | Subúrbio | 19,3 | 11,4 | 69,8 |
| L303 | Subúrbio | 19,3 | 12,2 | 69,3 |
| L305 | Subúrbio | 18,9 | 11,9 | 67,5 |
| L304 | Subúrbio | 17,8 | 11,3 | 65,4 |
| L202 | Miolo | 15,1 | 7,8 | 57,3 |
| L201 | Miolo | 14,7 | 7,7 | 55,6 |
| L205 | Miolo | 13,8 | 7,9 | 49 |
| L204 | Miolo | 13,5 | 7,3 | 53 |
| L203 | Miolo | 13,4 | 7,9 | 50,9 |
| L206 | Miolo | 13,4 | 7,5 | 54,3 |
| L103 | Orla | 8,6 | 4,3 | 31,2 |
| L102 | Orla | 8,3 | 4,2 | 27,9 |
| L101 | Orla | 8,2 | 4,2 | 28,6 |
| L104 | Orla | 8,1 | 4,4 | 27 |
| L105 | Orla | 8 | 4,5 | 26 |
| L106 | Orla | 7,7 | 4,1 | 25,6 |
| L107 | Orla | 7,4 | 4 | 23 |

### T2 — Linhas com superlotação sistemática (ago-out/2026)

**Enunciado:** Quais linhas e períodos do dia apresentaram superlotação em pelo menos 15% das viagens nos últimos três meses e, portanto, precisam de reforço de frota? Estimar quantas viagens extras por dia seriam necessárias para absorver o excedente.

```sql
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
```

**Resultado** (28 linhas):

| linha_periodo | linha | periodo_dia | viagens | pct_superlotadas | ocupacao_media_pct | viagens_extras_dia |
|---|---|---|---|---|---|---|
| L201 · Pico Manhã | L201 | Pico Manhã | 136 | 95,6 | 149,2 | 1,2 |
| L201 · Pico Tarde | L201 | Pico Tarde | 153 | 90,2 | 149,6 | 1,2 |
| L202 · Pico Manhã | L202 | Pico Manhã | 118 | 79,7 | 124,6 | 0,5 |
| L203 · Pico Tarde | L203 | Pico Tarde | 104 | 76 | 123 | 0,5 |
| L301 · Pico Tarde | L301 | Pico Tarde | 131 | 75,6 | 122,2 | 0,5 |
| L203 · Pico Manhã | L203 | Pico Manhã | 115 | 73 | 119,8 | 0,5 |
| L301 · Pico Manhã | L301 | Pico Manhã | 106 | 72,6 | 121,8 | 0,5 |
| L202 · Pico Tarde | L202 | Pico Tarde | 121 | 71,9 | 122,4 | 0,6 |
| L206 · Pico Tarde | L206 | Pico Tarde | 114 | 71,9 | 118,5 | 0,4 |
| L206 · Pico Manhã | L206 | Pico Manhã | 100 | 69 | 116,2 | 0,4 |
| L302 · Pico Tarde | L302 | Pico Tarde | 100 | 65 | 109,9 | 0,3 |
| L302 · Pico Manhã | L302 | Pico Manhã | 114 | 64 | 114,4 | 0,4 |
| L103 · Pico Manhã | L103 | Pico Manhã | 105 | 62,9 | 109,8 | 0,3 |
| L204 · Pico Manhã | L204 | Pico Manhã | 96 | 60,4 | 107 | 0,2 |
| L103 · Pico Tarde | L103 | Pico Tarde | 116 | 57,8 | 106,7 | 0,3 |
| L303 · Pico Tarde | L303 | Pico Tarde | 112 | 50 | 104,8 | 0,2 |
| L204 · Pico Tarde | L204 | Pico Tarde | 107 | 48,6 | 102,2 | 0,2 |
| L303 · Pico Manhã | L303 | Pico Manhã | 107 | 48,6 | 103 | 0,2 |
| L101 · Pico Tarde | L101 | Pico Tarde | 130 | 41,5 | 99 | 0,2 |
| L101 · Pico Manhã | L101 | Pico Manhã | 129 | 40,3 | 98,7 | 0,2 |

### T3 — Percentual de passageiros com tarifa subsidiada por zona (3º tri/2026)

**Enunciado:** Qual é o percentual de passageiros que utilizam tarifas subsidiadas (estudantes, idosos e PcD) em cada zona urbana de embarque no último trimestre, e quanto isso representa em renúncia tarifária?

```sql
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
```

**Resultado** (4 linhas):

| zona | passageiros | subsidiados | pct_subsidiados | pct_estudantes | pct_idosos | renuncia_rs |
|---|---|---|---|---|---|---|
| Subúrbio | 125.821 | 45.876 | 36,5 | 14,5 | 16,4 | 188.080,9 |
| Miolo | 181.451 | 65.886 | 36,3 | 14,6 | 16,3 | 278.804,4 |
| Centro | 339.024 | 109.843 | 32,4 | 13,7 | 14,1 | 497.745,5 |
| Orla | 233.978 | 68.075 | 29,1 | 12,6 | 12,6 | 299.479,6 |

### T4 — Desempenho mensal das concessionárias em 2026

**Enunciado:** Como evoluiu, mês a mês em 2026, o percentual de viagens pontuais de cada empresa concessionária, junto com o atraso médio e a taxa de superlotação, para a fiscalização do contrato de concessão?

```sql
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
```

**Resultado** (33 linhas):

| mes | empresa | viagens | pct_pontual | atraso_medio_min | pct_superlotadas |
|---|---|---|---|---|---|
| 2026-01 | Consórcio Miolo Integrado | 1.635 | 68,4 | 9,4 | 13,1 |
| 2026-01 | Transportes Enseada do Subúrbio | 1.171 | 48,4 | 13,5 | 6,5 |
| 2026-01 | Viação Brisa do Mar | 1.803 | 89,4 | 5,4 | 2,5 |
| 2026-02 | Consórcio Miolo Integrado | 1.480 | 63,9 | 9,9 | 24,6 |
| 2026-02 | Transportes Enseada do Subúrbio | 1.060 | 49,2 | 13,6 | 14 |
| 2026-02 | Viação Brisa do Mar | 1.632 | 89,8 | 5,1 | 7,7 |
| 2026-03 | Consórcio Miolo Integrado | 1.635 | 69,7 | 9,4 | 22,9 |
| 2026-03 | Transportes Enseada do Subúrbio | 1.171 | 50,6 | 13,1 | 13,6 |
| 2026-03 | Viação Brisa do Mar | 1.803 | 90,9 | 5,1 | 7,3 |
| 2026-04 | Consórcio Miolo Integrado | 1.600 | 57,9 | 11,9 | 23,4 |
| 2026-04 | Transportes Enseada do Subúrbio | 1.146 | 39,5 | 16,6 | 14 |
| 2026-04 | Viação Brisa do Mar | 1.764 | 81,1 | 6,8 | 7,8 |
| 2026-05 | Consórcio Miolo Integrado | 1.610 | 58,7 | 11,4 | 22,7 |
| 2026-05 | Transportes Enseada do Subúrbio | 1.153 | 42,6 | 16 | 14,2 |
| 2026-05 | Viação Brisa do Mar | 1.776 | 83,2 | 6,5 | 6,4 |
| 2026-06 | Consórcio Miolo Integrado | 1.600 | 57,3 | 11,8 | 22,8 |
| 2026-06 | Transportes Enseada do Subúrbio | 1.146 | 41,9 | 16,3 | 14,9 |
| 2026-06 | Viação Brisa do Mar | 1.764 | 82,1 | 6,7 | 7,4 |
| 2026-07 | Consórcio Miolo Integrado | 1.660 | 59,8 | 11,2 | 14 |
| 2026-07 | Transportes Enseada do Subúrbio | 1.189 | 41,6 | 16,2 | 8,3 |

### T5 — Demanda no período letivo x férias escolares (últimos 12 meses)

**Enunciado:** Qual é a média diária de passageiros em dias úteis por zona da linha no período letivo e nas férias escolares (jan, jul, dez), nos últimos 12 meses, para ajustar o quadro de horários sazonalmente?

```sql
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
```

**Resultado** (6 linhas):

| zona | periodo_escolar | dias_uteis | passageiros_dia | ocupacao_media_pct |
|---|---|---|---|---|
| Miolo | Letivo | 192 | 5.079 | 82 |
| Miolo | Férias | 68 | 4.283 | 69,2 |
| Orla | Letivo | 192 | 4.053 | 57,9 |
| Orla | Férias | 68 | 3.420 | 48,9 |
| Subúrbio | Letivo | 192 | 3.070 | 68,9 |
| Subúrbio | Férias | 68 | 2.623 | 58,8 |

## 9. Dashboard Estratégico

*Prefeitura · tendências de 2022 a 2026 ligadas à ODS 11 (Data Warehouse)* — consultas em `consultas/03_estrategico.sql`.

### E1 — Emissão de CO₂ por km rodado, por zona urbana e ano

**Enunciado:** Qual é a emissão média de carbono por quilômetro rodado (kg CO₂/km) nas diferentes zonas urbanas, ano a ano, para acompanhar a meta de descarbonização do transporte público?

```sql
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
```

**Resultado** (15 linhas):

| ano | zona | km_rodados | co2_toneladas | kg_co2_por_km |
|---|---|---|---|---|
| 2022 | Miolo | 224.253 | 315,9 | 1,409 |
| 2022 | Orla | 251.036 | 344,8 | 1,374 |
| 2022 | Subúrbio | 246.156 | 376,3 | 1,529 |
| 2023 | Miolo | 224.550 | 320,4 | 1,427 |
| 2023 | Orla | 251.264 | 301 | 1,198 |
| 2023 | Subúrbio | 246.410 | 381,4 | 1,548 |
| 2024 | Miolo | 225.775 | 316,8 | 1,403 |
| 2024 | Orla | 252.714 | 227,2 | 0,899 |
| 2024 | Subúrbio | 247.872 | 388,7 | 1,568 |
| 2025 | Miolo | 224.916 | 295,6 | 1,314 |
| 2025 | Orla | 251.710 | 139,5 | 0,554 |
| 2025 | Subúrbio | 246.947 | 388,6 | 1,573 |
| 2026 | Miolo | 224.497 | 238,4 | 1,062 |
| 2026 | Orla | 251.294 | 82,9 | 0,33 |
| 2026 | Subúrbio | 246.512 | 379,2 | 1,538 |

### E2 — Transição energética da frota e CO₂ evitado

**Enunciado:** Qual a participação de cada matriz energética nos km rodados a cada ano e quantas toneladas de CO₂ foram evitadas em relação a um cenário em que todos esses km fossem rodados pela frota a diesel (usando a emissão média por km do diesel naquele ano)?

```sql
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
```

**Resultado** (17 linhas):

| ano | combustivel | km_rodados | pct_km | co2_evitado_ano_t |
|---|---|---|---|---|
| 2022 | Diesel | 676.119 | 93,7 | 12,9 |
| 2022 | GNV | 45.327 | 6,3 | 12,9 |
| 2023 | Diesel | 640.534 | 88,7 | 63 |
| 2023 | Elétrico | 36.272 | 5 | 63 |
| 2023 | GNV | 45.418 | 6,3 | 63 |
| 2024 | Diesel | 572.808 | 78,9 | 155,3 |
| 2024 | Elétrico | 95.335 | 13,1 | 155,3 |
| 2024 | GNV | 44.312 | 6,1 | 155,3 |
| 2024 | Híbrido | 13.906 | 1,9 | 155,3 |
| 2025 | Diesel | 474.783 | 65,6 | 279,5 |
| 2025 | Elétrico | 171.714 | 23,7 | 279,5 |
| 2025 | GNV | 44.748 | 6,2 | 279,5 |
| 2025 | Híbrido | 32.328 | 4,5 | 279,5 |
| 2026 | Diesel | 384.236 | 53,2 | 415,8 |
| 2026 | Elétrico | 258.614 | 35,8 | 415,8 |
| 2026 | GNV | 30.348 | 4,2 | 415,8 |
| 2026 | Híbrido | 49.105 | 6,8 | 415,8 |

### E3 — Evolução anual da demanda e da pontualidade

**Enunciado:** Como evoluíram ano a ano o total de passageiros transportados, a variação percentual em relação ao ano anterior e o índice de pontualidade do sistema (jan-out de cada ano)?

```sql
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
```

**Resultado** (5 linhas):

| ano | passageiros | viagens | variacao_passageiros_pct | pct_pontual | pct_superlotadas |
|---|---|---|---|---|---|
| 2022 | 2.479.725 | 45.216 | – | 68,3 | 8 |
| 2023 | 2.676.166 | 45.286 | 7,9 | 67,2 | 10,4 |
| 2024 | 2.841.067 | 45.525 | 6,2 | 66,8 | 12,1 |
| 2025 | 2.919.055 | 45.356 | 2,7 | 67,3 | 13,1 |
| 2026 | 2.965.714 | 45.286 | 1,6 | 68,7 | 13,2 |

### E4 — Receita tarifária x custo das gratuidades e descontos

**Enunciado:** Qual é, por ano, a receita tarifária arrecadada, o valor da renúncia tarifária com gratuidades e meia-passagem (custo da política social) e o peso dessa renúncia sobre a receita potencial?

```sql
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
```

**Resultado** (5 linhas):

| ano | receita_milhoes_rs | renuncia_milhoes_rs | pct_renuncia | pct_passageiros_subsidiados |
|---|---|---|---|---|
| 2022 | 10,15 | 3,64 | 26,4 | 34,5 |
| 2023 | 10,97 | 3,93 | 26,4 | 34,5 |
| 2024 | 11,64 | 4,17 | 26,4 | 34,4 |
| 2025 | 11,96 | 4,28 | 26,4 | 34,4 |
| 2026 | 12,15 | 4,35 | 26,3 | 34,4 |

### E5 — Equidade territorial do serviço (2026)

**Enunciado:** As zonas periféricas recebem um serviço pior? Comparar, por zona da linha em 2026, o tempo médio de viagem, a tarifa efetiva paga por km, a taxa de atraso, a taxa de superlotação, a idade média da frota e a participação de veículos elétricos.

```sql
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
```

**Resultado** (3 linhas):

| zona | tempo_medio_viagem_min | tarifa_por_km_rs | pct_atrasadas | pct_superlotadas | idade_media_frota | pct_km_eletrico |
|---|---|---|---|---|---|---|
| Subúrbio | 72 | 0,174 | 53,6 | 13,1 | 14,2 | 0 |
| Miolo | 48,9 | 0,256 | 35,3 | 21 | 6,4 | 23 |
| Orla | 44,6 | 0,323 | 13,1 | 6,4 | 2,2 | 82,5 |
