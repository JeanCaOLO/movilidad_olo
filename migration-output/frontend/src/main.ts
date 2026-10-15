import { setupAuth } from './shared/auth/setup-auth';
import { mountMovilidadPage } from './views/movilidad/pages/movilidad-page';
import './styles/global.css';

setupAuth();
mountMovilidadPage();
