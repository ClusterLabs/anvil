import { uuidgen } from './uuidgen';

export const uuid = () => uuidgen('--random').trim();
