"""Item 6 - Análise exploratória + mineração de dados (Árvore de Decisão).

Problema: prever, ANTES da viagem, se ela terá atraso relevante (> 10 min),
usando apenas informações conhecidas no planejamento (hora, dia, mês, linha, veículo).

Saídas: docs/figuras/*.png e docs/figuras/resultados_mineracao.json
Uso: uv run src/tebd_trab/mineracao.py
"""

import json
import os
import sqlite3

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.metrics import (accuracy_score, classification_report, confusion_matrix,
                             f1_score, precision_score, recall_score, roc_auc_score)
from sklearn.tree import DecisionTreeClassifier, export_text, plot_tree

OUT = "docs/figuras"
os.makedirs(OUT, exist_ok=True)
plt.rcParams.update({"figure.dpi": 110, "axes.spines.top": False, "axes.spines.right": False,
                     "axes.grid": True, "grid.alpha": 0.3, "font.size": 10})
COR = "#2b6cb0"
ORDEM_ZONA = ["Orla", "Miolo", "Subúrbio"]

CONSULTA = """
SELECT f.id_viagem, f.atraso_minutos, f.flag_atraso, f.taxa_ocupacao, f.total_passageiros,
       f.tempo_viagem_minutos, f.distancia_km, f.emissao_co2_kg,
       t.ano, t.mes, t.hora, t.eh_final_semana, t.eh_horario_pico, t.eh_periodo_chuvoso,
       t.periodo_escolar, t.periodo_dia, t.dia_da_semana,
       l.codigo_linha, l.zona_urbana, l.tipo_servico, l.extensao_km,
       v.tipo_combustivel, v.ano_fabricacao, v.empresa_concessionaria
FROM fato_viagens_transporte f
JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo_partida
JOIN dim_linha l ON l.sk_linha = f.sk_linha
JOIN dim_veiculo v ON v.sk_veiculo = f.sk_veiculo
"""


def salvar(fig, nome):
    fig.tight_layout()
    fig.savefig(f"{OUT}/{nome}.png", bbox_inches="tight")
    plt.close(fig)


def main():
    df = pd.read_sql(CONSULTA, sqlite3.connect("olap.db"))
    df["idade_veiculo"] = df["ano"] - df["ano_fabricacao"]
    res = {"n_viagens": int(len(df))}

    # ------------------------------------------------------------ EDA
    desc = df[["atraso_minutos", "taxa_ocupacao", "total_passageiros", "tempo_viagem_minutos",
               "distancia_km", "idade_veiculo"]].describe().round(2)
    res["descritiva"] = desc.to_dict()
    res["taxa_atraso_geral"] = round(df["flag_atraso"].mean() * 100, 1)
    res["atraso_por_zona"] = df.groupby("zona_urbana")["atraso_minutos"].mean().round(1).to_dict()
    res["taxa_atraso_por_zona"] = (df.groupby("zona_urbana")["flag_atraso"].mean() * 100).round(1).to_dict()
    res["taxa_atraso_pico"] = (df.groupby("eh_horario_pico")["flag_atraso"].mean() * 100).round(1).to_dict()
    res["taxa_atraso_chuva"] = (df.groupby("eh_periodo_chuvoso")["flag_atraso"].mean() * 100).round(1).to_dict()
    res["taxa_atraso_fds"] = (df.groupby("eh_final_semana")["flag_atraso"].mean() * 100).round(1).to_dict()
    res["taxa_atraso_combustivel"] = (df.groupby("tipo_combustivel")["flag_atraso"].mean() * 100).round(1).to_dict()
    res["idade_media_frota_zona"] = df.groupby("zona_urbana")["idade_veiculo"].mean().round(1).to_dict()
    corr = df[["atraso_minutos", "idade_veiculo", "taxa_ocupacao", "eh_horario_pico",
               "eh_periodo_chuvoso", "eh_final_semana", "tempo_viagem_minutos"]].corr().round(2)
    res["correlacao_com_atraso"] = corr["atraso_minutos"].drop("atraso_minutos").to_dict()

    # Figura 1: distribuição do atraso
    fig, ax = plt.subplots(figsize=(7, 3.6))
    ax.hist(df["atraso_minutos"].clip(upper=60), bins=60, color=COR)
    ax.axvline(10, color="#c53030", ls="--", lw=1.5, label="Limite de tolerância (10 min)")
    ax.set(title="Distribuição do atraso na partida", xlabel="Atraso (min, truncado em 60)",
           ylabel="Nº de viagens")
    ax.legend()
    salvar(fig, "01_distribuicao_atraso")

    # Figura 2: atraso médio por hora e zona
    fig, ax = plt.subplots(figsize=(7, 3.6))
    for z, c in zip(ORDEM_ZONA, ["#2b6cb0", "#dd6b20", "#c53030"]):
        s = df[df["zona_urbana"] == z].groupby("hora")["atraso_minutos"].mean()
        ax.plot(s.index, s.values, marker="o", ms=3, label=z, color=c)
    for a, b in [(7, 9), (17, 19)]:
        ax.axvspan(a - 0.5, b - 0.5, color="#f6e05e", alpha=0.25)
    ax.set(title="Atraso médio por hora programada (faixas amarelas = pico)", xlabel="Hora",
           ylabel="Atraso médio (min)")
    ax.set_xticks(range(4, 24, 2))
    ax.legend(title="Zona da linha")
    salvar(fig, "02_atraso_hora_zona")

    # Figura 3: atraso x idade do veículo
    fig, ax = plt.subplots(figsize=(7, 3.6))
    s = df.groupby("idade_veiculo")["atraso_minutos"].agg(["mean", "count"])
    s = s[s["count"] > 500]
    ax.bar(s.index, s["mean"], color=COR)
    ax.set(title="Atraso médio por idade do veículo", xlabel="Idade do veículo (anos)",
           ylabel="Atraso médio (min)")
    salvar(fig, "03_atraso_idade_veiculo")

    # Figura 4: taxa de atraso por fator
    fig, axes = plt.subplots(1, 3, figsize=(9, 3.2), sharey=True)
    for ax, (col, rot) in zip(axes, [("eh_horario_pico", {0: "Fora pico", 1: "Pico"}),
                                     ("eh_periodo_chuvoso", {0: "Seco", 1: "Chuvoso"}),
                                     ("eh_final_semana", {0: "Dia útil", 1: "Fim de semana"})]):
        s = df.groupby(col)["flag_atraso"].mean() * 100
        ax.bar([rot[i] for i in s.index], s.values, color=["#a0aec0", COR])
        for i, val in enumerate(s.values):
            ax.text(i, val + 1, f"{val:.0f}%", ha="center")
    axes[0].set_ylabel("% viagens com atraso > 10 min")
    fig.suptitle("Taxa de atraso por fator")
    salvar(fig, "04_taxa_atraso_fatores")

    # Figura 5: matriz de correlação
    fig, ax = plt.subplots(figsize=(6.2, 5))
    im = ax.imshow(corr, cmap="RdBu_r", vmin=-1, vmax=1)
    ax.set_xticks(range(len(corr)), corr.columns, rotation=45, ha="right")
    ax.set_yticks(range(len(corr)), corr.columns)
    for i in range(len(corr)):
        for j in range(len(corr)):
            ax.text(j, i, f"{corr.iloc[i, j]:.2f}", ha="center", va="center", fontsize=8)
    ax.grid(False)
    fig.colorbar(im, ax=ax, shrink=0.8)
    ax.set_title("Correlação de Pearson")
    salvar(fig, "05_correlacao")

    # ------------------------------------------------------------ Mineração: Árvore de Decisão
    atributos_num = ["hora", "eh_horario_pico", "eh_final_semana", "eh_periodo_chuvoso", "idade_veiculo",
                     "extensao_km"]
    atributos_cat = ["zona_urbana", "tipo_servico", "tipo_combustivel", "periodo_escolar"]
    X = pd.get_dummies(df[atributos_num + atributos_cat], columns=atributos_cat, dtype=int)
    y = df["flag_atraso"]

    # divisão temporal: treina no passado (2022-2025) e testa no "futuro" (2026)
    treino = df["ano"] <= 2025
    Xtr, Xte, ytr, yte = X[treino], X[~treino], y[treino], y[~treino]

    modelo = DecisionTreeClassifier(max_depth=4, min_samples_leaf=500, class_weight="balanced",
                                    random_state=42)
    modelo.fit(Xtr, ytr)
    pred = modelo.predict(Xte)
    prob = modelo.predict_proba(Xte)[:, 1]

    base = int(ytr.mode()[0])
    res["modelo"] = {
        "n_treino": int(treino.sum()), "n_teste": int((~treino).sum()),
        "taxa_positiva_teste": round(yte.mean() * 100, 1),
        "baseline_acuracia": round(accuracy_score(yte, np.full(len(yte), base)) * 100, 1),
        "acuracia": round(accuracy_score(yte, pred) * 100, 1),
        "precisao": round(precision_score(yte, pred) * 100, 1),
        "revocacao": round(recall_score(yte, pred) * 100, 1),
        "f1": round(f1_score(yte, pred) * 100, 1),
        "auc": round(roc_auc_score(yte, prob), 3),
        "matriz_confusao": confusion_matrix(yte, pred).tolist(),
        "relatorio": classification_report(yte, pred, target_names=["Pontual", "Atrasada"], output_dict=True),
        "importancia": {k: round(v, 3) for k, v in sorted(zip(X.columns, modelo.feature_importances_),
                                                          key=lambda x: -x[1]) if v > 0},
        "regras": export_text(modelo, feature_names=list(X.columns), decimals=1),
    }

    # Figura 6: árvore
    fig, ax = plt.subplots(figsize=(26, 9))
    plot_tree(modelo, feature_names=list(X.columns), class_names=["Pontual", "Atrasada"], filled=True,
              rounded=True, fontsize=8, impurity=False, proportion=True, ax=ax)
    ax.grid(False)
    salvar(fig, "06_arvore_decisao")

    # Figura 7: importância
    imp = pd.Series(res["modelo"]["importancia"]).sort_values()
    fig, ax = plt.subplots(figsize=(7, 3.6))
    ax.barh(imp.index, imp.values, color=COR)
    ax.set(title="Importância dos atributos (redução de Gini)", xlabel="Importância relativa")
    salvar(fig, "07_importancia_atributos")

    # Figura 8: matriz de confusão
    cm = np.array(res["modelo"]["matriz_confusao"])
    fig, ax = plt.subplots(figsize=(4.2, 3.6))
    ax.imshow(cm, cmap="Blues")
    for i in range(2):
        for j in range(2):
            ax.text(j, i, f"{cm[i, j]:,}".replace(",", "."), ha="center", va="center",
                    color="white" if cm[i, j] > cm.max() / 2 else "black")
    ax.set_xticks([0, 1], ["Pontual", "Atrasada"])
    ax.set_yticks([0, 1], ["Pontual", "Atrasada"])
    ax.set(xlabel="Previsto", ylabel="Real", title="Matriz de confusão (teste 2026)")
    ax.grid(False)
    salvar(fig, "08_matriz_confusao")

    # risco previsto por linha no pico (uso prático do modelo)
    pico = df[(df["ano"] == 2026) & (df["eh_horario_pico"] == 1)]
    pico = pico.assign(risco=modelo.predict_proba(X.loc[pico.index])[:, 1])
    res["risco_pico_por_linha"] = (pico.groupby("codigo_linha")
                                   .agg(risco_previsto=("risco", "mean"), taxa_real=("flag_atraso", "mean"))
                                   .mul(100).round(1).sort_values("risco_previsto", ascending=False)
                                   .head(8).to_dict(orient="index"))

    with open(f"{OUT}/resultados_mineracao.json", "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False, indent=2, default=str)
    print(json.dumps({k: v for k, v in res.items() if k not in ("descritiva",)}, ensure_ascii=False,
                     indent=1, default=str)[:6000])


if __name__ == "__main__":
    main()
