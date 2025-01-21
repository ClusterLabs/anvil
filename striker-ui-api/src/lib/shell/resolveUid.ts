import { resolveId } from './resolveId';

export const resolveUid = (id: number | string) => resolveId(id, 'passwd');
