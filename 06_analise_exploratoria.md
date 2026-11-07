# 6. Análise Exploratória de Dados e Mineração

> Script: `src/tebd_trab/mineracao.py` · Resultados brutos: `docs/figuras/resultados_mineracao.json`
>
> **Observação:** os dados são **sintéticos** (gerados por `src/tebd_trab/gerar_dados.py`) e simulam a rede de ônibus de Salvador entre jan/2022 e nov/2026. Os padrões encontrados foram embutidos na simulação de forma plausível; o objetivo é demonstrar o método, que funciona da mesma forma com dados reais de GPS e bilhetagem.

## 6.1. Definição do problema

**Pergunta de negócio:** *Quais viagens têm alto risco de sair com atraso relevante, e o que explica esse risco?*

O atraso é a principal reclamação do usuário de transporte público e afeta diretamente a Meta 11.2 da ODS 11 (transporte seguro, acessível e sustentável). Se a operação souber **antes** da viagem quais combinações de linha, horário, veículo e época do ano têm maior risco, ela pode agir preventivamente: reforçar a frota, trocar o veículo por um mais novo, ajustar o quadro de horários ou priorizar faixas exclusivas.

**Formulação como tarefa de mineração:** classificação binária supervisionada.

- **Variável-alvo:** `flag_atraso` = 1 se `atraso_minutos > 10` (tolerância adotada), 0 caso contrário.
- **Atributos preditores:** somente informações **conhecidas antes da viagem**: hora programada, horário de pico, fim de semana, período chuvoso, período escolar, zona da linha, tipo de serviço, extensão da linha, tipo de combustível e idade do veículo.
- **Excluídos de propósito:** lotação, tempo de viagem e emissão. Eles só são conhecidos **depois** da viagem e causariam vazamento de dados (*data leakage*).

## 6.2. Análise exploratória (EDA)

Base analisada: **263.879 viagens** extraídas do Data Warehouse (`fato_viagens_transporte` + dimensões).

| Indicador | Valor |
| :--- | ---: |
| Viagens com atraso > 10 min | **31,8%** |
| Taxa de atraso: fora do pico → no pico | 22,9% → **47,4%** |
| Taxa de atraso: período seco → chuvoso (abr-jul) | 28,6% → **37,8%** |
| Taxa de atraso: dia útil → fim de semana | 34,7% → 19,1% |
| Taxa de atraso: Orla / Miolo / Subúrbio | 14,3% / 36,5% / **52,1%** |
| Idade média da frota: Orla / Miolo / Subúrbio | 3,4 / 7,4 / **13,3 anos** |
| Taxa de atraso: Elétrico / Híbrido / GNV / Diesel | 12,4% / 27,8% / 28,7% / **36,7%** |

**Distribuição do atraso.** A distribuição é assimétrica à direita: a maioria das viagens sai com poucos minutos de atraso, mas há uma cauda longa de atrasos de 20 a 40 minutos.

![Distribuição do atraso](figuras/01_distribuicao_atraso.png)

**Horário e zona.** Os picos (7h-9h e 17h-19h) praticamente dobram o atraso médio em todas as zonas. O Subúrbio fica sistematicamente acima das outras zonas em qualquer horário.

![Atraso por hora e zona](figuras/02_atraso_hora_zona.png)

**Idade do veículo.** O atraso médio cresce com a idade do veículo. Isso é coerente com mais quebras e manutenção corretiva em ônibus antigos.

![Atraso por idade](figuras/03_atraso_idade_veiculo.png)

![Taxa de atraso por fator](figuras/04_taxa_atraso_fatores.png)

**Correlações com `atraso_minutos`.** Idade do veículo (0,34), taxa de ocupação (0,34), horário de pico (0,30), período chuvoso (0,12) e fim de semana (−0,15). Nenhuma correlação isolada é forte, o que indica que o atraso resulta da **combinação** de fatores. Um modelo de árvore captura bem esse tipo de interação.

![Correlação](figuras/05_correlacao.png)

## 6.3. Método: Árvore de Decisão (CART)

**Como funciona.** A árvore de decisão divide os dados em grupos cada vez mais homogêneos, fazendo perguntas do tipo "o atributo X é menor ou igual a v?". Em cada nó, o algoritmo CART (implementado no `scikit-learn`) testa todas as divisões possíveis e escolhe a que mais reduz a **impureza de Gini**:

$$Gini = 1 - \sum_{k} p_k^2$$

em que $p_k$ é a proporção de viagens da classe *k* no nó. Um nó só com viagens atrasadas tem Gini = 0 (puro). As folhas finais dão a classe prevista e a proporção de atrasos daquele grupo.

**Por que este método.**

1. **Interpretabilidade:** cada caminho da raiz até uma folha é uma regra "SE ... ENTÃO ..." que o gestor entende sem conhecer estatística. Isso é essencial para justificar uma decisão pública.
2. Lida com atributos numéricos e categóricos e com **interações não lineares** (por exemplo, pico *e* Subúrbio), sem precisar normalizar os dados.
3. Indica a **importância de cada atributo**, o que orienta onde investir.

**Configuração e validação.**

| Parâmetro | Valor | Motivo |
| :--- | :--- | :--- |
| `max_depth` | 4 | Árvore pequena, legível e menos sujeita a sobreajuste. |
| `min_samples_leaf` | 500 | Cada regra se apoia em pelo menos 500 viagens. |
| `class_weight` | `balanced` | Só 32% das viagens atrasam; sem balanceamento, o modelo tenderia a prever sempre "pontual". |
| Divisão treino/teste | **Temporal**: treino 2022-2025 (217.649 viagens), teste 2026 (46.230) | Simula o uso real: aprende com o passado e prevê o futuro. |

Categorias como zona e combustível foram transformadas em variáveis binárias (*one-hot encoding*).

## 6.4. Resultados

| Métrica (teste 2026) | Valor |
| :--- | ---: |
| Acurácia do modelo | **72,3%** |
| Acurácia de referência (sempre "pontual") | 68,7% |
| Precisão (classe "Atrasada") | 54,7% |
| Revocação (classe "Atrasada") | **66,3%** |
| F1 (classe "Atrasada") | 60,0% |
| AUC-ROC | **0,781** |

A acurácia pouco acima da referência não é a métrica que importa aqui: a referência nunca acerta um atraso. O modelo **identifica 2 de cada 3 viagens que vão atrasar** (revocação de 66%). O AUC de 0,78 indica boa capacidade de ordenar as viagens por risco. Para uso operacional (priorizar reforços), um falso alarme custa pouco e um atraso não previsto custa caro, então dar prioridade à revocação é uma escolha consciente.

![Matriz de confusão](figuras/08_matriz_confusao.png)

### A árvore obtida

![Árvore de decisão](figuras/06_arvore_decisao.png)

Principais regras extraídas (lidas da árvore; "% atrasadas" é a proporção na folha, ponderada pelo balanceamento de classes):

1. **SE** a linha **não é da Orla** **E** é **horário de pico** **E** é **dia útil** → **Atrasada** (76,5% no Miolo e 83,7% no Subúrbio). É o grupo mais crítico: Miolo e Subúrbio no pico dos dias úteis.
2. **SE** a linha é do **Subúrbio** **E** fora do pico **E** dia útil → **Atrasada** (64,9%). No Subúrbio, até o horário normal é problemático.
3. **SE** a linha é da **Orla** **E** pico **E** **período chuvoso** → **Atrasada** (59,2%). A chuva derruba a pontualidade mesmo na zona mais bem servida.
4. **SE** fim de semana no pico **E** veículo com **mais de 8 anos** → **Atrasada** (64,7%). Com o veículo mais novo, a mesma situação é classificada como pontual.
5. **SE** a linha é da **Orla** **E** fora do pico **E** veículo com **até 3 anos** → **Pontual** (apenas 5,0% a 13,7% de atrasos).

### Importância dos atributos

![Importância](figuras/07_importancia_atributos.png)

| Atributo | Importância |
| :--- | ---: |
| Zona = Orla | 0,489 |
| Horário de pico | 0,317 |
| Fim de semana | 0,097 |
| Zona = Subúrbio | 0,068 |
| Idade do veículo | 0,016 |
| Período chuvoso | 0,013 |

A zona da linha aparece como o fator mais importante, mas **zona e idade da frota estão fortemente associadas**: o Subúrbio roda com veículos de 13,3 anos em média, contra 3,4 na Orla. Parte do "efeito zona" é, na verdade, efeito da frota antiga e da infraestrutura viária pior da periferia. Essa é uma questão de **equidade** (inclusão social, ODS 11).

### Uso prático: risco previsto no pico de 2026

| Linha | Risco previsto (score) | Taxa real de atraso |
| :--- | ---: | ---: |
| L303 Plataforma - Campo Grande | 80,2 | 71,2% |
| L302 Periperi - Lapa | 79,9 | 68,4% |
| L305 Paripe - Caminho das Árvores | 79,9 | 68,4% |
| L304 Fazenda Coutos - Lobato | 79,8 | 65,5% |
| L301 Paripe - Comércio | 79,7 | 69,0% |

As cinco linhas de maior risco são todas do Subúrbio, e o ranking previsto bate com o ranking real. O score fica acima da taxa real por causa do balanceamento de classes; ele deve ser usado para **ordenar** prioridades, não como probabilidade calibrada.

## 6.5. Conclusões para a tomada de decisão

1. **Renovar a frota do Subúrbio** é a ação de maior impacto: ataca ao mesmo tempo atraso, emissão de CO₂ e desigualdade territorial.
2. **Faixas exclusivas e reforço de frota nos picos** para as linhas do Miolo e do Subúrbio.
3. **Plano de contingência para o período chuvoso** (abr-jul): quadro de horários com folga e monitoramento de pontos de alagamento.
4. Usar o modelo semanalmente para **gerar a lista de viagens de alto risco** e alocar os veículos mais novos nelas.

Essas conclusões alimentam o Plano de Ação 5W2H (`docs/10_plano_acao_5w2h.md`).

**Limitações:** os dados são sintéticos; o modelo não usa trânsito em tempo real, acidentes ou eventos; a árvore rasa privilegia a interpretação em vez do desempenho máximo. Modelos como *Random Forest* podem aumentar o AUC, mas perdem legibilidade.
