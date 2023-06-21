import { resolveGid, resolveUid } from '../shell';

export const PUID = resolveUid(process.env.PUID ?? 'striker-ui-api');

export const PGID = resolveGid(process.env.PGID ?? PUID);
