#!/usr/bin/env bash
# =============================================================================
# RTU OLAP laboratorijas palaišana pret Docker konteineri "oracle-db"
#
# Pietiek ar Oracle konteineri (gvenzl/oracle-free): ports 1521.
# Skriptu izpilde NOTIEK konteinerī /tmp/rtu_lab (kopē visa projekta mape).
# Visi .sql faili atrodas apakšmapē sql/
#
# Sagatavojiet savienojuma virkni VIDĒ (NEIELIECIET paroli GIT repozitorijā):
#   export ORACLE_LAB_CONN='lab_user/JūsuParole@//127.0.0.1:1521/FREEPDB1'
#
# Palaišana projekta saknes mapē:
#   chmod +x run_oracle_lab.sh
#   ./run_oracle_lab.sh
#
# LAB_ATBILDES.txt kopē saknes mapē (no sql/99_lab_atskaite.sql SPOOL)
#
# SQL*Plus konteinerī: sqlplus USER/PASS @//HOST:1521/FREEPDB1
# =============================================================================

set +e
set +u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="${CONTAINER_NAME:-oracle-db}"
REMOTE_DIR="/tmp/rtu_lab"
SQL_REL="sql"

if ! docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Kļūda: Docker konteiners '$CONTAINER_NAME' nav atrasts (docker ps)."
  exit 1
fi

if [[ -z "${ORACLE_LAB_CONN:-}" ]]; then
  echo "Norādiet pieslēgumu, piemēram:"
  echo "  export ORACLE_LAB_CONN='lab_user/JūsuParole@//127.0.0.1:1521/FREEPDB1'"
  exit 1
fi

echo ">>> Sagatavoju konteineri $CONTAINER_NAME:$REMOTE_DIR"
docker exec "$CONTAINER_NAME" bash -lc "rm -rf '${REMOTE_DIR}' && mkdir -p '${REMOTE_DIR}'"

echo ">>> Kopēju projektu uz konteineri"
docker cp "${SCRIPT_DIR}/." "${CONTAINER_NAME}:${REMOTE_DIR}/"

STEP_SQL=(
  "${SQL_REL}/01_schema.sql"
  "${SQL_REL}/02_data_plsql.sql"
  "${SQL_REL}/08_gather_stats.sql"
)

if [[ -f "${SCRIPT_DIR}/${SQL_REL}/utlxplan.sql" ]]; then
  STEP_SQL+=( "${SQL_REL}/utlxplan.sql" )
fi

STEP_SQL+=(
  "${SQL_REL}/03_verify.sql"
  "${SQL_REL}/04_queries_no_index.sql"
  "${SQL_REL}/05_indexes_btree.sql"
  "${SQL_REL}/06_indexes_bitmap.sql"
  "${SQL_REL}/07_materialized_views.sql"
  "${SQL_REL}/99_lab_atskaite.sql"
)

for f in "${STEP_SQL[@]}"; do
  echo ""
  echo ">>> Izpilda: $f"
  docker exec "$CONTAINER_NAME" bash -lc "cd '${REMOTE_DIR}' && sqlplus -s '${ORACLE_LAB_CONN}' @${f}"
  RC=$?
  if [[ "$RC" -ne 0 ]]; then
    echo "!!! Brīdinājums: sqlplus beidzas ar kodu RC=$RC (skripts '$f')"
  fi
done

OUT_LOCAL="${SCRIPT_DIR}/LAB_ATBILDES.txt"
echo ""
echo ">>> Nogādāju LAB_ATBILDES.txt uz macOS: ${OUT_LOCAL}"
docker cp "${CONTAINER_NAME}:${REMOTE_DIR}/LAB_ATBILDES.txt" "${OUT_LOCAL}" 2>/dev/null || true

if [[ -f "${OUT_LOCAL}" ]]; then
  ls -la "${OUT_LOCAL}"
else
  echo "Uzmanību: LAB_ATBILDES.txt lokāli nav atrasts — pārbaudiet kādu no SQL failiem ar kļūdu."
fi

echo ">>> GATAVS."
