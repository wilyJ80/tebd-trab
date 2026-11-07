"""Executa o projeto inteiro do zero:
  1. cria oltp.db e olap.db (migrações)
  2. gera os dados sintéticos no OLTP
  3. ETL OLTP -> OLAP
  4. análise exploratória + mineração (item 6)
  5. consultas e dashboard (itens 7, 8 e 9)

Uso: uv run src/tebd_trab/pipeline.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import dashboard  # noqa: E402
import etl  # noqa: E402
import gerar_dados  # noqa: E402
import migrate  # noqa: E402
import mineracao  # noqa: E402


def main() -> None:
    etapas = [
        ("Migrações (OLTP e OLAP)", lambda: migrate.main(reset=True)),
        ("Geração de dados sintéticos", gerar_dados.main),
        ("ETL OLTP -> OLAP", etl.main),
        ("Análise exploratória e mineração", mineracao.main),
        ("Consultas e dashboard", dashboard.main),
    ]
    for i, (nome, fn) in enumerate(etapas, start=1):
        print(f"\n===== [{i}/{len(etapas)}] {nome} =====")
        fn()
    print("\nPronto. Abra dashboard/index.html no navegador.")


if __name__ == "__main__":
    main()
