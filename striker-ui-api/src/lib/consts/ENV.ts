import { resolveGid, resolveUid } from '../shell';

/**
 * The fallback job progress value when queuing jobs.
 *
 * Ignore jobs by setting this to `100`.
 *
 * @default 0
 */
export const DEFAULT_JOB_PROGRESS: number = Number.parseInt(
  process.env.DEFAULT_JOB_PROGRESS ?? '0',
);

/**
 * Port to use by the express app.
 *
 * @default 8080
 */
export const PORT = Number.parseInt(process.env.PORT ?? '8080');

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

/**
 * Get server screenshot job timeout in milliseconds. The job will be
 * forced to progress 100 if it doesn't start within this time limit.
 *
 * @default 30000
 */
export const GET_SERVER_SCREENSHOT_TIMEOUT = Number.parseInt(
  process.env.GET_SERVER_SCREENSHOT_TIMEOUT ?? '30000',
);
