# MIGRATION REPORT — movilidad-colaboradores

**Estado: INCOMPLETE**  
Generado: 2026-10-15T16:07:46+00:00 · Validación: 2026-10-15T16:07:45+00:00

## 1. Resumen

| Aspecto | Origen | Destino |
|---|---|---|
| Frontend | static-html (js), router none, monolito | mismo framework y router · hosting amplify-static |
| API | Supabase (PostgREST, RPC, Edge Functions) | API Gateway REST REGIONAL + 6 endpoints Lambda python3.13 (hexagonal) |
| Base de datos | PostgreSQL Supabase (esquema: live_db) | Aurora PostgreSQL `olo_dev_movilidad_db` · 2 tablas, 0 vistas, 4 funciones |
| Autorización | RLS + auth.uid() | reglas en use cases (rls_mode: backend) |
| Auth | Supabase Auth | Amazon Cognito (grupos: ninguno) |
| Exposición | — | public — Los jefes inmediatos y gerentes entran por enlaces #c= / #g= que reciben por correo, sin iniciar sesión y desde Internet, y el administrador puede continuar sin iniciar sesión (Camino B del origen). Se conserva el comportamiento tal como está. |

## 2. Criterios de finalización (16)

| # | Criterio | Estado |
|---|---|---|
| 1 | Discovery completo: preflight, proyecto, uso de Supabase y esquema real | OK |
| 2 | Manifest revisado (sin borrador, endpoints válidos, reglas de autorización asignadas) | OK |
| 3 | Scripts Aurora completos por ambiente (provisioning, schema, validation, rollback, migration, datos) | OK |
| 4 | SQL Aurora validado en PostgreSQL efímero (idempotente, TOTAL_FALTA=0, rollback limpio) | OK |
| 5 | Backend hexagonal: handlers y use cases existen; dependencias entre capas y SQL en su lugar | OK |
| 6 | Tests del backend en verde (unitarios con fakes e integración contra el esquema generado) | OK |
| 7 | Lint del backend limpio (ruff) | OK |
| 8 | Template SAM único y samconfig dev/qa/prod con tags y rutas por ambiente | OK |
| 9 | Template válido (cfn-lint y transformación SAM) | OK |
| 10 | IAM mínimo y resiliencia (sin wildcards salvo ENI; SQS con DLQ, reintentos, visibility e idempotencia) | OK |
| 11 | Frontend con arquitectura estándar (Page → Controller → Api → axiosApiGateway, naming y tamaños) | FAIL |
| 12 | Frontend compila, cumple Prettier y sus tests pasan | OK |
| 13 | Cero residuos de Supabase (código, dependencias, variables) | OK |
| 14 | Sin secretos ni identificadores de ambiente hardcodeados | OK |
| 15 | Sin TODO/FIXME/pseudocódigo en el código generado | OK |
| 16 | Reporte final con matriz ORIGEN → DESTINO y solo pendientes de configuración | FAIL |

## 3. Matriz ORIGEN → DESTINO

### 3.1 Operaciones del frontend y Edge Functions

| Origen (archivo:línea) | Operación Supabase | Destino | Use case |
|---|---|---|---|
| index-html-script.js:23 | table select | GET /movilidad/entries → `ListMovilidadEntries` | `ListMovilidadEntriesUseCase` |
| index-html-script.js:32 | table select | GET /movilidad/entries → `ListMovilidadEntries` | `ListMovilidadEntriesUseCase` |
| index-html-script.js:48 | table select | GET /movilidad/entries/{key} → `GetMovilidadEntry` | `GetMovilidadEntryUseCase` |
| index-html-script.js:55 | table upsert | PUT /movilidad/entries/{key} → `SaveMovilidadEntry` | `SaveMovilidadEntryUseCase` |
| index-html-script.js:61 | table delete | DELETE /movilidad/entries/{key} → `DeleteMovilidadEntry` | `DeleteMovilidadEntryUseCase` |
| index-html-script.js:67 | table select | GET /movilidad/entries → `ListMovilidadEntries` | `ListMovilidadEntriesUseCase` |
| index-html-script.js:174 | table select | GET /me/country-profile → `GetMyCountryProfile` | `GetMyCountryProfileUseCase` |
| index-html-script.js:164 | auth getSession | Amazon Cognito (src/shared/auth/cognito-auth) | — |
| index-html-script.js:188 | auth signInWithPassword | Amazon Cognito (src/shared/auth/cognito-auth) | — |
| index-html-script.js:196 | auth signOut | Amazon Cognito (src/shared/auth/cognito-auth) | — |
| index-html-script.js:228 | edge_function send-eval-email | POST /notifications/evaluation-emails → `SendEvaluationEmail` | `SendEvaluationEmailUseCase` |
| index-html-script.js:997 | edge_function reco-ia | **SIN DESTINO** | — |

### 3.2 Endpoints

| Método | Ruta | Función Lambda | Handler | Auth |
|---|---|---|---|---|
| GET | /movilidad/entries | ListMovilidadEntries | entrypoints.lambda_handlers.movilidad.list_movilidad_entries_handler | none |
| GET | /movilidad/entries/{key} | GetMovilidadEntry | entrypoints.lambda_handlers.movilidad.get_movilidad_entry_handler | none |
| PUT | /movilidad/entries/{key} | SaveMovilidadEntry | entrypoints.lambda_handlers.movilidad.save_movilidad_entry_handler | none |
| DELETE | /movilidad/entries/{key} | DeleteMovilidadEntry | entrypoints.lambda_handlers.movilidad.delete_movilidad_entry_handler | none |
| GET | /me/country-profile | GetMyCountryProfile | entrypoints.lambda_handlers.perfiles.get_my_country_profile_handler | cognito |
| POST | /notifications/evaluation-emails | SendEvaluationEmail | entrypoints.lambda_handlers.notificaciones.send_evaluation_email_handler | none |

### 3.3 Objetos de base de datos

| Origen | Aurora | Tipo |
|---|---|---|
| public.olo_movilidad_kv | olo_dev_movilidad_sch_core.tbl_olo_movilidad_kv | table |
| public.olo_movilidad_usuarios | olo_dev_movilidad_sch_core.tbl_olo_movilidad_usuarios | table |
| auth.users | olo_dev_movilidad_sch_core.tbl_app_users | table |
| public.olo_mov_es_admin | olo_dev_movilidad_sch_core.fn_olo_mov_es_admin | function |
| public.olo_mov_pais_actual | olo_dev_movilidad_sch_core.fn_olo_mov_pais_actual | function |
| public.olo_mov_pais_de_fila | olo_dev_movilidad_sch_core.fn_olo_mov_pais_de_fila | function |
| public.olo_movilidad_kv_touch | olo_dev_movilidad_sch_core.fn_olo_movilidad_kv_touch | function |
| auth.uid() | fn_auth_uid() | auth helper |
| auth.role() | fn_auth_role() | auth helper |
| auth.email() | fn_auth_email() | auth helper |
| auth.jwt() | fn_auth_jwt() | auth helper |

Roles: `ro_movilidad`, `rw_movilidad`, `ddl_movilidad`, `admin_movilidad` · Usuarios: `usr_movilidad_report`, `usr_movilidad_app`, `usr_movilidad_deploy`, `usr_movilidad_dba` · search_path: `olo_dev_movilidad_sch_core`

### 3.4 Políticas RLS → reglas de autorización

| Tabla | Regla | Comando | Condición | Se aplica en |
|---|---|---|---|---|
| public.olo_movilidad_kv | olo_mov_select | SELECT | true | List/GetMovilidadEntryUseCase sin filtro (rutas públicas GET /movilidad/entries*) |
| public.olo_movilidad_kv | olo_mov_insert | INSERT | true | SaveMovilidadEntryUseCase sin restricción (PUT /movilidad/entries/{key}) |
| public.olo_movilidad_kv | olo_mov_update | UPDATE | true | SaveMovilidadEntryUseCase sin restricción (PUT /movilidad/entries/{key}) |
| public.olo_movilidad_kv | olo_mov_delete | DELETE | true | DeleteMovilidadEntryUseCase sin restricción (DELETE /movilidad/entries/{key}) |
| public.olo_movilidad_kv | olo_mov_kv_anon_select | SELECT | true | List/GetMovilidadEntryUseCase (rutas públicas; equivalente a olo_mov_select) |
| public.olo_movilidad_kv | olo_mov_kv_anon_insert | INSERT | true | SaveMovilidadEntryUseCase (ruta pública; equivalente a olo_mov_insert) |
| public.olo_movilidad_kv | olo_mov_kv_anon_update | UPDATE | true | SaveMovilidadEntryUseCase (ruta pública; equivalente a olo_mov_update) |
| public.olo_movilidad_kv | olo_mov_kv_anon_delete | DELETE | true | DeleteMovilidadEntryUseCase (ruta pública; equivalente a olo_mov_delete) |
| public.olo_movilidad_kv | olo_mov_kv_select | SELECT | (olo_mov_es_admin() OR (olo_mov_pais_de_fila(key, value) IS NULL) OR (olo_mov_pais_de_fila(key, value) = olo_mov_pais_actual())) | Sin efecto en el origen (se combina con OR con olo_mov_select = true). Acotamiento por país en la interfaz (aplicarPaisDeSesion + GET /me/country-profile), igual que hoy. |
| public.olo_movilidad_kv | olo_mov_kv_insert | INSERT | (olo_mov_es_admin() OR (olo_mov_pais_de_fila(key, value) IS NULL) OR (olo_mov_pais_de_fila(key, value) = olo_mov_pais_actual())) | Sin efecto en el origen (OR con olo_mov_insert = true); acotamiento por país en la interfaz. |
| public.olo_movilidad_kv | olo_mov_kv_update | UPDATE | (olo_mov_es_admin() OR (olo_mov_pais_de_fila(key, value) IS NULL) OR (olo_mov_pais_de_fila(key, value) = olo_mov_pais_actual())) | Sin efecto en el origen (OR con olo_mov_update = true); acotamiento por país en la interfaz. |
| public.olo_movilidad_kv | olo_mov_kv_delete | DELETE | (olo_mov_es_admin() OR (olo_mov_pais_de_fila(key, value) IS NULL) OR (olo_mov_pais_de_fila(key, value) = olo_mov_pais_actual())) | Sin efecto en el origen (OR con olo_mov_delete = true); acotamiento por país en la interfaz. |
| public.olo_movilidad_usuarios | olo_mov_usuarios_select | SELECT | ((user_id = auth.uid()) OR olo_mov_es_admin()) | GetMyCountryProfileUseCase (solo la fila del principal.user_id; la UI no lista perfiles ajenos) |

### 3.5 Servicios

| Origen | Destino |
|---|---|
| Supabase Auth | Amazon Cognito User Pool + authorizer de API Gateway |

## 4. Cambios estructurales, incompatibilidades y riesgos

**Cambios estructurales:** 
- Frontend: el HTML monolítico (out/index.html) pasa a un proyecto Vite + TypeScript. Por indicación del usuario ("deja la aplicación tal y como está") la UI se conserva en JS vanilla sin portarla a React: mismo marcado, CSS, textos y lógica en src/app/movilidad-app.js; solo cambia la capa de datos.
- Objeto Store (supabase-js sobre olo_movilidad_kv) → src/views/movilidad (movilidad-api + use-movilidad-store-controller) sobre axiosApiGateway, con las mismas cachés y mensajes.
- getAll paginaba con .range() de 1000 filas → paginación por cursor de clave (next_cursor) con tope de 4 MB por página (límite de 6 MB de Lambda; los colaboradores llevan la foto en base64).
- supabase.auth (signInWithPassword/getSession/signOut) → Cognito vía src/views/perfiles (solo administradores).
- select en olo_movilidad_usuarios → GET /me/country-profile (204 si no hay fila, como maybeSingle()).
- Edge Function send-eval-email (SMTP de Gmail con contraseña de aplicación) → POST /notifications/evaluation-emails con Amazon SES, mismo contrato, reglas, mensajes y cuerpo texto + HTML; remitente "Comunicaciones OLO" <comunicaciones@ologistics.com> sin secretos de Gmail.
- El botón "Generar análisis con IA" llamaba a la Edge Function reco-ia, que no existe en el proyecto Supabase (solo están send-eval-email y quick-responder): siempre fallaba. Se retira el botón; el análisis base de recomendaciones para el comité se conserva.
- Textos de la UI que mencionaban Supabase pasan a decir "servidor". Se eliminan los modos sin backend (window.storage del entorno de artefactos y memoria local), que no aplican con la API desplegada.
- El proyecto Supabase es compartido con otros sistemas (olo_indicadores_*, olo_organigramas_kv, olo_salida_kv, olo_kv, olo_usuarios y la Edge Function quick-responder): quedan fuera de esta migración (database/config.yaml → skip_objects).
- Librerías de cliente (SheetJS xlsx 0.18.5 y jsPDF 2.5.1) y Google Fonts siguen por CDN como en el original; la CSP de Amplify los permite explícitamente.

**Incompatibilidades:** 
- Cognito no conserva las contraseñas de Supabase Auth: los 5 usuarios se migran a tbl_app_users con su id original y deben crearse en Cognito; definen una contraseña nueva en el primer ingreso (NEW_PASSWORD_REQUIRED, soportado en el login) y quedan vinculados por email verificado.

**Riesgos:** 
- Heredado del origen: lectura y escritura completas del almacén sin autenticación (rutas públicas), y las políticas por país no aíslan en la base porque olo_mov_select/insert/update/delete (true) las anulan; el aislamiento por país es solo visual. Mitigado con WAF (rate limit por IP + reglas administradas). Recomendado a futuro: login para todos y aislamiento en el backend.
- POST /notifications/evaluation-emails es público y envía desde el remitente corporativo (como la Edge Function con anon key): riesgo de abuso como relay. Mitigado con WAF rate limit.
- Las Lambdas corren en la VPC: necesitan salida a SES (NAT Gateway o VPC endpoint com.amazonaws.<región>.email-smtp / sesv2).
- CSP de Amplify: script-src requiere 'unsafe-inline' porque la UI conservada usa manejadores onclick inline generados dinámicamente; se permiten cdnjs y Google Fonts.
- aurora_postgresql_data.sql contiene datos personales reales (colaboradores con foto, evaluaciones, correos): no se versiona en git (.gitignore) y debe tratarse como información confidencial.

**Revisiones del generador SQL:**
- `public.olo_movilidad_usuarios.olo_movilidad_usuarios_user_id_fkey` (auth_users_ref): auth.users → tbl_app_users: solo existen id, cognito_sub, email, created_at, updated_at

## 5. Pendientes (solo configuración de ambiente)

- **dev** — crear parámetros SSM: `/dev/movilidad/network/subnets` (VpcSubnetIds), `/dev/movilidad/network/lambda-sg` (LambdaSecurityGroupId), `/dev/movilidad/db/proxy-endpoint` (DbProxyEndpoint), `/dev/movilidad/frontend/origin` (AllowedOrigins), `/dev/movilidad/notifications/from-email` (SesFromEmail)
- **dev** — crear el secreto de Secrets Manager `/dev/movilidad/db/app` con `username`/`password` del usuario `usr_<app>_app`
- **qa** — crear parámetros SSM: `/qa/movilidad/network/subnets` (VpcSubnetIds), `/qa/movilidad/network/lambda-sg` (LambdaSecurityGroupId), `/qa/movilidad/db/proxy-endpoint` (DbProxyEndpoint), `/qa/movilidad/frontend/origin` (AllowedOrigins), `/qa/movilidad/notifications/from-email` (SesFromEmail)
- **qa** — crear el secreto de Secrets Manager `/qa/movilidad/db/app` con `username`/`password` del usuario `usr_<app>_app`
- **prod** — crear parámetros SSM: `/prod/movilidad/network/subnets` (VpcSubnetIds), `/prod/movilidad/network/lambda-sg` (LambdaSecurityGroupId), `/prod/movilidad/db/proxy-endpoint` (DbProxyEndpoint), `/prod/movilidad/frontend/origin` (AllowedOrigins), `/prod/movilidad/notifications/from-email` (SesFromEmail)
- **prod** — crear el secreto de Secrets Manager `/prod/movilidad/db/app` con `username`/`password` del usuario `usr_<app>_app`
- Frontend — variables por ambiente en Amplify/pipeline: `REACT_APP_API_BASE_URL`, `REACT_APP_COGNITO_USER_POOL_ID`, `REACT_APP_COGNITO_CLIENT_ID` (salidas del stack SAM)
- Base de datos — ejecutar provisioning con las 4 contraseñas por variable de psql (`-v pass_ro=... -v pass_rw=... -v pass_ddl=... -v pass_admin=...`), nunca en archivos
- Usuarios — importar usuarios a Cognito (CSV de importación o Lambda de migración) y comunicar el restablecimiento de contraseña
- Opcional — `AlarmTopicArn` (SNS) en parameter_overrides para recibir las alarmas
- Seguridad — al terminar, borrar `.env.supabase` y rotar en Supabase la secret key, la password de la base y el access token usados en la migración

## 6. Validaciones ejecutadas

| Criterio | Verificación | Estado | Detalle |
|---|---|---|---|
| C1 | Artefactos de discovery | OK |  |
| C1 | Origen del esquema | OK | fuente: live_database |
| C2 | Manifest completo | OK |  |
| C2 | Cada regla de autorización tiene dónde se aplica (enforced_in) | OK |  |
| C2 | Sin errores pendientes declarados en el manifest | OK |  |
| C3 | Scripts Aurora por ambiente (dev, qa, prd) | OK |  |
| C3 | Objetos sin equivalente en Aurora documentados | OK |  |
| C4 | SQL en PostgreSQL efímero (idempotencia, validación, rollback) | OK | dev: PASSED; qa: PASSED; prd: PASSED |
| C8 | Un único template SAM parametrizado | OK |  |
| C8 | Template conforme al estándar (parámetros, runtime, logs) | OK |  |
| C5 | Estructura hexagonal del backend | OK |  |
| C5 | Handlers del manifest y del template implementados | OK | 6 handlers |
| C5 | Use cases del manifest implementados | OK | 6 use cases |
| C5 | Dependencias entre capas y handlers delgados | OK |  |
| C5 | SQL solo en adapters y con nombres de Aurora | OK |  |
| C6 | pytest (unitarios con fakes) | OK | 46 passed, 2 skipped in 0.23s |
| C6 | Cada módulo del manifest tiene tests unitarios | OK |  |
| C6 | pytest de integración contra el esquema generado (PG efímero) | OK | 3 passed in 0.29s |
| C7 | ruff check | OK |  |
| C8 | samconfig.toml dev/qa/prod con tags y rutas por ambiente | OK |  |
| C9 | cfn-lint | OK |  |
| C9 | Transformación SAM | OK | 34 recursos CloudFormation |
| C10 | IAM sin comodines (salvo ENI documentado) | OK |  |
| C10 | Colas SQS con los 4 controles del estándar | OK | sin colas (no aplica) |
| C11 | Capa compartida (gateway HTTP, auth, env) | OK |  |
| C11 | HTTP solo vía axiosApiGateway | OK |  |
| C11 | Módulos src/views con Page → Controller → Api | OK |  |
| C11 | Naming kebab-case (-page, use-*-controller, -api) | OK |  |
| C11 | Límites de tamaño de pages y secciones | OK |  |
| C11 | Componentes fuera de views/ ≤ 250 líneas | OK |  |
| C11 | Variables por ambiente y hosting | FAIL | 1 hallazgo(s) |
| C12 | Instalación y build del frontend | OK | install + build |
| C12 | Prettier | OK |  |
| C12 | Tests del frontend | OK | el proyecto no tiene tests (no aplica) |
| C13 | Cero referencias a Supabase en frontend y backend | OK |  |
| C14 | Sin secretos en código ni configuración | OK |  |
| C14 | Sin IDs/ARNs/endpoints de AWS hardcodeados | OK |  |
| C15 | Sin TODO/FIXME/pseudocódigo | OK |  |

<details><summary>FAIL — Variables por ambiente y hosting</summary>

- frontend/.env.example sin REACT_APP_API_BASE_URL

</details>

## 7. Despliegue

```bash
# 1. Base de datos (por ambiente; desde database/ o database/environments/<amb>/)
psql "$ADMIN_URL/postgres" -v pass_ro=*** -v pass_rw=*** -v pass_ddl=*** -v pass_admin=*** \
     -f aurora_postgresql_provisioning.sql
psql "$ADMIN_URL/olo_dev_movilidad_db" -f aurora_postgresql_schema.sql
psql "$ADMIN_URL/olo_dev_movilidad_db" -f aurora_postgresql_data.sql             # datos del origen (re-ejecutable)
psql "$ADMIN_URL/olo_dev_movilidad_db" -At -f aurora_postgresql_validation.sql   # TOTAL_FALTA debe ser 0
# datos: origen Supabase en solo lectura, credenciales desde .env.supabase (nunca en la línea de comandos)
TARGET_DATABASE_URL=... python "$SKILL/scripts/supabase_connect.py" exec -- ./data_migration.sh
python "$SKILL/scripts/supabase_connect.py" storage-export --out ./storage-export   # Storage
aws s3 sync ./storage-export/<bucket> s3://<bucket-del-stack>/
# 2. Backend
cd backend && sam build && sam deploy --config-env dev   # qa / prod
# 3. Frontend: configurar variables por rama en Amplify (o build del Dockerfile) y desplegar
```

