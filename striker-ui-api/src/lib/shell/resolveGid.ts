import { resolveId } from './resolveId';

export const resolveGid = (id: number | string) => resolveId(id, 'group');
