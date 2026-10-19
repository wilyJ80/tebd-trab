# Trabalho: TEBD 2026.2 UNEB
## Hugo Alves, Victor Bitencourt

## Problematização

O crescimento desordenado das áreas urbanas impõe desafios complexos à mobilidade das populações. Nas grandes cidades, o sistema de transporte público frequentemente sofre com atrasos crônicos, frotas obsoletas, superlotação e falta de integração entre diferentes modais (ônibus, metrô, trens).
Sem dados integrados, os gestores públicos e as empresas concessionárias operam no escuro: não conseguem identificar quais linhas são ineficientes, quais horários concentram os maiores gargalos e como o tempo de espera impacta a qualidade de vida do cidadão. Além disso, o setor de transporte é um dos maiores emissores de gases de efeito estufa nas cidades, e a falta de planejamento impede a transição para frotas mais limpas.
A ausência de uma visão analítica centralizada fragmenta as tomadas de decisão, resultando em um sistema caro, poluente e ineficaz para quem mais precisa dele.

## Justificativa (Alinhamento com o ODS 11)

Este projeto está diretamente alinhado com o ODS 11: Cidades e Comunidades Sustentáveis, mais especificamente com a Meta 11.2, que visa, até 2030, proporcionar o acesso a sistemas de transporte seguros, acessíveis, sustentáveis e a preço acessível para todos, melhorando a segurança rodoviária por meio da expansão dos transportes públicos.
A criação de um Data Warehouse (DW) focado na mobilidade urbana justifica-se pela necessidade de transformar registros brutos (como dados de GPS dos ônibus e bilhetagem eletrônica) em inteligência estratégica. Através da modelagem multidimensional, o projeto viabiliza:
- Inclusão Social: Identificar bairros periféricos desatendidos ou com tarifas desproporcionais ao tempo de viagem.
- Sustentabilidade Ambiental: Monitorar e incentivar a substituição de veículos movidos a combustíveis fósseis por modais elétricos ou híbridos, calculando a redução na emissão de \(CO_{2}\).
- Eficiência Operacional: Otimizar frotas para reduzir congestionamentos e o tempo de deslocamento da população, tornando as cidades mais resilientes e inteligentes.

## Requisitos do Sistema (Data Warehouse)

Para que o modelo multidimensional responda às dores da problematização, o sistema deve atender aos seguintes requisitos:

Requisitos de Negócio (Perguntas que o DW deve responder)

- Análise de Pontualidade: Qual é o índice de atraso médio por linha de ônibus durante os horários de pico (7h-9h e 17h-19h)?
- Otimização de Demanda: Quais linhas apresentam superlotação sistemática e necessitam de reforço na frota?
- Perfil do Usuário: Qual é o percentual de passageiros que utilizam tarifas subsidiadas (estudantes/idosos) por região da cidade?
- Impacto Ecológico: Qual é a estimativa de emissão de carbono por quilômetro rodado nas diferentes zonas urbanas?

### Requisitos Técnicos e de Dados

- Granularidade da Fato: Cada registro na tabela fato deve representar uma viagem individualizada realizada por um veículo entre um ponto de partida e um ponto de chegada.
- Histórico Temporal: O sistema deve armazenar dados históricos de pelo menos 5 anos para análise de tendências sazonais (ex: período de férias escolares vs. período letivo).
- Dimensão Geográfica: Capacidade de agregar e filtrar os dados por múltiplos níveis de hierarquia espacial (Ponto de Parada -> Bairro -> Zona Urbana).
- Performance de Consulta: O modelo (Star Schema) deve ser otimizado para consultas rápidas de agregação (Soma, Média, Percentual), evitando cruzamentos (joins) complexos que travariam um banco de dados transacional (OLTP).
