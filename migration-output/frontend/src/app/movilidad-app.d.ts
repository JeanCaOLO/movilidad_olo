import type { MovilidadStore } from '../views/movilidad/hooks/use-movilidad-store-controller';
import type { EmailSenderController } from '../views/notificaciones/hooks/use-email-sender-controller';
import type { AdminSessionController } from '../views/perfiles/hooks/use-admin-session-controller';

export interface MovilidadAppDeps {
  createStore: (toast: (message: string) => void) => MovilidadStore;
  adminSession: AdminSessionController;
  emailSender: EmailSenderController;
}

/** Arranca la interfaz original sobre el marcado de index.html. */
export function startMovilidadApp(deps: MovilidadAppDeps): void;
