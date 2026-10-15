-- =============================================================================
-- olo_prd_movilidad — Aurora PostgreSQL — PROVISIONING
-- Ambiente: prd | Base: olo_prd_movilidad_db
-- Ejecutar como: master (rds_superuser) conectado a la base 'postgres'
-- psql -v ON_ERROR_STOP=1 ... Generado por la skill aws-project-* (no editar a mano;
-- ajustar config.yaml y regenerar).
-- =============================================================================
\set ON_ERROR_STOP on
-- Variables requeridas: -v pass_ro=... -v pass_rw=... -v pass_ddl=... -v pass_admin=...
\if :{?pass_ro}
\else
  \echo 'Falta la variable psql pass_ro (-v pass_ro=...)'
  SELECT 1/0 AS falta_pass_ro;
\endif
\if :{?pass_rw}
\else
  \echo 'Falta la variable psql pass_rw (-v pass_rw=...)'
  SELECT 1/0 AS falta_pass_rw;
\endif
\if :{?pass_ddl}
\else
  \echo 'Falta la variable psql pass_ddl (-v pass_ddl=...)'
  SELECT 1/0 AS falta_pass_ddl;
\endif
\if :{?pass_admin}
\else
  \echo 'Falta la variable psql pass_admin (-v pass_admin=...)'
  SELECT 1/0 AS falta_pass_admin;
\endif

-- 0. Guarda: nunca ejecutar contra Supabase
DO $do$
BEGIN
  IF to_regclass('auth.users') IS NOT NULL AND to_regclass('storage.objects') IS NOT NULL THEN
    RAISE EXCEPTION 'Destino parece un proyecto Supabase (auth.users/storage.objects). Abortado.';
  END IF;
END
$do$;

-- 1. Política de contraseñas (>=12, mayúscula, minúscula, número, especial; no expiran)
SELECT set_config('dbkit.check_pass_ro', :'pass_ro', false) AS _ \gset
DO $do$
DECLARE p text := current_setting('dbkit.check_pass_ro');
BEGIN
  IF length(p) < 12 OR p !~ '[A-Z]' OR p !~ '[a-z]' OR p !~ '[0-9]' OR p !~ '[^A-Za-z0-9]' THEN
    RAISE EXCEPTION 'La contraseña pass_ro no cumple la política (>=12, mayúscula, minúscula, número, especial)';
  END IF;
  PERFORM set_config('dbkit.check_pass_ro', '', false);
END
$do$;
SELECT set_config('dbkit.check_pass_rw', :'pass_rw', false) AS _ \gset
DO $do$
DECLARE p text := current_setting('dbkit.check_pass_rw');
BEGIN
  IF length(p) < 12 OR p !~ '[A-Z]' OR p !~ '[a-z]' OR p !~ '[0-9]' OR p !~ '[^A-Za-z0-9]' THEN
    RAISE EXCEPTION 'La contraseña pass_rw no cumple la política (>=12, mayúscula, minúscula, número, especial)';
  END IF;
  PERFORM set_config('dbkit.check_pass_rw', '', false);
END
$do$;
SELECT set_config('dbkit.check_pass_ddl', :'pass_ddl', false) AS _ \gset
DO $do$
DECLARE p text := current_setting('dbkit.check_pass_ddl');
BEGIN
  IF length(p) < 12 OR p !~ '[A-Z]' OR p !~ '[a-z]' OR p !~ '[0-9]' OR p !~ '[^A-Za-z0-9]' THEN
    RAISE EXCEPTION 'La contraseña pass_ddl no cumple la política (>=12, mayúscula, minúscula, número, especial)';
  END IF;
  PERFORM set_config('dbkit.check_pass_ddl', '', false);
END
$do$;
SELECT set_config('dbkit.check_pass_admin', :'pass_admin', false) AS _ \gset
DO $do$
DECLARE p text := current_setting('dbkit.check_pass_admin');
BEGIN
  IF length(p) < 12 OR p !~ '[A-Z]' OR p !~ '[a-z]' OR p !~ '[0-9]' OR p !~ '[^A-Za-z0-9]' THEN
    RAISE EXCEPTION 'La contraseña pass_admin no cumple la política (>=12, mayúscula, minúscula, número, especial)';
  END IF;
  PERFORM set_config('dbkit.check_pass_admin', '', false);
END
$do$;

-- 2. Roles de grupo (NOLOGIN). Herencia: admin > ddl > rw > ro
SELECT format('CREATE ROLE %I NOLOGIN', 'ro_movilidad')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ro_movilidad') \gexec
SELECT format('CREATE ROLE %I NOLOGIN', 'rw_movilidad')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rw_movilidad') \gexec
SELECT format('CREATE ROLE %I NOLOGIN', 'ddl_movilidad')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddl_movilidad') \gexec
SELECT format('CREATE ROLE %I NOLOGIN', 'admin_movilidad')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_movilidad') \gexec
GRANT ro_movilidad TO rw_movilidad;
GRANT rw_movilidad TO ddl_movilidad;
GRANT ddl_movilidad TO admin_movilidad;
-- el master necesita membresía para SET ROLE, ALTER DEFAULT PRIVILEGES y OWNER de la base
SELECT format('GRANT %I TO %I', 'admin_movilidad', current_user) \gexec

-- 3. Usuarios (LOGIN) con contraseña parametrizada que no expira
SELECT format('CREATE ROLE %I LOGIN', 'usr_movilidad_report')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_report') \gexec
SELECT format('ALTER ROLE %I WITH LOGIN PASSWORD %L VALID UNTIL %L', 'usr_movilidad_report', :'pass_ro', 'infinity') \gexec
GRANT ro_movilidad TO usr_movilidad_report;
SELECT format('CREATE ROLE %I LOGIN', 'usr_movilidad_app')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_app') \gexec
SELECT format('ALTER ROLE %I WITH LOGIN PASSWORD %L VALID UNTIL %L', 'usr_movilidad_app', :'pass_rw', 'infinity') \gexec
GRANT rw_movilidad TO usr_movilidad_app;
SELECT format('CREATE ROLE %I LOGIN', 'usr_movilidad_deploy')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_deploy') \gexec
SELECT format('ALTER ROLE %I WITH LOGIN PASSWORD %L VALID UNTIL %L', 'usr_movilidad_deploy', :'pass_ddl', 'infinity') \gexec
GRANT ddl_movilidad TO usr_movilidad_deploy;
SELECT format('CREATE ROLE %I LOGIN', 'usr_movilidad_dba')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_dba') \gexec
SELECT format('ALTER ROLE %I WITH LOGIN PASSWORD %L VALID UNTIL %L', 'usr_movilidad_dba', :'pass_admin', 'infinity') \gexec
GRANT admin_movilidad TO usr_movilidad_dba;

-- 4. Base de datos (CREATE DATABASE no admite IF NOT EXISTS ni transacción)
SELECT format('CREATE DATABASE %I OWNER %I ENCODING %L', 'olo_prd_movilidad_db', 'admin_movilidad', 'UTF8')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'olo_prd_movilidad_db') \gexec
\connect olo_prd_movilidad_db
REVOKE ALL ON DATABASE olo_prd_movilidad_db FROM PUBLIC;
GRANT CONNECT, TEMPORARY ON DATABASE olo_prd_movilidad_db TO ro_movilidad;
GRANT ALL ON DATABASE olo_prd_movilidad_db TO admin_movilidad;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- 5. Esquemas, permisos y default privileges (se repite por esquema)
-- >>> PER_SCHEMA_BEGIN <<<
CREATE SCHEMA IF NOT EXISTS olo_prd_movilidad_sch_core AUTHORIZATION ddl_movilidad;
GRANT USAGE ON SCHEMA olo_prd_movilidad_sch_core TO ro_movilidad;
GRANT ALL ON SCHEMA olo_prd_movilidad_sch_core TO admin_movilidad;
GRANT SELECT ON ALL TABLES IN SCHEMA olo_prd_movilidad_sch_core TO ro_movilidad;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA olo_prd_movilidad_sch_core TO ro_movilidad;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA olo_prd_movilidad_sch_core TO rw_movilidad;
GRANT USAGE, UPDATE ON ALL SEQUENCES IN SCHEMA olo_prd_movilidad_sch_core TO rw_movilidad;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA olo_prd_movilidad_sch_core TO rw_movilidad;
GRANT ALL ON ALL TABLES IN SCHEMA olo_prd_movilidad_sch_core TO admin_movilidad;
GRANT ALL ON ALL SEQUENCES IN SCHEMA olo_prd_movilidad_sch_core TO admin_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE ddl_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT SELECT ON TABLES TO ro_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE ddl_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT SELECT ON SEQUENCES TO ro_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE ddl_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT INSERT, UPDATE, DELETE ON TABLES TO rw_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE ddl_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT USAGE, UPDATE ON SEQUENCES TO rw_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE ddl_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT EXECUTE ON FUNCTIONS TO rw_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE ddl_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT ALL ON TABLES TO admin_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT SELECT ON TABLES TO ro_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT SELECT ON SEQUENCES TO ro_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT INSERT, UPDATE, DELETE ON TABLES TO rw_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT USAGE, UPDATE ON SEQUENCES TO rw_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT EXECUTE ON FUNCTIONS TO rw_movilidad;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_movilidad IN SCHEMA olo_prd_movilidad_sch_core GRANT ALL ON TABLES TO admin_movilidad;
-- >>> PER_SCHEMA_END <<<

-- 6. Funciones: sin EXECUTE para PUBLIC en objetos futuros
ALTER DEFAULT PRIVILEGES FOR ROLE ddl_movilidad REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_movilidad REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- 7. search_path fijado por usuario (la app NO ejecuta SET en runtime → sin pinning en RDS Proxy)
ALTER ROLE usr_movilidad_report IN DATABASE olo_prd_movilidad_db SET search_path = olo_prd_movilidad_sch_core;
ALTER ROLE usr_movilidad_app IN DATABASE olo_prd_movilidad_db SET search_path = olo_prd_movilidad_sch_core;
ALTER ROLE usr_movilidad_deploy IN DATABASE olo_prd_movilidad_db SET search_path = olo_prd_movilidad_sch_core;
ALTER ROLE usr_movilidad_dba IN DATABASE olo_prd_movilidad_db SET search_path = olo_prd_movilidad_sch_core;

-- 8. Extensiones (compatibles o con adaptación documentada)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA olo_prd_movilidad_sch_core;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA olo_prd_movilidad_sch_core;
-- NO SE CREA (supabase_specific): supabase_vault — Supabase-specific: usar Secrets Manager.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA olo_prd_movilidad_sch_core;

\echo 'Provisioning completado.'
