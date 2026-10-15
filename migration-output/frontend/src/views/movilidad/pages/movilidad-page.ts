/**
 * Página única de Movilidad de Colaboradores: compone los controllers de datos y arranca la
 * interfaz original (pestañas Jefe inmediato, Pre-comité, Comité, Repositorio, Administrador).
 */
import { startMovilidadApp } from '../../../app/movilidad-app.js';
import { useEmailSenderController } from '../../notificaciones/hooks/use-email-sender-controller';
import { useAdminSessionController } from '../../perfiles/hooks/use-admin-session-controller';
import { useMovilidadStoreController } from '../hooks/use-movilidad-store-controller';

export function mountMovilidadPage(): void {
  startMovilidadApp({
    createStore: useMovilidadStoreController,
    adminSession: useAdminSessionController(),
    emailSender: useEmailSenderController(),
  });
}
