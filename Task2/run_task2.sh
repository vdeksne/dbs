#!/usr/bin/env bash
# Palaist Task2 sql skriptus secīgi un saglabāt visu izvadi vienā teksta failā.
# Prasa Oracle klientu: sqlplus vai sql (SQLcl).
#
# Lietošana:
#   export TASK2_CONNECT='lietotājs/parole@localhost:1521/FREEPDB1'
#   ./run_task2.sh
#
# Vai vienu reizi ar argumentu:
#   ./run_task2.sh 'lietotājs/parole@localhost:1521/FREEPDB1'
#
# Pilns ceļš līdz sqlplus vai sql (SQLcl), ja nav PATH:
#   export TASK2_SQL_CLIENT='/Applications/SQLDeveloper.app/Contents/Resources/sqldeveloper/sqldeveloper/bin/sql'
#
# SQLcl (sql) vajag JDK 11+ (ne JDK 8). Skripts meklē: TASK2_JAVA_HOME, tad JAVA_HOME (tikai ja ≥11), tad
# macOS /usr/libexec/java_home, tad SQL Developer jdk*.jdk. Citādi: brew install openjdk@17
#   export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
#
# Izvades fails (pēc noklusējuma): ./task2_run_YYYYMMDD_HHMMSS.txt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="${SCRIPT_DIR}/sql"

# Atrod sqlplus vai sql — PATH, TASK2_SQL_CLIENT, tipiskas SQL Developer / Instant Client lokācijas (macOS)
find_oracle_client() {
  local p
  if [[ -n "${TASK2_SQL_CLIENT:-}" && -x "${TASK2_SQL_CLIENT}" ]]; then
    printf '%s\n' "${TASK2_SQL_CLIENT}"
    return 0
  fi
  for p in "$(command -v sqlplus 2>/dev/null)" "$(command -v sql 2>/dev/null)"; do
    if [[ -n "$p" && -x "$p" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done

  local -a app_roots=(
    "/Applications/SQLDeveloper.app"
    "/Applications/SQL Developer.app"
  )
  local rels=(
    "Contents/Resources/sqldeveloper/sqldeveloper/bin/sql"
    "Contents/Resources/sqldeveloper/sqlclient/bin/sql"
  )
  local root rel cand
  for root in "${app_roots[@]}"; do
    [[ -d "$root" ]] || continue
    for rel in "${rels[@]}"; do
      cand="${root}/${rel}"
      if [[ -x "$cand" ]]; then
        printf '%s\n' "$cand"
        return 0
      fi
    done
  done

  shopt -s nullglob
  local ic
  for ic in \
    /opt/oracle/instantclient*/sqlplus \
    "${HOME}/instantclient_"*/sqlplus \
    /usr/local/instantclient*/sqlplus \
    /opt/homebrew/opt/instantclient*/sqlplus \
    "${HOME}/Oracle/instantclient_"*/sqlplus
  do
    if [[ -x "$ic" ]]; then
      printf '%s\n' "$ic"
      shopt -u nullglob
      return 0
    fi
  done
  shopt -u nullglob

  return 1
}

# SQLcl (bin/sql) ir Java lietotne — vajag JDK 11+ (bieži kļūda: noklusējums JDK 8).
java_major_from_cmd() {
  local line
  line="$("$1" -version 2>&1 | head -1)"
  if [[ "$line" =~ version\ \"1\.8 ]]; then echo 8; return; fi
  if [[ "$line" =~ version\ \"1\.[0-9] ]]; then echo 8; return; fi
  if [[ "$line" =~ version\ \"([0-9]+) ]]; then echo "${BASH_REMATCH[1]}"; return; fi
  echo 0
}

find_java11_home() {
  local j h
  if [[ -n "${TASK2_JAVA_HOME:-}" && -x "${TASK2_JAVA_HOME}/bin/java" ]]; then
    h="$(java_major_from_cmd "${TASK2_JAVA_HOME}/bin/java")"
    if [[ "${h}" -ge 11 ]]; then
      printf '%s\n' "${TASK2_JAVA_HOME}"
      return 0
    fi
  fi
  if [[ -n "${JAVA_HOME:-}" && -x "${JAVA_HOME}/bin/java" ]]; then
    h="$(java_major_from_cmd "${JAVA_HOME}/bin/java")"
    if [[ "${h}" -ge 11 ]]; then
      printf '%s\n' "${JAVA_HOME}"
      return 0
    fi
  fi
  if [[ -x /usr/libexec/java_home ]]; then
    for v in 24 23 22 21 20 19 18 17 11; do
      j="$(/usr/libexec/java_home -v "${v}" 2>/dev/null)" || continue
      [[ -n "${j}" && -x "${j}/bin/java" ]] && printf '%s\n' "${j}" && return 0
    done
  fi
  # Homebrew «keg-only» openjdk@17 bieži nav /usr/libexec/java_home sarakstā
  for j in \
    /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home \
    /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home \
    /usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
  do
    if [[ -x "${j}/bin/java" ]]; then
      h="$(java_major_from_cmd "${j}/bin/java")"
      [[ "${h}" -ge 11 ]] && printf '%s\n' "${j}" && return 0
    fi
  done
  local sql_bin_dir root
  sql_bin_dir="$(dirname "${ORACLE_BIN}")"
  for root in \
    "$(cd "${sql_bin_dir}/../.." 2>/dev/null && pwd)" \
    "$(cd "${sql_bin_dir}/../../.." 2>/dev/null && pwd)" \
    "/Applications/SQLDeveloper.app/Contents/Resources/sqldeveloper"
  do
    [[ -d "${root}" ]] || continue
    shopt -s nullglob
    for j in \
      "${root}/jdk"*.jdk/Contents/Home \
      "${root}/../jdk"*.jdk/Contents/Home \
      "${root}/sqldeveloper/jdk"*.jdk/Contents/Home
    do
      if [[ -x "${j}/bin/java" ]]; then
        h="$(java_major_from_cmd "${j}/bin/java")"
        if [[ "${h}" -ge 11 ]]; then
          shopt -u nullglob
          printf '%s\n' "${j}"
          return 0
        fi
      fi
    done
    shopt -u nullglob
  done
  return 1
}

ensure_java_for_sqlcl() {
  [[ "$(basename "${ORACLE_BIN}")" == "sql" ]] || return 0
  local picked
  if ! picked="$(find_java11_home)"; then
    echo "SQLcl prasa Java 11+, bet atrasts Java 8 (vai vecāks)." >&2
    echo "Risinājumi (macOS):" >&2
    echo "  brew install openjdk@17" >&2
    echo "  export JAVA_HOME=\"\$(/usr/libexec/java_home -v 17)\"" >&2
    echo "Vai norādiet JDK no SQL Developer .app: atrast jdk*.jdk/Contents/Home un" >&2
    echo "  export TASK2_JAVA_HOME='/pilns/ceļš/līdz/.../Contents/Home'" >&2
    exit 1
  fi
  export JAVA_HOME="${picked}"
}

ORACLE_BIN="$(find_oracle_client || true)"

CONNECT_URI="${1:-${TASK2_CONNECT:-}}"
if [[ -z "${CONNECT_URI}" ]]; then
  echo "Trūkst datu bāzes savienojuma (šajā termināļa sesijā)." >&2
  echo "Pirms ./run_task2.sh vienā blokā vai secīgi palaidiet, piem.:" >&2
  echo "  export TASK2_CONNECT='system/parole@localhost:1521/FREEPDB1'" >&2
  echo "Jauns Terminal logs = export jāatkārto." >&2
  echo "Vai vienā līnijā: $0 'system/parole@localhost:1521/FREEPDB1'" >&2
  exit 1
fi

if [[ -z "${ORACLE_BIN}" ]]; then
  echo "Nav atrasts ne sqlplus, ne sql (SQLcl) PATH un parastajās mapēs." >&2
  echo "Varianti:" >&2
  echo "  1) Instalēt Oracle Instant Client (Basic + SQL*Plus): https://www.oracle.com/database/technologies/instant-client.html" >&2
  echo "  2) Norādīt pilnu ceļu: export TASK2_SQL_CLIENT='/ceļš/līdz/sql' vai sqlplus" >&2
  echo "  3) Ja SQL Developer mapē ir sql, piem.: SQLDeveloper.app/.../sqldeveloper/bin/sql" >&2
  exit 1
fi

ensure_java_for_sqlcl

case "$(basename "${ORACLE_BIN}")" in
  sqlplus) run_client() { "${ORACLE_BIN}" -L "$CONNECT_URI" "$@"; } ;;
  sql)
    # SQLcl: -L mēdz atšķirties no SQL*Plus; savienojums kā pirmais arguments
    run_client() { "${ORACLE_BIN}" "$CONNECT_URI" "$@"; }
    ;;
  *)       run_client() { "${ORACLE_BIN}" "$CONNECT_URI" "$@"; } ;;
esac

if [[ -n "${TASK2_OUTPUT:-}" ]]; then
  OUT_FILE="${TASK2_OUTPUT}"
else
  OUT_FILE="${SCRIPT_DIR}/task2_run_$(date +%Y%m%d_%H%M%S).txt"
fi

SCRIPTS=(
  "01_relational_ddl.sql"
  "02_relational_data.sql"
  "03_functions.sql"
  "04_relational_queries_plan.sql"
  "05_object_types.sql"
  "06_object_load.sql"
  "07_object_queries_plan.sql"
)

{
  echo "================================================================================
Task2 — pilna izpilde
Sākta: $(date "+%Y-%m-%d %H:%M:%S")
Datubāzes punkts (suffix pēc @): @${CONNECT_URI#*@}"
  echo "Oracle klients: ${ORACLE_BIN}"
  if [[ "$(basename "${ORACLE_BIN}")" == "sql" ]]; then
    echo "JAVA_HOME (SQLcl): ${JAVA_HOME:-}"
  fi
  echo "================================================================================
"
} | tee "${OUT_FILE}"

for name in "${SCRIPTS[@]}"; do
  f="${SQL_DIR}/${name}"
  if [[ ! -f "${f}" ]]; then
    echo "FAIL: nav faila ${f}" | tee -a "${OUT_FILE}"
    exit 1
  fi
  {
    echo ""
    echo "================================================================================
=== ${name} ===
================================================================================
"
  } | tee -a "${OUT_FILE}"
  set +e
  # Ceļš ar atstarpēm/unicode — @ izmanto relatīvo vārdu no sql/ mapes
  (
    cd "${SQL_DIR}" || exit 1
    run_client @"${name}"
  ) >>"${OUT_FILE}" 2>&1
  rc=$?
  set -e
  if [[ "${rc}" -ne 0 ]]; then
    echo "" | tee -a "${OUT_FILE}"
    echo "FAIL: ${name} — iziešanas kods ${rc}" | tee -a "${OUT_FILE}"
    echo "------ pēdējās ~50 rindas no loga (meklējiet ORA-): ------" >&2
    tail -n 50 "${OUT_FILE}" >&2
    exit "${rc}"
  fi
done

{
  echo ""
  echo "================================================================================
Pabeigts: $(date "+%Y-%m-%d %H:%M:%S")
Izvade: ${OUT_FILE}
================================================================================
"
} | tee -a "${OUT_FILE}"

echo "Gatavs: ${OUT_FILE}"
