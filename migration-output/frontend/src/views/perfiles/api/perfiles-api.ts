/** Perfil de país del administrador (antes select en olo_movilidad_usuarios). */
import { axiosApiGateway } from '../../../shared/api/axios-api-gateway';

export interface CountryProfile {
  pais: string | null;
  es_admin: boolean;
  email: string | null;
}

export const perfilesApi = {
  /** null si el usuario no tiene fila de perfil (204), como el maybeSingle() original. */
  async getMyCountryProfile(options: { signal?: AbortSignal } = {}) {
    const response = await axiosApiGateway.get<CountryProfile | ''>('/me/country-profile', {
      signal: options.signal,
    });
    return response.status === 204 || !response.data ? null : response.data;
  },
};
