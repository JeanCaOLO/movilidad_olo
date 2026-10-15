-- =============================================================================
-- olo_dev_movilidad — Aurora PostgreSQL — VALIDATION
-- Ambiente: dev | Base: olo_dev_movilidad_db
-- Ejecutar como: cualquier usuario con lectura de catálogo, conectado a olo_dev_movilidad_db
-- psql -v ON_ERROR_STOP=1 ... Generado por la skill aws-project-* (no editar a mano;
-- ajustar config.yaml y regenerar).
-- =============================================================================
-- Cada fila: objeto, tipo, estado (OK | FALTA). La última fila es TOTAL_FALTA (debe ser 0).
WITH checks(objeto, tipo, ok) AS (VALUES
  ('olo_dev_movilidad_db', 'database', coalesce(EXISTS (SELECT 1 FROM pg_database WHERE datname = 'olo_dev_movilidad_db'), false)),
  ('ro_movilidad', 'role', coalesce(EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ro_movilidad' AND NOT rolcanlogin), false)),
  ('rw_movilidad', 'role', coalesce(EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rw_movilidad' AND NOT rolcanlogin), false)),
  ('ddl_movilidad', 'role', coalesce(EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddl_movilidad' AND NOT rolcanlogin), false)),
  ('admin_movilidad', 'role', coalesce(EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_movilidad' AND NOT rolcanlogin), false)),
  ('usr_movilidad_report', 'user', coalesce(EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_report' AND rolcanlogin), false)),
  ('usr_movilidad_report ∈ ro_movilidad', 'membership', coalesce((SELECT pg_has_role('usr_movilidad_report', 'ro_movilidad', 'MEMBER') WHERE EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_report') AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ro_movilidad')), false)),
  ('usr_movilidad_app', 'user', coalesce(EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_app' AND rolcanlogin), false)),
  ('usr_movilidad_app ∈ rw_movilidad', 'membership', coalesce((SELECT pg_has_role('usr_movilidad_app', 'rw_movilidad', 'MEMBER') WHERE EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_app') AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rw_movilidad')), false)),
  ('usr_movilidad_deploy', 'user', coalesce(EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_deploy' AND rolcanlogin), false)),
  ('usr_movilidad_deploy ∈ ddl_movilidad', 'membership', coalesce((SELECT pg_has_role('usr_movilidad_deploy', 'ddl_movilidad', 'MEMBER') WHERE EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_deploy') AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ddl_movilidad')), false)),
  ('usr_movilidad_dba', 'user', coalesce(EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_dba' AND rolcanlogin), false)),
  ('usr_movilidad_dba ∈ admin_movilidad', 'membership', coalesce((SELECT pg_has_role('usr_movilidad_dba', 'admin_movilidad', 'MEMBER') WHERE EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_dba') AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_movilidad')), false)),
  ('rw_movilidad > ro_movilidad', 'inheritance', coalesce(EXISTS (SELECT 1 FROM pg_auth_members m JOIN pg_roles a ON a.oid = m.roleid JOIN pg_roles b ON b.oid = m.member WHERE a.rolname = 'ro_movilidad' AND b.rolname = 'rw_movilidad'), false)),
  ('ddl_movilidad > rw_movilidad', 'inheritance', coalesce(EXISTS (SELECT 1 FROM pg_auth_members m JOIN pg_roles a ON a.oid = m.roleid JOIN pg_roles b ON b.oid = m.member WHERE a.rolname = 'rw_movilidad' AND b.rolname = 'ddl_movilidad'), false)),
  ('admin_movilidad > ddl_movilidad', 'inheritance', coalesce(EXISTS (SELECT 1 FROM pg_auth_members m JOIN pg_roles a ON a.oid = m.roleid JOIN pg_roles b ON b.oid = m.member WHERE a.rolname = 'ddl_movilidad' AND b.rolname = 'admin_movilidad'), false)),
  ('olo_dev_movilidad_sch_core', 'schema', coalesce(EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'olo_dev_movilidad_sch_core'), false)),
  ('olo_dev_movilidad_sch_core USAGE ro_movilidad', 'privilege', coalesce((SELECT has_schema_privilege('ro_movilidad', 'olo_dev_movilidad_sch_core', 'USAGE') WHERE EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'olo_dev_movilidad_sch_core') AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ro_movilidad')), false)),
  ('olo_dev_movilidad_sch_core default privileges', 'default_acl', coalesce(EXISTS (SELECT 1 FROM pg_default_acl d JOIN pg_namespace n ON n.oid = d.defaclnamespace WHERE n.nspname = 'olo_dev_movilidad_sch_core'), false)),
  ('search_path usr_movilidad_app', 'role_setting', coalesce(EXISTS (SELECT 1 FROM pg_db_role_setting s JOIN pg_roles r ON r.oid = s.setrole JOIN pg_database d ON d.oid = s.setdatabase WHERE r.rolname = 'usr_movilidad_app' AND d.datname = 'olo_dev_movilidad_db' AND array_to_string(s.setconfig, ',') LIKE 'search_path=%'), false)),
  ('pg_stat_statements', 'extension', coalesce(EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements'), false)),
  ('pgcrypto', 'extension', coalesce(EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto'), false)),
  ('uuid-ossp', 'extension', coalesce(EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp'), false)),
  ('olo_dev_movilidad_sch_core.tbl_app_users', 'table', coalesce(EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.oid = to_regclass('olo_dev_movilidad_sch_core.tbl_app_users') AND c.relkind IN ('r')), false)),
  ('olo_dev_movilidad_sch_core.fn_auth_uid', 'function', coalesce((to_regprocedure('olo_dev_movilidad_sch_core.fn_auth_uid()') IS NOT NULL), false)),
  ('olo_dev_movilidad_sch_core.fn_auth_role', 'function', coalesce((to_regprocedure('olo_dev_movilidad_sch_core.fn_auth_role()') IS NOT NULL), false)),
  ('olo_dev_movilidad_sch_core.fn_auth_email', 'function', coalesce((to_regprocedure('olo_dev_movilidad_sch_core.fn_auth_email()') IS NOT NULL), false)),
  ('olo_dev_movilidad_sch_core.fn_auth_jwt', 'function', coalesce((to_regprocedure('olo_dev_movilidad_sch_core.fn_auth_jwt()') IS NOT NULL), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv', 'table', coalesce(EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.oid = to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv') AND c.relkind IN ('r','p')), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv (3 columnas esperadas)', 'columns', coalesce(((SELECT count(*) FROM pg_attribute WHERE attrelid = to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv') AND attnum > 0 AND NOT attisdropped AND attname = ANY (ARRAY['key', 'value', 'updated_at']::name[])) = 3), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv INSERT usr_movilidad_app', 'privilege', coalesce((SELECT has_table_privilege('usr_movilidad_app', to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv'), 'INSERT') WHERE to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv') IS NOT NULL AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_app')), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv SELECT usr_movilidad_report', 'privilege', coalesce((SELECT has_table_privilege('usr_movilidad_report', to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv'), 'SELECT') WHERE to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv') IS NOT NULL AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_report')), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios', 'table', coalesce(EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.oid = to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios') AND c.relkind IN ('r','p')), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios (5 columnas esperadas)', 'columns', coalesce(((SELECT count(*) FROM pg_attribute WHERE attrelid = to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios') AND attnum > 0 AND NOT attisdropped AND attname = ANY (ARRAY['user_id', 'email', 'pais', 'es_admin', 'creado_en']::name[])) = 5), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios INSERT usr_movilidad_app', 'privilege', coalesce((SELECT has_table_privilege('usr_movilidad_app', to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios'), 'INSERT') WHERE to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios') IS NOT NULL AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_app')), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios SELECT usr_movilidad_report', 'privilege', coalesce((SELECT has_table_privilege('usr_movilidad_report', to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios'), 'SELECT') WHERE to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios') IS NOT NULL AND EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usr_movilidad_report')), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv.pk_olo_movilidad_kv', 'constraint_p', coalesce(EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv') AND conname = 'pk_olo_movilidad_kv'), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios.fk_olo_movilidad_usuarios_app_users', 'constraint_f', coalesce(EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios') AND conname = 'fk_olo_movilidad_usuarios_app_users'), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios.pk_olo_movilidad_usuarios', 'constraint_p', coalesce(EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios') AND conname = 'pk_olo_movilidad_usuarios'), false)),
  ('olo_dev_movilidad_sch_core.idx_olo_movilidad_kv_key', 'index', coalesce(EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.oid = to_regclass('olo_dev_movilidad_sch_core.idx_olo_movilidad_kv_key') AND c.relkind IN ('i','I')), false)),
  ('olo_dev_movilidad_sch_core.fn_olo_mov_es_admin()', 'function', coalesce((to_regprocedure('olo_dev_movilidad_sch_core.fn_olo_mov_es_admin()') IS NOT NULL), false)),
  ('olo_dev_movilidad_sch_core.fn_olo_mov_pais_actual()', 'function', coalesce((to_regprocedure('olo_dev_movilidad_sch_core.fn_olo_mov_pais_actual()') IS NOT NULL), false)),
  ('olo_dev_movilidad_sch_core.fn_olo_mov_pais_de_fila(text, jsonb)', 'function', coalesce((to_regprocedure('olo_dev_movilidad_sch_core.fn_olo_mov_pais_de_fila(text, jsonb)') IS NOT NULL), false)),
  ('olo_dev_movilidad_sch_core.fn_olo_movilidad_kv_touch()', 'function', coalesce((to_regprocedure('olo_dev_movilidad_sch_core.fn_olo_movilidad_kv_touch()') IS NOT NULL), false)),
  ('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv.trg_olo_movilidad_kv_touch', 'trigger', coalesce(EXISTS (SELECT 1 FROM pg_trigger WHERE tgrelid = to_regclass('olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv') AND tgname = 'trg_olo_movilidad_kv_touch' AND NOT tgisinternal), false))
)
SELECT objeto, tipo, CASE WHEN ok THEN 'OK' ELSE 'FALTA' END AS estado FROM checks
UNION ALL
SELECT 'TOTAL_FALTA', 'resumen', count(*) FILTER (WHERE NOT ok)::text FROM checks;
