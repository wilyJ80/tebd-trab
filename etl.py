"""Executa o ETL OLTP -> OLAP (sql/etl_oltp_para_olap.sql).

Uso: uv run src/tebd_trab/etl.py
"""

import sqlite3
import time


def main() -> None:
    inicio = time.time()
    con = sqlite3.connect("olap.db")
    con.execute("ATTACH DATABASE 'oltp.db' AS oltp")
    with open("sql/etl_oltp_para_olap.sql", encoding="utf-8") as f:
        con.executescript(f.read())
    con.commit()
    for tabela in ["dim_tempo", "dim_localizacao", "dim_linha", "dim_veiculo", "dim_tarifa",
                   "fato_viagens_transporte", "fato_bilhetagem"]:
        n = con.execute(f"SELECT COUNT(*) FROM {tabela}").fetchone()[0]
        print(f"[INFO] {tabela:<25} {n:>10,} linhas")
    con.execute("DETACH DATABASE oltp")
    con.execute("VACUUM")
    con.close()
    print(f"[INFO] ETL concluído em {time.time() - inicio:.1f}s.")


if __name__ == "__main__":
    main()
