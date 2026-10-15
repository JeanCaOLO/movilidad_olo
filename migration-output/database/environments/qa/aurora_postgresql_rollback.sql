-- =============================================================================
-- olo_qa_movilidad — Aurora PostgreSQL — ROLLBACK
-- Ambiente: qa | Base: olo_qa_movilidad_db
-- Ejecutar como: master conectado a olo_qa_movilidad_db. Orden descendente; NUNCA contra Supabase
-- psql -v ON_ERROR_STOP=1 ... Generado por la skill aws-project-* (no editar a mano;
-- ajustar config.yaml y regenerar).
-- =============================================================================
\set ON_ERROR_STOP on
DO $do$
BEGIN
  IF current_database() <> 'olo_qa_movilidad_db' THEN
    RAISE EXCEPTION 'Rollback abortado: base actual % distinta de olo_qa_movilidad_db', current_database();
  END IF;
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname IN ('auth', 'storage', 'supabase_functions', 'realtime')) THEN
    RAISE EXCEPTION 'Rollback abortado: se detectaron esquemas de Supabase en la base actual.';
  END IF;
END
$do$;
BEGIN;
-- 0a. extensiones del aplicativo (la base es exclusiva del aplicativo; arrastran sus índices)
DROP EXTENSION IF EXISTS "uuid-ossp" CASCADE;
DROP EXTENSION IF EXISTS pgcrypto CASCADE;
DROP EXTENSION IF EXISTS pg_stat_statements CASCADE;
-- 0b. todo lo que pertenece al rol ddl del aplicativo: lo generado por la skill y lo agregado por
--     database/changes (incluida tbl_schema_changes) aunque dependa entre sí. Un objeto de OTRO
--     dueño que dependa de estos hace fallar el rollback (DROP OWNED no usa CASCADE).
DROP OWNED BY ddl_movilidad;
-- 1. triggers y políticas
DO $do$
BEGIN
  IF to_regclass('olo_qa_movilidad_sch_core.tbl_olo_movilidad_kv') IS NOT NULL THEN DROP TRIGGER IF EXISTS trg_olo_movilidad_kv_touch ON olo_qa_movilidad_sch_core.tbl_olo_movilidad_kv; END IF;
END
$do$;
-- 2. vistas materializadas y vistas
-- 3. FK
ALTER TABLE IF EXISTS olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios DROP CONSTRAINT IF EXISTS fk_olo_movilidad_usuarios_app_users;
-- 4. tablas (orden topológico inverso)
DROP TABLE IF EXISTS olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios;
DROP TABLE IF EXISTS olo_qa_movilidad_sch_core.tbl_olo_movilidad_kv;
-- 5. funciones
DROP ROUTINE IF EXISTS olo_qa_movilidad_sch_core.fn_olo_movilidad_kv_touch();
DROP ROUTINE IF EXISTS olo_qa_movilidad_sch_core.fn_olo_mov_pais_de_fila(k text, v jsonb);
DROP ROUTINE IF EXISTS olo_qa_movilidad_sch_core.fn_olo_mov_pais_actual();
DROP ROUTINE IF EXISTS olo_qa_movilidad_sch_core.fn_olo_mov_es_admin();
DROP TABLE IF EXISTS olo_qa_movilidad_sch_core.tbl_app_users;
DROP FUNCTION IF EXISTS olo_qa_movilidad_sch_core.fn_auth_uid();
DROP FUNCTION IF EXISTS olo_qa_movilidad_sch_core.fn_auth_role();
DROP FUNCTION IF EXISTS olo_qa_movilidad_sch_core.fn_auth_email();
DROP FUNCTION IF EXISTS olo_qa_movilidad_sch_core.fn_auth_jwt();
-- 6. secuencias y tipos
-- 7. extensiones
DROP EXTENSION IF EXISTS "uuid-ossp";
DROP EXTENSION IF EXISTS pgcrypto;
DROP EXTENSION IF EXISTS pg_stat_statements;
-- 8. esquemas (RESTRICT: falla si quedan objetos no generados por esta skill)
DROP SCHEMA IF EXISTS olo_qa_movilidad_sch_core;
-- 9. privilegios y default privileges de los roles en esta base
DROP OWNED BY ro_movilidad, rw_movilidad, ddl_movilidad, admin_movilidad;
COMMIT;

-- 10. Base de datos, usuarios y roles: requiere conexión a 'postgres' y CONFIRMACIÓN HUMANA.
--     Descomentar el bloque y ejecutarlo aparte.
-- >>> MANUAL_BEGIN <<<
-- \connect postgres
-- DROP DATABASE IF EXISTS olo_qa_movilidad_db;
-- DROP ROLE IF EXISTS usr_movilidad_dba;
-- DROP ROLE IF EXISTS usr_movilidad_deploy;
-- DROP ROLE IF EXISTS usr_movilidad_app;
-- DROP ROLE IF EXISTS usr_movilidad_report;
-- REVOKE admin_movilidad FROM CURRENT_USER;
-- DROP ROLE IF EXISTS admin_movilidad;
-- DROP ROLE IF EXISTS ddl_movilidad;
-- DROP ROLE IF EXISTS rw_movilidad;
-- DROP ROLE IF EXISTS ro_movilidad;
-- >>> MANUAL_END <<<

\echo 'Rollback de objetos completado.'
