#!/usr/bin/env bash
# data_migration.sh — copia de datos Supabase → Aurora (dev). Generado por aws-project-migrator.
# La ORIGEN se abre en modo solo lectura (default_transaction_read_only=on): nunca se modifica Supabase.
#   SOURCE_DATABASE_URL  conexión directa (no pooler) al Postgres de Supabase
#   TARGET_DATABASE_URL  Aurora olo_dev_movilidad_db como master o usr_movilidad_deploy
#   DISABLE_TRIGGERS=1   (por defecto) usa session_replication_role=replica en destino (requiere rds_superuser)
#   ALLOW_NON_EMPTY=1    permite continuar si el destino ya tiene filas (por defecto aborta)
set -euo pipefail
: "${SOURCE_DATABASE_URL:?Defina SOURCE_DATABASE_URL}"
: "${TARGET_DATABASE_URL:?Defina TARGET_DATABASE_URL}"
DISABLE_TRIGGERS="${DISABLE_TRIGGERS:-1}"
SRC_OPTS="-c default_transaction_read_only=on"
DST_OPTS="-c role=ddl_movilidad"
if [ "$DISABLE_TRIGGERS" = "1" ]; then DST_OPTS="$DST_OPTS -c session_replication_role=replica"; fi

src() { PGOPTIONS="$SRC_OPTS" psql "$SOURCE_DATABASE_URL" -v ON_ERROR_STOP=1 -X -q -At "$@"; }
dst() { PGOPTIONS="$DST_OPTS" psql "$TARGET_DATABASE_URL" -v ON_ERROR_STOP=1 -X -q -At "$@"; }

# Guardas
[ "$(dst -c "SELECT current_database()")" = "olo_dev_movilidad_db" ] || { echo "Destino no es olo_dev_movilidad_db"; exit 1; }
[ "$(dst -c "SELECT to_regclass('auth.users') IS NULL")" = "t" ] || { echo "Destino parece Supabase"; exit 1; }
[ "$(src -c "SELECT to_regclass('auth.users') IS NOT NULL")" = "t" ] || echo "AVISO: origen sin auth.users"

copy_table() {  # $1 origen, $2 destino, $3 columnas
  if [ "${ALLOW_NON_EMPTY:-0}" != "1" ] && [ "$(dst -c "SELECT EXISTS (SELECT 1 FROM $2)")" = "t" ]; then
    echo "Destino $2 no está vacío (ALLOW_NON_EMPTY=1 para continuar)"; exit 1
  fi
  echo "Copiando $1 → $2"
  src -c "\\copy (SELECT $3 FROM $1) TO STDOUT" | dst -c "\\copy $2 ($3) FROM STDIN"
}

compare_count() {
  local a b; a="$(src -c "SELECT count(*) FROM $1")"; b="$(dst -c "SELECT count(*) FROM $2")"
  if [ "$a" = "$b" ]; then echo "OK      $2 $b"; else echo "DIFERENCIA $2 origen=$a destino=$b"; FAILED=1; fi
}

# 1. Usuarios: auth.users → olo_dev_movilidad_sch_core.tbl_app_users (cognito_sub se vincula en el primer login por email verificado)
copy_table "auth.users" "olo_dev_movilidad_sch_core.tbl_app_users" "id, email, created_at, updated_at"

# 2. Tablas en orden topológico de FK
copy_table "public.olo_movilidad_kv" "olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv" "key, value, updated_at"
copy_table "public.olo_movilidad_usuarios" "olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios" "user_id, email, pais, es_admin, creado_en"

# 3. Secuencias / identity
dst <<'SQL'
SELECT 1;

SQL

# 4. Conteos origen vs destino
FAILED=0
compare_count "auth.users" "olo_dev_movilidad_sch_core.tbl_app_users"
compare_count "public.olo_movilidad_kv" "olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv"
compare_count "public.olo_movilidad_usuarios" "olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios"
[ "$FAILED" = "0" ] && echo "Migración de datos verificada." || { echo "Hay diferencias de conteo"; exit 1; }
