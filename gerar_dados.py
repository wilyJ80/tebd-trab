"""Popula o banco OLTP (oltp.db) com dados SINTÉTICOS e reprodutíveis.

Os dados simulam o sistema de ônibus de Salvador-BA entre 2022-01-01 e 2026-11-06.
Nomes de empresas, placas e CNPJs são fictícios. Padrões embutidos de propósito
(para que as análises tenham o que encontrar):
  * a frota do Subúrbio é mais antiga e quase toda a diesel;
  * as linhas do Miolo têm demanda alta e superlotam no pico;
  * a frota elétrica entra a partir de 2023, concentrada na concessionária da Orla/Centro;
  * atrasos aumentam no horário de pico, no período chuvoso (abr-jul),
    com veículos mais velhos e com veículo lotado.

Uso: uv run src/tebd_trab/gerar_dados.py
"""

import math
import sqlite3
from datetime import date, timedelta

import numpy as np
import pandas as pd

SEED = 2026
DATA_INICIO = date(2022, 1, 1)
DATA_FIM = date(2026, 11, 6)
DB = "oltp.db"

rng = np.random.default_rng(SEED)

# ---------------------------------------------------------------- referência
EMPRESAS = [
    # id, nome, cnpj, telefone, tamanho da frota em operação
    (1, "Viação Brisa do Mar", "11.222.333/0001-81", "(71) 3000-1001", 45),
    (2, "Consórcio Miolo Integrado", "22.333.444/0001-92", "(71) 3000-2002", 40),
    (3, "Transportes Enseada do Subúrbio", "33.444.555/0001-03", "(71) 3000-3003", 35),
]

BAIRROS = {
    # nome: (zona, lat, lon)
    "Comércio": ("Centro", -12.9705, -38.5124),
    "Lapa": ("Centro", -12.9850, -38.5110),
    "Barris": ("Centro", -12.9870, -38.5170),
    "Nazaré": ("Centro", -12.9810, -38.5050),
    "Campo Grande": ("Centro", -12.9900, -38.5220),
    "Barra": ("Orla", -13.0050, -38.5300),
    "Ondina": ("Orla", -13.0080, -38.5080),
    "Rio Vermelho": ("Orla", -13.0110, -38.4900),
    "Pituba": ("Orla", -13.0000, -38.4600),
    "Caminho das Árvores": ("Orla", -12.9820, -38.4570),
    "Itapuã": ("Orla", -12.9460, -38.3580),
    "Stella Maris": ("Orla", -12.9400, -38.3350),
    "Pernambués": ("Miolo", -12.9680, -38.4630),
    "Cabula": ("Miolo", -12.9550, -38.4750),
    "Sussuarana": ("Miolo", -12.9330, -38.4500),
    "Tancredo Neves": ("Miolo", -12.9500, -38.4480),
    "Pau da Lima": ("Miolo", -12.9260, -38.4300),
    "Cajazeiras": ("Miolo", -12.9000, -38.4050),
    "Lobato": ("Subúrbio", -12.9060, -38.4880),
    "Plataforma": ("Subúrbio", -12.8920, -38.4850),
    "Periperi": ("Subúrbio", -12.8620, -38.4800),
    "Fazenda Coutos": ("Subúrbio", -12.8580, -38.4680),
    "Paripe": ("Subúrbio", -12.8250, -38.4730),
}

LINHAS = [
    # codigo, nome, origem, destino, tipo_servico, empresa, demanda_base, viagens_dia_util
    ("L101", "Pituba - Lapa", "Pituba", "Lapa", "Convencional", 1, 62, 11),
    ("L102", "Barra - Comércio", "Barra", "Comércio", "Convencional", 1, 55, 10),
    ("L103", "Itapuã - Lapa (Expresso)", "Itapuã", "Lapa", "Expresso", 1, 70, 9),
    ("L104", "Rio Vermelho - Campo Grande", "Rio Vermelho", "Campo Grande", "Convencional", 1, 48, 9),
    ("L105", "Stella Maris - Comércio (Expresso)", "Stella Maris", "Comércio", "Expresso", 1, 58, 8),
    ("L106", "Circular da Orla", "Barra", "Rio Vermelho", "Circular", 1, 40, 10),
    ("L107", "Caminho das Árvores - Nazaré", "Caminho das Árvores", "Nazaré", "Convencional", 1, 50, 9),
    ("L201", "Cajazeiras - Lapa", "Cajazeiras", "Lapa", "Convencional", 2, 92, 12),
    ("L202", "Sussuarana - Comércio", "Sussuarana", "Comércio", "Convencional", 2, 80, 10),
    ("L203", "Pau da Lima - Pituba", "Pau da Lima", "Pituba", "Convencional", 2, 78, 10),
    ("L204", "Cabula - Barris", "Cabula", "Barris", "Convencional", 2, 66, 9),
    ("L205", "Tancredo Neves - Caminho das Árvores", "Tancredo Neves", "Caminho das Árvores", "Alimentadora", 2, 60, 9),
    ("L206", "Pernambués - Lapa", "Pernambués", "Lapa", "Convencional", 2, 72, 10),
    ("L301", "Paripe - Comércio", "Paripe", "Comércio", "Convencional", 3, 76, 10),
    ("L302", "Periperi - Lapa", "Periperi", "Lapa", "Convencional", 3, 70, 9),
    ("L303", "Plataforma - Campo Grande", "Plataforma", "Campo Grande", "Convencional", 3, 64, 9),
    ("L304", "Fazenda Coutos - Lobato", "Fazenda Coutos", "Lobato", "Alimentadora", 3, 45, 8),
    ("L305", "Paripe - Caminho das Árvores (Expresso)", "Paripe", "Caminho das Árvores", "Expresso", 3, 60, 7),
]

TARIFA_POR_SERVICO = {"Convencional": 5.60, "Circular": 5.60, "Expresso": 7.00, "Alimentadora": 2.80}

TIPOS_TARIFA = [
    # id, descricao, desconto %, subsidiada
    (1, "Inteira", 0.0, 0),
    (2, "Vale-Transporte", 0.0, 0),
    (3, "Estudante (Meia)", 50.0, 1),
    (4, "Idoso (Gratuidade)", 100.0, 1),
    (5, "Pessoa com Deficiência (Gratuidade)", 100.0, 1),
]

# kg de CO2 por km (escapamento + parcela da geração elétrica para o elétrico)
CO2_KM = {"Diesel": 1.30, "GNV": 1.10, "Híbrido": 0.85, "Elétrico": 0.10}

# Frota inicial: (empresa, quantidade, combustível, faixa de ano de fabricação)
FROTA_INICIAL = [
    (1, 42, "Diesel", (2013, 2021)), (1, 3, "GNV", (2018, 2021)),
    (2, 35, "Diesel", (2011, 2020)), (2, 5, "GNV", (2016, 2020)),
    (3, 35, "Diesel", (2007, 2015)),
]
# Renovação da frota: (empresa, data de entrada, quantidade, combustível)
RENOVACAO = [
    (1, "2023-03-01", 8, "Elétrico"), (1, "2024-02-01", 10, "Elétrico"),
    (1, "2025-02-01", 12, "Elétrico"), (1, "2026-02-01", 8, "Elétrico"),
    (2, "2024-06-01", 5, "Híbrido"), (2, "2025-08-01", 6, "Elétrico"),
    (2, "2026-03-01", 4, "Elétrico"),
    (3, "2025-09-01", 3, "Híbrido"),
]

TENDENCIA_ANUAL = {2022: 0.88, 2023: 0.94, 2024: 1.00, 2025: 1.03, 2026: 1.05}

# distribuição horária das partidas (horas 4..23)
HORAS = np.arange(4, 24)
PESO_HORA = np.array([1, 3, 6, 9, 9, 6, 5, 4, 4, 4, 4, 5, 6, 9, 9, 6, 4, 3, 2, 1], float)
PESO_HORA /= PESO_HORA.sum()
FATOR_DEMANDA_HORA = {h: (0.35 if h < 5 else 0.8 if h < 7 else 1.55 if h < 9 else 0.85 if h < 17
                          else 1.55 if h < 19 else 0.65 if h < 22 else 0.4) for h in range(24)}
ATRASO_BASE_ZONA = {"Centro": 3.0, "Orla": 3.5, "Miolo": 5.5, "Subúrbio": 7.0}


def haversine_km(a, b):
    lat1, lon1, lat2, lon2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    h = math.sin((lat2 - lat1) / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2
    return 2 * 6371 * math.asin(math.sqrt(h))


def placa_mercosul(i):
    letras = "ABCDEFGHJKLMNPRSTUVWXYZ"
    return f"R{letras[i % 23]}{letras[(i // 23) % 23]}{i % 10}{letras[(i * 7) % 23]}{(i * 3) % 100:02d}"


def main():
    con = sqlite3.connect(DB)
    con.execute("PRAGMA foreign_keys = ON")
    cur = con.cursor()
    for t in ["validacoes_bilhetagem", "viagens_diarias", "veiculos", "linhas",
              "pontos_parada", "bairros", "tipos_tarifa", "empresas_onibus"]:
        cur.execute(f"DELETE FROM {t}")
    cur.execute("DELETE FROM sqlite_sequence")

    # ---- empresas, tarifas, bairros, pontos
    cur.executemany("INSERT INTO empresas_onibus VALUES (?,?,?,?)", [e[:4] for e in EMPRESAS])
    cur.executemany("INSERT INTO tipos_tarifa VALUES (?,?,?,?)", TIPOS_TARIFA)

    id_bairro, pontos_do_bairro, pontos = {}, {}, []
    for i, (nome, (zona, lat, lon)) in enumerate(BAIRROS.items(), start=1):
        id_bairro[nome] = i
        cur.execute("INSERT INTO bairros VALUES (?,?,?)", (i, nome, zona))
        pontos_do_bairro[nome] = []
        for k, logradouro in enumerate([f"Terminal / Estação {nome}", f"Av. Principal - {nome}"]):
            pid = len(pontos) + 1
            pontos.append((pid, i, f"PT-{1000 + pid}", logradouro,
                           round(lat + rng.normal(0, 0.002), 6), round(lon + rng.normal(0, 0.002), 6)))
            pontos_do_bairro[nome].append(pid)
    cur.executemany("INSERT INTO pontos_parada VALUES (?,?,?,?,?,?)", pontos)

    # ---- linhas
    linhas = []
    for i, (cod, nome, orig, dest, serv, emp, dem, nviag) in enumerate(LINHAS, start=1):
        ext = haversine_km(BAIRROS[orig][1:], BAIRROS[dest][1:]) * 1.45 + 2.0
        linhas.append(dict(id=i, cod=cod, nome=nome, orig=orig, dest=dest, serv=serv, emp=emp,
                           dem=dem, nviag=nviag, ext=round(ext, 1), zona=BAIRROS[orig][0],
                           tarifa=TARIFA_POR_SERVICO[serv]))
    cur.executemany("INSERT INTO linhas VALUES (?,?,?,?,?,?,?,?)",
                    [(l["id"], l["emp"], l["cod"], l["nome"], l["serv"], l["tarifa"], l["ext"], l["zona"])
                     for l in linhas])

    # ---- veículos
    veiculos = []
    for emp, qtd, comb, (a0, a1) in FROTA_INICIAL:
        for _ in range(qtd):
            ano = int(rng.integers(a0, a1 + 1))
            veiculos.append(dict(emp=emp, comb=comb, ano=ano, inicio=f"{max(ano, 2007)}-01-15",
                                 cap=int(rng.choice([70, 80, 90], p=[0.3, 0.5, 0.2]))))
    for emp, inicio, qtd, comb in RENOVACAO:
        for _ in range(qtd):
            veiculos.append(dict(emp=emp, comb=comb, ano=int(inicio[:4]), inicio=inicio,
                                 cap=int(rng.choice([80, 90], p=[0.6, 0.4]))))
    for i, v in enumerate(veiculos, start=1):
        v["id"] = i
        v["prefixo"] = f"{v['emp']}{i:04d}"
    cur.executemany("INSERT INTO veiculos VALUES (?,?,?,?,?,?,?,?)",
                    [(v["id"], v["emp"], placa_mercosul(v["id"] * 37), v["prefixo"], v["cap"], v["comb"],
                      v["ano"], v["inicio"]) for v in veiculos])
    vdf = pd.DataFrame(veiculos)
    vdf["inicio"] = pd.to_datetime(vdf["inicio"])

    # ---- viagens (vetorizado)
    dias = pd.date_range(DATA_INICIO, DATA_FIM, freq="D")
    ldf = pd.DataFrame(linhas)
    grade = ldf.merge(pd.DataFrame({"dia": dias}), how="cross")
    fds = grade["dia"].dt.day_of_week >= 5
    grade["n"] = np.where(fds, np.round(grade["nviag"] * 0.6), grade["nviag"]).astype(int)
    v = grade.loc[grade.index.repeat(grade["n"])].reset_index(drop=True)
    n = len(v)
    print(f"[INFO] Gerando {n:,} viagens...")

    hora = rng.choice(HORAS, size=n, p=PESO_HORA)
    minuto = rng.integers(0, 60, size=n)
    v["prevista"] = v["dia"] + pd.to_timedelta(hora, "h") + pd.to_timedelta(minuto, "m")
    v = v.sort_values(["prevista", "id"]).reset_index(drop=True)
    hora = v["prevista"].dt.hour.to_numpy()
    mes = v["prevista"].dt.month.to_numpy()
    ano = v["prevista"].dt.year.to_numpy()
    fds = (v["prevista"].dt.day_of_week >= 5).to_numpy()
    pico = np.isin(hora, [7, 8, 17, 18])
    chuva = np.isin(mes, [4, 5, 6, 7])
    ferias = np.isin(mes, [1, 7, 12])

    # veículo: sorteado entre os N mais novos em operação da empresa no mês (renovação de frota)
    v["mes_ref"] = v["prevista"].dt.to_period("M")
    v["id_veiculo"] = 0
    tam_frota = {e[0]: e[4] for e in EMPRESAS}
    for (emp, mref), idx in v.groupby(["emp", "mes_ref"]).groups.items():
        ativos = vdf[(vdf["emp"] == emp) & (vdf["inicio"] <= mref.to_timestamp(how="end"))]
        ativos = ativos.sort_values(["ano", "id"], ascending=False).head(tam_frota[emp])
        v.loc[idx, "id_veiculo"] = rng.choice(ativos["id"].to_numpy(), size=len(idx))
    v = v.merge(vdf[["id", "comb", "ano", "cap"]].rename(columns={"id": "id_veiculo", "ano": "ano_fab"}),
                on="id_veiculo", how="left")
    idade = ano - v["ano_fab"].to_numpy()

    # pontos (ida/volta)
    volta = rng.random(n) < 0.5
    po = np.array([rng.choice(pontos_do_bairro[b]) for b in v["orig"]])
    pd_ = np.array([rng.choice(pontos_do_bairro[b]) for b in v["dest"]])
    v["p_partida"] = np.where(volta, pd_, po)
    v["p_chegada"] = np.where(volta, po, pd_)

    # demanda
    fh = np.vectorize(FATOR_DEMANDA_HORA.get)(hora)
    tend = np.vectorize(TENDENCIA_ANUAL.get)(ano)
    demanda = (v["dem"].to_numpy() * fh * np.where(fds, 0.65, 1.0) * np.where(ferias, 0.85, 1.0)
               * tend * rng.lognormal(0, 0.18, n))
    total = np.maximum(0, np.round(demanda)).astype(int)
    # lotação máxima simultânea a bordo (sensor APC) é uma fração do total de embarques
    lotacao = np.round(total * rng.uniform(0.60, 0.95, n)).astype(int)
    ocup = lotacao / v["cap"].to_numpy()

    # atraso (minutos, na partida em relação ao programado)
    media = (np.vectorize(ATRASO_BASE_ZONA.get)(v["zona"].to_numpy())
             * np.where(pico, 1.9, 1.0) * np.where(chuva, 1.35, 1.0) * np.where(fds, 0.6, 1.0)
             + 0.30 * np.maximum(idade, 0) + np.where(ocup > 1.0, 3.0, 0.0))
    atraso = np.round(rng.gamma(2.0, media / 2.0)).astype(int)
    partida = v["prevista"] + pd.to_timedelta(atraso, "m")

    dist = np.round(v["ext"].to_numpy() * rng.uniform(0.97, 1.06, n), 2)
    vel = 21.0 * np.where(pico, 0.68, 1.0) * np.where(chuva, 0.9, 1.0) * np.where(fds, 1.15, 1.0)
    vel = vel * np.where(v["serv"].to_numpy() == "Expresso", 1.25, 1.0) * rng.uniform(0.85, 1.1, n)
    dur = np.round(dist / vel * 60).astype(int)
    chegada = partida + pd.to_timedelta(dur, "m")
    co2 = np.round(dist * np.vectorize(CO2_KM.get)(v["comb"].to_numpy()) * (1 + 0.015 * np.maximum(idade, 0)), 3)

    fmt = "%Y-%m-%d %H:%M:%S"
    viagens = pd.DataFrame({
        "id_viagem": np.arange(1, n + 1), "id_veiculo": v["id_veiculo"], "id_linha": v["id"],
        "id_ponto_partida": v["p_partida"], "id_ponto_chegada": v["p_chegada"],
        "prevista": v["prevista"].dt.strftime(fmt), "partida": partida.dt.strftime(fmt),
        "chegada": chegada.dt.strftime(fmt), "atraso": atraso, "dist": dist,
        "total": total, "lotacao": lotacao, "co2": co2,
    })
    cur.executemany("INSERT INTO viagens_diarias VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
                    viagens.itertuples(index=False, name=None))

    # ---- bilhetagem: divide os passageiros da viagem entre os tipos de tarifa
    periferia = np.isin(v["zona"].to_numpy(), ["Miolo", "Subúrbio"])
    p = np.column_stack([
        np.where(periferia, 0.34, 0.36),                                  # Inteira
        np.where(periferia, 0.24, 0.33),                                  # Vale-Transporte
        0.17 * np.where(ferias, 0.15, 1.0) * np.where(fds, 0.3, 1.0)
        * np.where(periferia, 1.25, 1.0),                                 # Estudante
        np.where(periferia, 0.15, 0.10),                                  # Idoso
        np.where(periferia, 0.05, 0.03),                                  # PcD
    ])
    p = p / p.sum(axis=1, keepdims=True)
    qtd = rng.multinomial(total, p)
    tarifa = v["tarifa"].to_numpy()
    desc = np.array([t[2] for t in TIPOS_TARIFA]) / 100
    linhas_b = []
    for j, tid in enumerate([t[0] for t in TIPOS_TARIFA]):
        mask = qtd[:, j] > 0
        valor = np.round(qtd[mask, j] * tarifa[mask] * (1 - desc[j]), 2)
        linhas_b.append(pd.DataFrame({"id_viagem": viagens["id_viagem"].to_numpy()[mask], "tid": tid,
                                      "q": qtd[mask, j], "valor": valor}))
    b = pd.concat(linhas_b).sort_values(["id_viagem", "tid"])
    cur.executemany("INSERT INTO validacoes_bilhetagem (id_viagem, id_tipo_tarifa, quantidade_validacoes,"
                    " valor_arrecadado) VALUES (?,?,?,?)", b.itertuples(index=False, name=None))
    con.commit()
    print(f"[INFO] OLTP populado: {len(veiculos)} veículos, {len(linhas)} linhas, {n:,} viagens, "
          f"{len(b):,} registros de bilhetagem.")
    con.close()


if __name__ == "__main__":
    main()
