"""Itens 7, 8 e 9 - Executa as 15 consultas de consultas/*.sql e gera:
  * dashboard/index.html          -> dashboard interativo (Plotly) com 3 abas
  * docs/07_09_dashboards.md      -> documento com enunciado + código + resultado

Cada consulta nos arquivos .sql é anotada assim:
  -- @consulta O1
  -- @titulo ...
  -- @enunciado ...
  -- @grafico barra|barra_empilhada|linha|tabela x=col y=col cor=col

Uso: uv run src/tebd_trab/dashboard.py
"""

import html
import os
import re
import sqlite3

import pandas as pd
import plotly.express as px
from plotly.offline import get_plotlyjs

NIVEIS = [
    ("operacional", "Operacional", "consultas/01_operacional.sql", "oltp.db",
     "Centro de Controle Operacional · o que está acontecendo hoje (dados de 06/11/2026, banco OLTP)"),
    ("tatico", "Tático", "consultas/02_tatico.sql", "olap.db",
     "Gerência de operações · desempenho por linha, zona e empresa em meses/trimestres (Data Warehouse)"),
    ("estrategico", "Estratégico", "consultas/03_estrategico.sql", "olap.db",
     "Prefeitura · tendências de 2022 a 2026 ligadas à ODS 11 (Data Warehouse)"),
]
PALETA = ["#2563eb", "#ea580c", "#16a34a", "#9333ea", "#dc2626", "#0891b2"]
CORES_COMB = {"Diesel": "#57534e", "GNV": "#ca8a04", "Híbrido": "#0891b2", "Elétrico": "#16a34a"}
CORES_ZONA = {"Centro": "#9333ea", "Orla": "#2563eb", "Miolo": "#ea580c", "Subúrbio": "#dc2626"}


def ler_consultas(caminho):
    texto = open(caminho, encoding="utf-8").read()
    consultas = []
    for bloco in texto.split("-- @consulta ")[1:]:
        linhas = bloco.splitlines()
        meta = {"id": linhas[0].strip()}
        sql = []
        for ln in linhas[1:]:
            m = re.match(r"--\s*@(\w+)\s*(.*)", ln)
            if m:
                meta[m.group(1)] = m.group(2).strip()
            elif not ln.startswith("-- ===") and not (not sql and ln.startswith("--")):
                sql.append(ln)
        meta["sql"] = "\n".join(sql).strip()
        g = meta.get("grafico", "tabela").split()
        meta["tipo"] = g[0]
        meta.update(dict(p.split("=") for p in g[1:]))
        consultas.append(meta)
    return consultas


def mapa_cores(col, valores):
    if col in ("combustivel", "tipo_combustivel"):
        return CORES_COMB
    if col == "zona":
        return CORES_ZONA
    return {v: PALETA[i % len(PALETA)] for i, v in enumerate(sorted(set(valores)))}


def grafico(c, df):
    if c["tipo"] == "tabela" or df.empty:
        return None
    x, y, cor = c["x"], c["y"], c.get("cor")
    kw = dict(x=x, y=y, template="plotly_white", height=360)
    if cor:
        kw.update(color=cor, color_discrete_map=mapa_cores(cor, df[cor]))
    else:
        kw.update(color_discrete_sequence=[PALETA[0]])
    if c["tipo"] == "linha":
        fig = px.line(df, markers=True, **kw)
    else:
        fig = px.bar(df, barmode="stack" if c["tipo"] == "barra_empilhada" else "group", text_auto=True, **kw)
        fig.update_traces(textposition="outside" if c["tipo"] == "barra" else "inside", cliponaxis=False)
    fig.update_layout(margin=dict(l=10, r=10, t=10, b=10), legend_title_text=cor or "",
                      font=dict(family="Inter, system-ui, sans-serif", size=12))
    fig.update_xaxes(type="category")
    return fig.to_html(full_html=False, include_plotlyjs=False, config={"displaylogo": False})


def num_br(v):
    """Formata número no padrão brasileiro: 5079.0 -> 5.079 ; 65.3 -> 65,3 ; 1.413 -> 1,413."""
    if pd.isna(v):
        return "–"
    if isinstance(v, float):
        if v.is_integer():
            v = int(v)
        else:
            txt = f"{v:,.3f}".rstrip("0").rstrip(".")
            return txt.replace(",", "X").replace(".", ",").replace("X", ".")
    if isinstance(v, int):
        return f"{v:,}".replace(",", ".")
    return str(v)


def tabela_html(df, limite=25):
    corpo = df.head(limite).to_html(index=False, classes="tab", border=0, na_rep="–",
                                    formatters={c: num_br for c in df.columns if df[c].dtype != object and c != "ano"})
    extra = f'<p class="nota">Mostrando {limite} de {len(df)} linhas.</p>' if len(df) > limite else ""
    return corpo + extra


def tabela_md(df, limite=20):
    df = df.head(limite)
    fmt = num_br
    linhas = ["| " + " | ".join(df.columns) + " |", "|" + "---|" * len(df.columns)]
    linhas += ["| " + " | ".join(str(v) if c == "ano" else fmt(v) for c, v in zip(df.columns, r)) + " |"
               for r in df.itertuples(index=False)]
    return "\n".join(linhas)


def main():
    os.makedirs("dashboard", exist_ok=True)
    abas, paineis, md = [], [], ["# 7, 8 e 9. Dashboards Operacional, Tático e Estratégico", "",
                                 "> Gerado automaticamente por `src/tebd_trab/dashboard.py` a partir de "
                                 "`consultas/*.sql`. Dashboard interativo: `dashboard/index.html`.", "",
                                 "> Dados sintéticos (ver `src/tebd_trab/gerar_dados.py`). "
                                 "Resultados limitados às primeiras linhas.", ""]
    for i, (chave, nome, arquivo, banco, desc) in enumerate(NIVEIS):
        con = sqlite3.connect(banco)
        cards = []
        md += [f"## {7 + i}. Dashboard {nome}", "", f"*{desc}* — consultas em `{arquivo}`.", ""]
        for c in ler_consultas(arquivo):
            df = pd.read_sql(c["sql"], con)
            print(f"[INFO] {c['id']}: {len(df)} linhas")
            g = grafico(c, df)
            visual = g if g else tabela_html(df)
            detalhe = "" if not g else f"<details><summary>Ver dados ({len(df)} linhas)</summary>{tabela_html(df)}</details>"
            cards.append(f"""
<section class="card">
  <div class="card-head"><span class="tag">{c['id']}</span><h3>{html.escape(c['titulo'])}</h3></div>
  <p class="enunciado">{html.escape(c['enunciado'])}</p>
  <div class="visual">{visual}</div>
  {detalhe}
  <details><summary>Ver SQL</summary><pre><code>{html.escape(c['sql'])}</code></pre></details>
</section>""")
            md += [f"### {c['id']} — {c['titulo']}", "", f"**Enunciado:** {c['enunciado']}", "",
                   "```sql", c["sql"], "```", "", f"**Resultado** ({len(df)} linhas):", "", tabela_md(df), ""]
        abas.append(f'<button class="aba{" ativa" if i == 0 else ""}" data-alvo="{chave}">{nome}</button>')
        paineis.append(f'<div class="painel{" ativo" if i == 0 else ""}" id="{chave}">'
                       f'<p class="desc">{desc}</p><div class="grade">{"".join(cards)}</div></div>')
        con.close()

    pagina = f"""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mobilidade Salvador</title>
<script>{get_plotlyjs()}</script>
<style>
:root {{ --bg:#f5f6f8; --card:#fff; --tx:#1f2937; --mut:#6b7280; --bd:#e5e7eb; --ac:#2563eb; }}
* {{ box-sizing:border-box; }}
body {{ margin:0; background:var(--bg); color:var(--tx); font:15px/1.5 Inter, system-ui, sans-serif; }}
header {{ background:#0f172a; color:#fff; padding:24px 16px 0; }}
.wrap {{ max-width:1280px; margin:0 auto; }}
header h1 {{ margin:0 0 4px; font-size:22px; }}
header p {{ margin:0 0 16px; color:#cbd5e1; font-size:14px; }}
.abas {{ display:flex; gap:4px; flex-wrap:wrap; }}
.aba {{ background:transparent; border:0; color:#cbd5e1; padding:10px 18px; font:600 14px inherit;
        cursor:pointer; border-radius:8px 8px 0 0; }}
.aba.ativa {{ background:var(--bg); color:var(--tx); }}
main {{ padding:20px 16px 48px; }}
.painel {{ display:none; }} .painel.ativo {{ display:block; }}
.desc {{ color:var(--mut); margin:0 0 16px; }}
.grade {{ display:grid; grid-template-columns:repeat(auto-fit, minmax(min(100%, 560px), 1fr)); gap:16px; }}
.card {{ background:var(--card); border:1px solid var(--bd); border-radius:12px; padding:16px; min-width:0; }}
.card-head {{ display:flex; align-items:center; gap:10px; }}
.card h3 {{ margin:0; font-size:16px; }}
.tag {{ background:#eff6ff; color:var(--ac); font-weight:700; font-size:12px; padding:2px 8px; border-radius:6px; }}
.enunciado {{ color:var(--mut); font-size:13.5px; margin:8px 0 12px; }}
.visual {{ overflow:auto; max-height:440px; }}
table.tab {{ border-collapse:collapse; width:100%; font-size:13px; }}
table.tab th {{ text-align:left; background:#f9fafb; position:sticky; top:0; }}
table.tab th, table.tab td {{ padding:6px 8px; border-bottom:1px solid var(--bd); white-space:nowrap; }}
details {{ margin-top:10px; font-size:13px; }} summary {{ cursor:pointer; color:var(--ac); font-weight:600; }}
details > table, details > .nota {{ display:block; overflow-x:auto; margin-top:8px; }}
pre {{ background:#0f172a; color:#e2e8f0; padding:12px; border-radius:8px; overflow-x:auto; font-size:12.5px; }}
.nota {{ color:var(--mut); font-size:12px; }}
footer {{ color:var(--mut); font-size:12px; text-align:center; padding:0 16px 24px; }}
</style></head><body>
<header><div class="wrap">
  <h1>Mobilidade Urbana · Salvador</h1>
  <p>Laboratório de Dados para Cidades Sustentáveis · ODS 11.2 · TEBD 2026.2 (UNEB)</p>
  <nav class="abas">{"".join(abas)}</nav>
</div></header>
<main class="wrap">{"".join(paineis)}</main>
<footer>Dados sintéticos gerados para fins acadêmicos.</footer>
<script>
document.querySelectorAll('.aba').forEach(b => b.addEventListener('click', () => {{
  document.querySelectorAll('.aba').forEach(x => x.classList.toggle('ativa', x === b));
  document.querySelectorAll('.painel').forEach(p => p.classList.toggle('ativo', p.id === b.dataset.alvo));
  window.dispatchEvent(new Event('resize'));
}}));
</script>
</body></html>"""
    with open("dashboard/index.html", "w", encoding="utf-8") as f:
        f.write(pagina)
    with open("docs/07_09_dashboards.md", "w", encoding="utf-8") as f:
        f.write("\n".join(md))
    print("[INFO] dashboard/index.html e docs/07_09_dashboards.md gerados.")


if __name__ == "__main__":
    main()
