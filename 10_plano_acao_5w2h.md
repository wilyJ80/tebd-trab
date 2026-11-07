# 10. Plano de Ação (5W2H)

O plano parte dos achados da mineração de dados (item 6) e dos dashboards (itens 7 a 9). Cada ação responde a um problema medido e tem um indicador de acompanhamento que já existe no Data Warehouse. Assim, o mesmo dashboard que apontou o problema mostra se a ação funcionou.

> Os valores de custo são **estimativas de ordem de grandeza** para fins acadêmicos e devem ser confirmados com cotações e com o orçamento municipal. Os dados que embasam o diagnóstico são sintéticos.

## 10.1. Diagnóstico que orienta o plano

| # | Achado | Evidência |
| :--- | :--- | :--- |
| D1 | O **Subúrbio** tem o pior serviço: 53,6% das viagens atrasam mais de 10 min, a viagem média dura 72 min e a frota tem em média 14,2 anos, com **0% de km elétricos**. | E5, T1, mineração |
| D2 | A emissão por km **caiu 76% na Orla** (1,37 → 0,33 kg CO₂/km de 2022 a 2026), mas **não caiu no Subúrbio** (1,53 → 1,54). A transição energética está concentrada na região mais rica. | E1, E2 |
| D3 | **Superlotação crescente**: passou de 8,0% para 13,2% das viagens (2022 → 2026), porque a demanda cresceu 19,6% sem aumento de viagens. No pico, a L201 Cajazeiras-Lapa superlota em mais de 90% das viagens. | E3, T2 |
| D4 | O **horário de pico** dobra a taxa de atraso (22,9% → 47,4%), e o **período chuvoso** (abr-jul) a eleva de 28,6% para 37,8%. | Mineração, T4 |
| D5 | A **pontualidade do sistema está estagnada** em cerca de 67-69% há cinco anos. | E3 |
| D6 | **34%** dos passageiros usam tarifa subsidiada (até 36,5% na periferia), e a renúncia tarifária somou **R$ 4,35 milhões** de jan a out/2026. | T3, E4 |

## 10.2. Quadro 5W2H

| # | **What** (O quê) | **Why** (Por quê) | **Where** (Onde) | **When** (Quando) | **Who** (Quem) | **How** (Como) | **How much** (Quanto) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| A1 | Substituir os 15 ônibus a diesel mais antigos do Subúrbio por ônibus elétricos (1ª fase) | D1, D2: frota mais velha, mais atrasos e mais CO₂/km na região mais vulnerável | Linhas L301 a L305 (Paripe, Periperi, Plataforma, Fazenda Coutos) | Licitação no 1º sem/2027; operação até dez/2027 | SEMOB (gestão do contrato) + concessionária do Subúrbio | Aditivo contratual com meta de eletrificação; financiamento federal (ex.: Novo PAC / BNDES); eletropostos na garagem | ≈ R$ 42 mi em veículos (15 × ≈ R$ 2,8 mi) + ≈ R$ 3 mi em recarga |
| A2 | Reforçar a frota nos picos das linhas com superlotação sistemática | D3: até 95% das viagens de pico superlotadas | L201, L202, L203, L206 e L301 | A partir de jan/2027 (período letivo) | SEMOB (programação) + concessionárias | Inserir de 1 a 2 viagens extras por pico, conforme a coluna `viagens_extras_dia` da consulta T2; usar veículos da reserva técnica | ≈ R$ 35 mil/mês (≈ 3.300 km extras × ≈ R$ 10/km) |
| A3 | Implantar faixas exclusivas de ônibus nos corredores críticos | D1, D4: o atraso no pico é estrutural (trânsito), não só da frota | Av. Afrânio Peixoto (Suburbana) e eixos de acesso do Miolo ao Centro, ≈ 12 km | Projeto até mar/2027; implantação até ago/2027 | SEMOB + Transalvador | Sinalização horizontal e vertical, fiscalização eletrônica, semáforos com prioridade ao ônibus | ≈ R$ 3 mi (≈ R$ 250 mil/km) |
| A4 | Plano de contingência para o período chuvoso | D4: +9 pontos percentuais de atraso entre abril e julho | Toda a rede, com prioridade para Subúrbio e Miolo | Vigente todo ano de abr a jul, a partir de abr/2027 | CCO da SEMOB + Codesal (Defesa Civil) | Quadro de horários de chuva com tempo de ciclo 15% maior; desvios pré-definidos para pontos de alagamento; alertas no app | ≈ R$ 0 adicional (reorganização da programação) |
| A5 | Alerta preditivo de atraso no Centro de Controle Operacional | Mineração: o modelo identifica 2 de cada 3 atrasos com antecedência | CCO da SEMOB | Piloto em fev/2027; produção em jun/2027 | Equipe de TI/dados da SEMOB + universidade parceira (UNEB) | Rodar a árvore de decisão toda semana sobre a programação; listar viagens de alto risco e alocar nelas os veículos mais novos | ≈ R$ 80 mil (desenvolvimento e integração) |
| A6 | Incluir metas de desempenho nos contratos de concessão | D5: pontualidade estagnada e sem incentivo de melhoria | Contratos das 3 concessionárias | Revisão contratual até jul/2027 | SEMOB + Procuradoria do Município | Meta de pontualidade ≥ 80% e superlotação ≤ 5%, aferidas mensalmente pela consulta T4; bônus e penalidades na remuneração | Custo administrativo |
| A7 | Publicar o painel em dados abertos e prestar contas da política de gratuidade | D6: R$ 4,35 mi/ano de renúncia tarifária sem visibilidade para a população | Portal de transparência da Prefeitura | A partir de mar/2027, com atualização mensal | SEMOB + Controladoria | Publicar os indicadores táticos e estratégicos e o custo da gratuidade por zona (consultas T3 e E4) | ≈ R$ 20 mil (hospedagem e manutenção/ano) |

## 10.3. Priorização

| Ação | Impacto | Esforço/custo | Prazo | Prioridade |
| :--- | :--- | :--- | :--- | :--- |
| A2 Reforço nos picos | Alto (superlotação) | Baixo | Curto | **1** |
| A4 Contingência de chuva | Médio | Muito baixo | Curto | **2** |
| A5 Alerta preditivo | Médio | Baixo | Curto | **3** |
| A6 Metas contratuais | Alto (estrutural) | Baixo | Médio | **4** |
| A3 Faixas exclusivas | Alto (atraso) | Médio | Médio | **5** |
| A1 Eletrificação do Subúrbio | Muito alto (atraso, CO₂ e equidade) | Alto | Longo | **6** (iniciar já a captação de recursos) |
| A7 Dados abertos | Médio (transparência) | Muito baixo | Curto | Contínua |

## 10.4. Indicadores de acompanhamento (metas para dez/2027)

| Indicador | Situação 2026 | Meta | Consulta de acompanhamento |
| :--- | ---: | ---: | :--- |
| % de viagens pontuais (atraso ≤ 10 min), sistema | 68,7% | ≥ 80% | E3 / T4 |
| % de viagens atrasadas no Subúrbio | 53,6% | ≤ 35% | E5 / T1 |
| % de viagens superlotadas, sistema | 13,2% | ≤ 5% | E3 / T2 |
| kg CO₂ por km no Subúrbio | 1,54 | ≤ 1,00 | E1 |
| % de km rodados por veículos elétricos (sistema) | 35,8% | ≥ 50% | E2 |
| Idade média da frota do Subúrbio | 14,2 anos | ≤ 9 anos | E5 |

## 10.5. Alinhamento com a ODS 11

- **Meta 11.2** (transporte seguro, acessível e sustentável para todos, com atenção às pessoas em situação vulnerável): A1, A2, A3 e A6 atacam a pior qualidade do serviço justamente nas zonas periféricas.
- **Meta 11.6** (reduzir o impacto ambiental das cidades): A1 reduz emissões onde elas não estão caindo.
- **Meta 11.3** (planejamento participativo e integrado): A5 e A7 baseiam o planejamento em dados e os tornam públicos.
- Conexões secundárias: **ODS 13** (ação climática), com A1; **ODS 9** (infraestrutura e inovação), com A3 e A5; **ODS 3** (saúde), com a redução de poluentes locais pela A1.
