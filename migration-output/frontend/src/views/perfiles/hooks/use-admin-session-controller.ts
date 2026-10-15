/**
 * Sesión del administrador: restaurar, iniciar y cerrar sesión con
 * Cognito y leer su perfil de país. Los jefes y gerentes no inician sesión (Camino B).
 */
import {
  completeNewPassword,
  getSessionUser,
  signInWithEmail,
  signOutUser,
} from '../../../shared/auth/cognito-auth';
import { perfilesApi, type CountryProfile } from '../api/perfiles-api';

export interface AdminUser {
  id: string;
  email: string | null;
}

export interface AdminSignInResult {
  user: AdminUser | null;
  /** true si Cognito exige definir una contraseña nueva (usuario creado o importado). */
  newPasswordRequired: boolean;
}

export interface AdminSessionController {
  currentUser(): AdminUser | null;
  restore(): Promise<AdminUser | null>;
  signIn(email: string, password: string): Promise<AdminSignInResult>;
  completeNewPassword(newPassword: string): Promise<AdminSignInResult>;
  signOut(): Promise<void>;
  fetchProfile(): Promise<CountryProfile | null>;
}

export function useAdminSessionController(): AdminSessionController {
  let user: AdminUser | null = null;
  let profileRequest: AbortController | null = null;

  async function loadUser(): Promise<AdminUser | null> {
    const session = await getSessionUser();
    user = session ? { id: session.sub, email: session.email } : null;
    return user;
  }

  async function afterStep(isSignedIn: boolean, nextStep: string): Promise<AdminSignInResult> {
    if (isSignedIn) return { user: await loadUser(), newPasswordRequired: false };
    if (nextStep === 'CONFIRM_SIGN_IN_WITH_NEW_PASSWORD_REQUIRED') {
      return { user: null, newPasswordRequired: true };
    }
    throw new Error(`No se pudo completar el inicio de sesión (${nextStep}).`);
  }

  return {
    currentUser: () => user,

    restore: loadUser,

    async signIn(email, password) {
      const result = await signInWithEmail(String(email || '').trim(), String(password || ''));
      return afterStep(result.isSignedIn, result.nextStep);
    },

    async completeNewPassword(newPassword) {
      const result = await completeNewPassword(newPassword);
      return afterStep(result.isSignedIn, result.nextStep);
    },

    async signOut() {
      user = null;
      profileRequest?.abort();
      await signOutUser();
    },

    async fetchProfile() {
      profileRequest?.abort();
      const controller = new AbortController();
      profileRequest = controller;
      try {
        return await perfilesApi.getMyCountryProfile({ signal: controller.signal });
      } finally {
        if (profileRequest === controller) profileRequest = null;
      }
    },
  };
}
