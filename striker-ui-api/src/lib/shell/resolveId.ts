import { getent } from './getent';

export const resolveId = (id: number | string, database: string) =>
  Number(getent(database, String(id)).split(':', 3)[2]);
