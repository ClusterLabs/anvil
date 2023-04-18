import session, {
  SessionData,
  Store as BaseSessionStore,
} from 'express-session';

import {
  awrite,
  dbQuery,
  getLocalHostUUID,
  timestamp,
} from './lib/accessModule';
import { getSessionSecret } from './lib/getSessionSecret';
import { isObject } from './lib/isObject';
import { stderr, stdout, stdoutVar, uuidgen } from './lib/shell';

const DEFAULT_COOKIE_ORIGINAL_MAX_AGE = 1000 * 60 * 60;

const getWriteCode = (obj: object) => {
  let result: number | undefined;

  if ('write_code' in obj) {
    ({ write_code: result } = obj as { write_code: number });
  }

  return result;
};

export class SessionStore extends BaseSessionStore {
  constructor(options = {}) {
    super(options);
  }

  public destroy(
    sid: string,
    done?: ((err?: unknown) => void) | undefined,
  ): void {
    stdout(`Destroy session ${sid}`);

    try {
      awrite(`DELETE FROM sessions WHERE session_uuid = '${sid}';`, {
        onClose({ stdout: s1 }) {
          const wcode = getWriteCode(isObject(s1).obj);

          if (wcode !== 0) {
            stderr(
              `SQL script failed during destroy session ${sid}; code: ${wcode}`,
            );
          }
        },
        onError(error) {
          stderr(
            `Failed to complete DB write in destroy session ${sid}; CAUSE: ${error}`,
          );
        },
      });
    } catch (error) {
      return done?.call(null, error);
    }

    return done?.call(null);
  }

  public get(
    sid: string,
    done: (err: unknown, session?: SessionData | null | undefined) => void,
  ): void {
    stdout(`Get session ${sid}`);

    let rows: [
      sessionUuid: string,
      userUuid: string,
      sessionModifiedDate: string,
    ][];

    try {
      rows = dbQuery(
        `SELECT
            s.session_uuid,
            u.user_uuid,
            s.modified_date
          FROM sessions AS s
          JOIN users AS u
            ON s.session_user_uuid = u.user_uuid
          WHERE s.session_uuid = '${sid}';`,
      ).stdout;
    } catch (queryError) {
      return done(queryError);
    }

    if (!rows.length) {
      return done(null);
    }

    const {
      0: [, userUuid, sessionModifiedDate],
    } = rows;

    const cookieMaxAge =
      SessionStore.calculateCookieMaxAge(sessionModifiedDate);

    const data: SessionData = {
      cookie: {
        maxAge: cookieMaxAge,
        originalMaxAge: DEFAULT_COOKIE_ORIGINAL_MAX_AGE,
      },
      passport: {
        user: userUuid,
      },
    };

    return done(null, data);
  }

  public set(
    sid: string,
    session: SessionData,
    done?: ((err?: unknown) => void) | undefined,
  ): void {
    stdout(`Set session ${sid}`);

    const {
      passport: { user: userUuid },
    } = session;

    try {
      const localHostUuid = getLocalHostUUID();
      const modifiedDate = timestamp();

      awrite(
        `INSERT INTO
            sessions (
              session_uuid,
              session_host_uuid,
              session_user_uuid,
              session_salt,
              modified_date
            )
          VALUES
            (
              '${sid}',
              '${localHostUuid}',
              '${userUuid}',
              '',
              '${modifiedDate}'
            )
          ON CONFLICT (session_uuid)
            DO UPDATE SET session_host_uuid = '${localHostUuid}',
                          modified_date = '${modifiedDate}';`,
        {
          onClose: ({ stdout: s1 }) => {
            const wcode = getWriteCode(isObject(s1).obj);

            if (wcode !== 0) {
              stderr(
                `SQL script failed during set session ${sid}; code: ${wcode}`,
              );
            }
          },
          onError: (error) => {
            stderr(
              `Failed to complete DB write in set session ${sid}; CAUSE: ${error}`,
            );
          },
        },
      );
    } catch (error) {
      return done?.call(null, error);
    }

    return done?.call(null);
  }

  public touch(
    sid: string,
    session: SessionData,
    done?: ((err?: unknown) => void) | undefined,
  ): void {
    stdout(`Touch session ${sid}`);

    try {
      awrite(
        `UPDATE sessions SET modified_date = '${timestamp()}' WHERE session_uuid = '${sid}';`,
        {
          onClose: ({ stdout: s1 }) => {
            const wcode = getWriteCode(isObject(s1).obj);

            if (wcode !== 0) {
              stderr(
                `SQL script failed during touch session ${sid}; code: ${wcode}`,
              );
            }
          },
          onError: (error) => {
            stderr(
              `Failed to complete DB write in touch session ${sid}; CAUSE: ${error}`,
            );
          },
        },
      );
    } catch (error) {
      return done?.call(null, error);
    }

    return done?.call(null);
  }

  public static calculateCookieMaxAge(
    sessionModifiedDate: string,
    cookieOriginalMaxAge: number = DEFAULT_COOKIE_ORIGINAL_MAX_AGE,
  ) {
    const sessionModifiedEpoch = Date.parse(sessionModifiedDate);
    const sessionDeadlineEpoch = sessionModifiedEpoch + cookieOriginalMaxAge;
    const cookieMaxAge = sessionDeadlineEpoch - Date.now();

    stdoutVar({ sessionModifiedDate, sessionDeadlineEpoch, cookieMaxAge });

    return cookieMaxAge;
  }
}

const sessionHandler = session({
  cookie: { maxAge: DEFAULT_COOKIE_ORIGINAL_MAX_AGE },
  genid: ({ path }) => {
    const sid = uuidgen('--random').trim();

    stdout(`Generated session identifier ${sid}; request.path=${path}`);

    return sid;
  },
  resave: false,
  saveUninitialized: false,
  secret: getSessionSecret(),
  store: new SessionStore(),
});

export default sessionHandler;
