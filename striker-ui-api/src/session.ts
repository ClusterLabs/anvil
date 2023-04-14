import assert from 'assert';
import session, {
  SessionData as BaseSessionData,
  Store as BaseStore,
} from 'express-session';

import {
  dbQuery,
  dbWrite,
  getLocalHostUUID,
  timestamp,
} from './lib/accessModule';
import { getSessionSecret } from './lib/getSessionSecret';
import { stdout, stdoutVar, uuidgen } from './lib/shell';

const DEFAULT_COOKIE_ORIGINAL_MAX_AGE = 1000 * 60 * 60;

export class SessionStore extends BaseStore {
  constructor(options = {}) {
    super(options);
  }

  public destroy(
    sid: string,
    done?: ((err?: unknown) => void) | undefined,
  ): void {
    stdout(`Destroy session ${sid}`);

    try {
      const { write_code: wcode }: { write_code: number } = dbWrite(
        `DELETE FROM sessions WHERE session_uuid = '${sid}';`,
      ).stdout;

      assert(wcode === 0, `Delete session ${sid} failed with code ${wcode}`);
    } catch (writeError) {
      return done?.call(null, writeError);
    }

    return done?.call(null);
  }

  public get(
    sid: string,
    done: (err: unknown, session?: BaseSessionData | null | undefined) => void,
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
    session: BaseSessionData,
    done?: ((err?: unknown) => void) | undefined,
  ): void {
    stdout(`Set session ${sid}; session=${JSON.stringify(session, null, 2)}`);

    const {
      passport: { user: userUuid },
    } = session as SessionData;

    try {
      const localHostUuid = getLocalHostUUID();
      const modifiedDate = timestamp();

      const { write_code: wcode }: { write_code: number } = dbWrite(
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
      ).stdout;

      assert(
        wcode === 0,
        `Insert or update session ${sid} failed with code ${wcode}`,
      );
    } catch (error) {
      return done?.call(null, error);
    }

    return done?.call(null);
  }

  public touch(
    sid: string,
    session: BaseSessionData,
    done?: ((err?: unknown) => void) | undefined,
  ): void {
    stdout(
      `Update modified date in session ${sid}; session=${JSON.stringify(
        session,
        null,
        2,
      )}`,
    );

    try {
      const { write_code: wcode }: { write_code: number } = dbWrite(
        `UPDATE sessions SET modified_date = '${timestamp()}' WHERE session_uuid = '${sid}';`,
      ).stdout;

      assert(
        wcode === 0,
        `Update modified date for session ${sid} failed with code ${wcode}`,
      );
    } catch (writeError) {
      return done?.call(null, writeError);
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
