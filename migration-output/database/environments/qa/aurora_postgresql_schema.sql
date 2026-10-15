-- =============================================================================
-- olo_qa_movilidad — Aurora PostgreSQL — SCHEMA
-- Ambiente: qa | Base: olo_qa_movilidad_db
-- Ejecutar como: master o usr_movilidad_deploy conectado a olo_qa_movilidad_db
-- psql -v ON_ERROR_STOP=1 ... Generado por la skill aws-project-* (no editar a mano;
-- ajustar config.yaml y regenerar).
-- =============================================================================
\set ON_ERROR_STOP on
DO $do$
BEGIN
  IF current_database() <> 'olo_qa_movilidad_db' THEN
    RAISE EXCEPTION 'Base actual % distinta de la esperada olo_qa_movilidad_db', current_database();
  END IF;
  IF to_regclass('auth.users') IS NOT NULL THEN
    RAISE EXCEPTION 'Destino parece Supabase. Abortado.';
  END IF;
END
$do$;
BEGIN;
SET LOCAL ROLE ddl_movilidad;
SET LOCAL search_path = olo_qa_movilidad_sch_core;
SET LOCAL check_function_bodies = off;

-- ---------------------------------------------------------------- tipos

-- ---------------------------------------------------------------- secuencias

-- ---------------------------------------------------------------- auth: espejo de usuarios + contexto
-- Reemplaza auth.users (Cognito es el IdP). El backend vincula cognito_sub en el primer login.
CREATE TABLE IF NOT EXISTS olo_qa_movilidad_sch_core.tbl_app_users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  cognito_sub text,
  email text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_app_users PRIMARY KEY (id),
  CONSTRAINT uq_app_users_cognito_sub UNIQUE (cognito_sub)
);
CREATE INDEX IF NOT EXISTS idx_app_users_email_expr ON olo_qa_movilidad_sch_core.tbl_app_users (lower(email));
-- Contexto de sesión por transacción (set_config(..., true)) fijado por PostgresUnitOfWork.
CREATE OR REPLACE FUNCTION olo_qa_movilidad_sch_core.fn_auth_uid() RETURNS uuid
  LANGUAGE sql STABLE PARALLEL SAFE AS $fn$SELECT nullif(current_setting('app.user_id', true), '')::uuid$fn$;
CREATE OR REPLACE FUNCTION olo_qa_movilidad_sch_core.fn_auth_role() RETURNS text
  LANGUAGE sql STABLE PARALLEL SAFE AS $fn$SELECT coalesce(nullif(current_setting('app.role', true), ''), 'anon')$fn$;
CREATE OR REPLACE FUNCTION olo_qa_movilidad_sch_core.fn_auth_email() RETURNS text
  LANGUAGE sql STABLE PARALLEL SAFE AS $fn$SELECT nullif(current_setting('app.email', true), '')$fn$;
CREATE OR REPLACE FUNCTION olo_qa_movilidad_sch_core.fn_auth_jwt() RETURNS jsonb
  LANGUAGE sql STABLE PARALLEL SAFE AS $fn$SELECT coalesce(nullif(current_setting('app.jwt_claims', true), ''), '{}')::jsonb$fn$;

-- ---------------------------------------------------------------- funciones (previas a tablas)
CREATE OR REPLACE FUNCTION olo_qa_movilidad_sch_core.fn_olo_mov_es_admin()
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO olo_qa_movilidad_sch_core
AS $fn$
  select coalesce(
    (select u.es_admin or u.pais is null
       from olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios u
      where u.user_id = olo_qa_movilidad_sch_core.fn_auth_uid()),
    false)
$fn$;
CREATE OR REPLACE FUNCTION olo_qa_movilidad_sch_core.fn_olo_mov_pais_actual()
  RETURNS text
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO olo_qa_movilidad_sch_core
AS $fn$
  select u.pais
  from olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios u
  where u.user_id = olo_qa_movilidad_sch_core.fn_auth_uid()
$fn$;
CREATE OR REPLACE FUNCTION olo_qa_movilidad_sch_core.fn_olo_mov_pais_de_fila(k text, v jsonb)
  RETURNS text
  LANGUAGE sql
  IMMUTABLE
AS $fn$
  select case
           when k like 'colaborador:%'
             then coalesce(nullif(upper(v->>'pais'), ''), 'CR')
           else null                      -- claves no-colaborador: sin país
         end
$fn$;
CREATE OR REPLACE FUNCTION olo_qa_movilidad_sch_core.fn_olo_movilidad_kv_touch()
  RETURNS trigger
  LANGUAGE plpgsql
  VOLATILE
AS $fn$
begin
  new.updated_at = now();
  return new;
end;
$fn$;
-- ---------------------------------------------------------------- tablas
CREATE TABLE IF NOT EXISTS olo_qa_movilidad_sch_core.tbl_olo_movilidad_kv (
  key text NOT NULL,
  value jsonb NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios (
  user_id uuid NOT NULL,
  email text,
  pais text,
  es_admin boolean DEFAULT false NOT NULL,
  creado_en timestamp with time zone DEFAULT now() NOT NULL
);

-- ---------------------------------------------------------------- constraints (PK/UQ/CK/EX → FK)
DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'olo_qa_movilidad_sch_core.tbl_olo_movilidad_kv'::regclass
                 AND conname = 'pk_olo_movilidad_kv') THEN
    ALTER TABLE olo_qa_movilidad_sch_core.tbl_olo_movilidad_kv ADD CONSTRAINT pk_olo_movilidad_kv PRIMARY KEY (key);
  END IF;
END
$do$;
DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios'::regclass
                 AND conname = 'pk_olo_movilidad_usuarios') THEN
    ALTER TABLE olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios ADD CONSTRAINT pk_olo_movilidad_usuarios PRIMARY KEY (user_id);
  END IF;
END
$do$;
DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios'::regclass
                 AND conname = 'fk_olo_movilidad_usuarios_app_users') THEN
    ALTER TABLE olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios ADD CONSTRAINT fk_olo_movilidad_usuarios_app_users FOREIGN KEY (user_id) REFERENCES olo_qa_movilidad_sch_core.tbl_app_users(id) ON DELETE CASCADE;
  END IF;
END
$do$;

-- ---------------------------------------------------------------- índices
CREATE INDEX IF NOT EXISTS idx_olo_movilidad_kv_key ON olo_qa_movilidad_sch_core.tbl_olo_movilidad_kv USING btree (key text_pattern_ops);

-- ---------------------------------------------------------------- funciones (usan tipos de tabla)
-- ---------------------------------------------------------------- vistas y vistas materializadas

-- ---------------------------------------------------------------- índices de vistas materializadas

-- ---------------------------------------------------------------- triggers
DROP TRIGGER IF EXISTS trg_olo_movilidad_kv_touch ON olo_qa_movilidad_sch_core.tbl_olo_movilidad_kv;
CREATE TRIGGER trg_olo_movilidad_kv_touch BEFORE UPDATE ON olo_qa_movilidad_sch_core.tbl_olo_movilidad_kv FOR EACH ROW EXECUTE FUNCTION fn_olo_movilidad_kv_touch();

-- RLS: rls_mode=backend → la autorización vive en los use cases (ver generation-report.json).

-- ---------------------------------------------------------------- comentarios
COMMENT ON TABLE olo_qa_movilidad_sch_core.tbl_olo_movilidad_usuarios IS 'Asigna a cada usuario autenticado su país. pais NULL o es_admin=true => acceso a todos los países.';

COMMIT;

\echo 'Esquema creado/actualizado.'
