import { resolveGid, resolveUid } from '../shell';

/**
 * The prefix of every cookie used by the express app.
 *
 * @default 'suiapi'
 */
export const COOKIE_PREFIX = process.env.COOKIE_PREFIX ?? 'suiapi';

/**
 * The max lifespan of a session cookie in milliseconds.
 *
 * @default 28800000
 */
export const COOKIE_ORIGINAL_MAX_AGE: number =
  Number(process.env.COOKIE_ORIGINAL_MAX_AGE) || 28800000;

/**
 * The debug level to pass to anvil-access-module; 1 is '-v', 2 is '-vv', ...
 *
 * @default 0
 */
export const DEBUG_ACCESS = Number(process.env.DEBUG_ACCESS) || 0;

/**
 * The debug level of the main process.
 *
 * Only supports 0 (off) or 1 (on).
 *
 * @default 0
 */
export const DEBUG_MAIN = Number(process.env.DEBUG_MAIN) || 0;

/**
 * The fallback job progress value when queuing jobs.
 *
 * Ignore jobs by setting this to `100`.
 *
 * @default 0
 */
export const DEFAULT_JOB_PROGRESS: number =
  Number(process.env.DEFAULT_JOB_PROGRESS) || 0;

/**
 * Port to use by the express app.
 *
 * @default 8080
 */
export const PORT: number = Number(process.env.PORT) || 8080;

/**
 * Process user identifier. Also used to set ownership on the access daemon.
 *
 * @default 'striker-ui-api'
 */
export const PUID = resolveUid(process.env.PUID ?? 'striker-ui-api');

/**
 * Process group identifier. Also used to set ownership on the access daemon.
 *
 * Defaults to the value set in process user identifier.
 *
 * @default PUID
 */
export const PGID = resolveGid(process.env.PGID ?? PUID);
