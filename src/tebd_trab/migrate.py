from yoyo import get_backend, read_migrations
from yoyo.backends import SQLiteBackend
from yoyo.migrations import MigrationList

oltp_backend: SQLiteBackend = get_backend("sqlite:///./oltp.db")
olap_backend: SQLiteBackend = get_backend("sqlite:///./olap.db")
oltp_migrations: MigrationList = read_migrations("oltp_migrations")
olap_migrations: MigrationList = read_migrations("olap_migrations")

print("[INFO] Preparing OLTP...")
with oltp_backend.lock():
    print("[INFO] Migrating OLTP...")
    oltp_backend.apply_migrations(oltp_backend.to_apply(oltp_migrations))
    print("[INFO] Migrated OLTP.")

print("[INFO] Preparing OLAP...")
with olap_backend.lock():
    print("[INFO] Migrating OLAP...")
    olap_backend.apply_migrations(olap_backend.to_apply(olap_migrations))
    print("[INFO] Migrated OLAP.")
