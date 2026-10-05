-- ============================================================================
--  Movilidad de Colaboradores · Soporte multi-país a nivel de base de datos
--  Proyecto Supabase: olo_movilidad_kv  (tabla key-value: key TEXT, value JSONB)
-- ----------------------------------------------------------------------------
--  OBJETIVO
--    Permitir que ciertos usuarios SOLO vean/manipulen datos de su país, con
--    enforcement real en la base (no solo en la UI).
--
--  PRINCIPIOS (importante):
--    * ADITIVO y NO DESTRUCTIVO: este script NO borra ni modifica ningún dato
--      existente. Solo crea objetos nuevos (tabla de usuarios, funciones y
--      políticas). Puedes ejecutarlo sin miedo sobre datos ya cargados.
--    * Los registros que ya existen NO tienen el campo `pais` dentro de su JSON.
--      Se tratan como Costa Rica ('CR') por DEFECTO al leer, igual que hace la
--      app en el front (coalesce a 'CR').
--    * El país de un colaborador vive dentro del JSON: value->>'pais'.
--      Las claves de colaborador tienen el prefijo 'colaborador:'.
--
--  MODELO DE ESTE SCRIPT = CAMINO B (login solo para administración):
--    * El rol `anon` (la app con anon key y los enlaces #c=/#g= de jefes y
--      gerentes) conserva acceso completo, para no romper el flujo actual.
--    * El rol `authenticated` (administradores que inician sesión) queda
--      acotado por país según olo_movilidad_usuarios.
--    => El aislamiento por país es DURO solo para admins autenticados; para
--       quien use la anon key, la acotación es a nivel de app (el hash).
--
--  ORDEN SEGURO DE APLICACIÓN (muy importante):
--    1) Primero implementa/prueba el login en la app (ya está en index.html /
--       index_v2.html) con tu usuario admin.
--    2) Recién cuando confirmes que entras bien, ejecuta ESTE script.
--    Como el rol anon mantiene acceso, la app NO se queda sin datos al aplicarlo.
-- ============================================================================

-- Ejecuta todo en el editor SQL de Supabase (una sola corrida).

begin;

-- ----------------------------------------------------------------------------
-- 1) Tabla que mapea cada usuario autenticado a su país (y si es admin global).
--    pais = NULL  -> acceso a TODOS los países (administrador global)
--    pais = 'CR'  -> solo Costa Rica, etc.
-- ----------------------------------------------------------------------------
create table if not exists public.olo_movilidad_usuarios (
  user_id   uuid primary key references auth.users(id) on delete cascade,
  email     text,
  pais      text,                 -- código ISO corto: CR, PA, GT, SV, HN, NI, DO. NULL = todos
  es_admin  boolean not null default false,
  creado_en timestamptz not null default now()
);

comment on table public.olo_movilidad_usuarios is
  'Asigna a cada usuario autenticado su país. pais NULL o es_admin=true => acceso a todos los países.';

-- ----------------------------------------------------------------------------
-- 2) Funciones de ayuda: país del usuario actual y si es admin global.
--    SECURITY DEFINER para poder leer la tabla de mapeo sin exponerla.
-- ----------------------------------------------------------------------------
create or replace function public.olo_mov_pais_actual()
returns text
language sql stable security definer set search_path = public as $$
  select u.pais
  from public.olo_movilidad_usuarios u
  where u.user_id = auth.uid()
$$;

create or replace function public.olo_mov_es_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select u.es_admin or u.pais is null
       from public.olo_movilidad_usuarios u
      where u.user_id = auth.uid()),
    false)
$$;

-- País efectivo de una fila del KV. Solo aplica a claves 'colaborador:%'.
-- Registros sin `pais` => 'CR' (Costa Rica) por defecto. NO modifica el dato.
create or replace function public.olo_mov_pais_de_fila(k text, v jsonb)
returns text
language sql immutable as $$
  select case
           when k like 'colaborador:%'
             then coalesce(nullif(upper(v->>'pais'), ''), 'CR')
           else null                      -- claves no-colaborador: sin país
         end
$$;

-- ----------------------------------------------------------------------------
-- 3) Habilitar RLS en la tabla KV y definir políticas por país.
--
--    Lógica de acceso para cada fila:
--      * admin global (pais NULL / es_admin)         -> ve y edita TODO
--      * usuario con país P                           -> solo filas cuyo país = P
--      * claves que NO son 'colaborador:%' (directorio,
--        config, evaluacion:, historico:)            -> visibles para todos los
--        usuarios autenticados (no llevan país propio; el filtrado fino de
--        evaluaciones/histórico lo hace la app cruzando con el colaborador).
--
--    AJUSTA esto a tu gusto: si quieres que evaluaciones/histórico también se
--    aislen por país a nivel de BD, habría que guardar el país dentro de esos
--    JSON o derivarlo por join (ver nota al final).
-- ----------------------------------------------------------------------------
alter table public.olo_movilidad_kv enable row level security;

-- Limpia políticas previas con el mismo nombre (idempotente, no toca datos).
drop policy if exists olo_mov_kv_select on public.olo_movilidad_kv;
drop policy if exists olo_mov_kv_insert on public.olo_movilidad_kv;
drop policy if exists olo_mov_kv_update on public.olo_movilidad_kv;
drop policy if exists olo_mov_kv_delete on public.olo_movilidad_kv;

-- Expresión reutilizable de "esta fila es accesible para el usuario actual".
--   true si: es admin global
--        OR  la clave no es de colaborador (recurso compartido)
--        OR  el país de la fila coincide con el país del usuario
create policy olo_mov_kv_select on public.olo_movilidad_kv
  for select to authenticated
  using (
    public.olo_mov_es_admin()
    or public.olo_mov_pais_de_fila(key, value) is null
    or public.olo_mov_pais_de_fila(key, value) = public.olo_mov_pais_actual()
  );

create policy olo_mov_kv_insert on public.olo_movilidad_kv
  for insert to authenticated
  with check (
    public.olo_mov_es_admin()
    or public.olo_mov_pais_de_fila(key, value) is null
    or public.olo_mov_pais_de_fila(key, value) = public.olo_mov_pais_actual()
  );

create policy olo_mov_kv_update on public.olo_movilidad_kv
  for update to authenticated
  using (
    public.olo_mov_es_admin()
    or public.olo_mov_pais_de_fila(key, value) is null
    or public.olo_mov_pais_de_fila(key, value) = public.olo_mov_pais_actual()
  )
  with check (
    public.olo_mov_es_admin()
    or public.olo_mov_pais_de_fila(key, value) is null
    or public.olo_mov_pais_de_fila(key, value) = public.olo_mov_pais_actual()
  );

create policy olo_mov_kv_delete on public.olo_movilidad_kv
  for delete to authenticated
  using (
    public.olo_mov_es_admin()
    or public.olo_mov_pais_de_fila(key, value) is null
    or public.olo_mov_pais_de_fila(key, value) = public.olo_mov_pais_actual()
  );

-- ----------------------------------------------------------------------------
-- 3-bis) CAMINO B: acceso para el rol `anon` (la app usa la anon key y los
--        enlaces #c=/#g= de jefes/gerentes entran SIN login). Para no romper
--        nada, el rol anon conserva acceso completo, como hoy.
--
--        IMPORTANTE / límite de seguridad: por esto, el aislamiento por país
--        es DURO solo para administradores autenticados. Cualquiera con la
--        anon key (p. ej. desde los enlaces) sigue con acceso total a nivel BD;
--        su acotación por equipo/país es a nivel de aplicación (el hash).
--        Si en el futuro quieres aislamiento criptográfico total, hay que pedir
--        login a todos (camino A) y ELIMINAR estas cuatro políticas `anon`.
-- ----------------------------------------------------------------------------
drop policy if exists olo_mov_kv_anon_select on public.olo_movilidad_kv;
drop policy if exists olo_mov_kv_anon_insert on public.olo_movilidad_kv;
drop policy if exists olo_mov_kv_anon_update on public.olo_movilidad_kv;
drop policy if exists olo_mov_kv_anon_delete on public.olo_movilidad_kv;

create policy olo_mov_kv_anon_select on public.olo_movilidad_kv
  for select to anon using ( true );
create policy olo_mov_kv_anon_insert on public.olo_movilidad_kv
  for insert to anon with check ( true );
create policy olo_mov_kv_anon_update on public.olo_movilidad_kv
  for update to anon using ( true ) with check ( true );
create policy olo_mov_kv_anon_delete on public.olo_movilidad_kv
  for delete to anon using ( true );

-- ----------------------------------------------------------------------------
-- 4) RLS en la tabla de usuarios: cada quien ve su propia fila; el admin, todas.
-- ----------------------------------------------------------------------------
alter table public.olo_movilidad_usuarios enable row level security;

drop policy if exists olo_mov_usuarios_select on public.olo_movilidad_usuarios;
create policy olo_mov_usuarios_select on public.olo_movilidad_usuarios
  for select to authenticated
  using ( user_id = auth.uid() or public.olo_mov_es_admin() );

commit;

-- ============================================================================
--  ASIGNACIÓN DE PAÍSES A LOS USUARIOS DE OLO
--  Países en uso: CR = Costa Rica, VE = Venezuela.
--
--  REQUISITO PREVIO: crea PRIMERO estos 4 usuarios en Supabase Auth
--  (Authentication > Users > Add user), con los mismos correos de abajo.
--  Luego ejecuta este bloque: resuelve el user_id automáticamente por correo
--  desde auth.users, así no tienes que copiar UIDs a mano.
--
--  Mapa solicitado:
--    lamador@ologistics.com     -> Costa Rica (CR)
--    hchavarria@ologistics.com  -> Costa Rica (CR)
--    mmontanes@ologistics.com   -> TODOS (admin global)
--    zalvarez@ologistics.com    -> Venezuela (VE)
--    jalvarez@ologistics.com    -> TODOS (admin global)
-- ----------------------------------------------------------------------------
insert into public.olo_movilidad_usuarios (user_id, email, pais, es_admin)
select u.id, u.email,
       m.pais,
       m.es_admin
from (values
        ('lamador@ologistics.com',    'CR'::text, false),
        ('hchavarria@ologistics.com', 'CR'::text, false),
        ('mmontanes@ologistics.com',  null::text, true),   -- TODOS los países
        ('zalvarez@ologistics.com',   'VE'::text, false),
        ('jalvarez@ologistics.com',   null::text, true)    -- TODOS los países
     ) as m(email, pais, es_admin)
join auth.users u on lower(u.email) = lower(m.email)
on conflict (user_id) do update
   set pais = excluded.pais,
       es_admin = excluded.es_admin,
       email = excluded.email;

-- Verifica qué quedó asignado (y detecta correos que aún no existen en Auth):
--   select email, pais, es_admin from public.olo_movilidad_usuarios order by email;
--   -- Correos del mapa que todavía NO tienen usuario creado en Auth:
--   select m.email from (values
--     ('lamador@ologistics.com'),('hchavarria@ologistics.com'),
--     ('mmontanes@ologistics.com'),('zalvarez@ologistics.com'),
--     ('jalvarez@ologistics.com')
--   ) as m(email)
--   left join auth.users u on lower(u.email)=lower(m.email)
--   where u.id is null;
-- ============================================================================

-- ============================================================================
--  CÓMO REVERTIR (si necesitas desactivar el multi-país a nivel de BD).
--  Esto NO borra datos del KV; solo quita las políticas y objetos nuevos.
--
--    alter table public.olo_movilidad_kv disable row level security;
--    drop policy if exists olo_mov_kv_select on public.olo_movilidad_kv;
--    drop policy if exists olo_mov_kv_insert on public.olo_movilidad_kv;
--    drop policy if exists olo_mov_kv_update on public.olo_movilidad_kv;
--    drop policy if exists olo_mov_kv_delete on public.olo_movilidad_kv;
--    drop policy if exists olo_mov_kv_anon_select on public.olo_movilidad_kv;
--    drop policy if exists olo_mov_kv_anon_insert on public.olo_movilidad_kv;
--    drop policy if exists olo_mov_kv_anon_update on public.olo_movilidad_kv;
--    drop policy if exists olo_mov_kv_anon_delete on public.olo_movilidad_kv;
--    drop function if exists public.olo_mov_pais_de_fila(text, jsonb);
--    drop function if exists public.olo_mov_pais_actual();
--    drop function if exists public.olo_mov_es_admin();
--    drop table if exists public.olo_movilidad_usuarios;
-- ============================================================================

-- ----------------------------------------------------------------------------
--  NOTA sobre evaluaciones e histórico:
--  Hoy evaluacion:% e historico:% no guardan país propio; la app los cruza con
--  su colaborador (colaboradorId) para filtrar en pantalla. Si necesitas
--  aislarlos TAMBIÉN a nivel de BD, la opción más limpia es guardar el país
--  dentro de esos JSON cuando se crean (value->>'pais'), replicando el del
--  colaborador. Entonces bastaría con quitar la condición
--  "olo_mov_pais_de_fila(...) is null" para esos prefijos y tratarlos igual que
--  a los colaboradores. Déjalo así por ahora para no alterar datos existentes.
-- ----------------------------------------------------------------------------
