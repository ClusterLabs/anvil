import assert from 'assert';
import expressSession, {
  SessionData,
  Store as BaseSessionStore,
} from 'express-session';

import { DELETED } from './lib/consts';

import { getLocalHostUUID, query, timestamp, write } from './lib/accessModule';
import { getSessionSecret } from './lib/getSessionSecret';
import { stderr, stdout, stdoutVar, uuid } from './lib/shell';

const DEFAULT_COOKIE_ORIGINAL_MAX_AGE = 3600000;

export class SessionStore extends BaseSessionStore {
  constructor(options = {}) {
    super(options);
  }

  public async destroy(
    sid: string,
    done?: ((err?: unknown) => void) | undefined,
  ): Promise<void> {
    stdout(`Destroy session ${sid}`);

    try {
      const wcode = await write(
        `UPDATE sessions
          SET session_salt = '${DELETED}', modified_date = '${timestamp()}'
          WHERE session_uuid = '${sid}';`,
      );

      assert(wcode === 0, `Write exited with code ${wcode}`);
    } catch (error) {
      stderr(
        `Failed to complete DB write in destroy session ${sid}; CAUSE: ${error}`,
      );

      return done?.call(null, error);
    }

    return done?.call(null);
  }

  public async get(
    sid: string,
    done: (err: unknown, session?: SessionData | null | undefined) => void,
  ): Promise<void> {
    stdout(`Get session ${sid}`);

    let rows: [
      sessionUuid: string,
      userUuid: string,
      sessionModifiedDate: string,
    ][];

    try {
      rows = await query(
        `SELECT
            s.session_uuid,
            u.user_uuid,
            s.modified_date
          FROM sessions AS s
          JOIN users AS u
            ON s.session_user_uuid = u.user_uuid
          WHERE s.session_salt != '${DELETED}'
            AND s.session_uuid = '${sid}';`,
      );
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
      passport: { user: userUuid },
    };

    return done(null, data);
  }

  public async set(
    sid: string,
    session: SessionData,
    done?: ((err?: unknown) => void) | undefined,
  ): Promise<void> {
    stdoutVar({ session }, `Set session ${sid}`);

    const {
      passport: { user: userUuid },
    } = session;

    try {
      const localHostUuid = getLocalHostUUID();
      const modifiedDate = timestamp();

      const wcode = await write(
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
            DO UPDATE SET modified_date = '${modifiedDate}';`,
      );

      assert(wcode === 0, `Write exited with code ${wcode}`);
    } catch (error) {
      stderr(
        `Failed to complete DB write in set session ${sid}; CAUSE: ${error}`,
      );

      return done?.call(null, error);
    }

    return done?.call(null);
  }

  public async touch(
    sid: string,
    session: SessionData,
    done?: ((err?: unknown) => void) | undefined,
  ): Promise<void> {
    stdoutVar({ session }, `Touch session ${sid}`);

    try {
      const wcode = await write(
        `UPDATE sessions
          SET modified_date = '${timestamp()}'
          WHERE session_uuid = '${sid}';`,
      );

      assert(wcode === 0, `Write exited with code ${wcode}`);
    } catch (error) {
      stderr(
        `Failed to complete DB write in touch session ${sid}; CAUSE: ${error}`,
      );

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

export default (async () =>
  expressSession({
    cookie: { maxAge: DEFAULT_COOKIE_ORIGINAL_MAX_AGE },
    genid: ({ path }) => {
      const sid = uuid();

      stdout(`Generated session identifier ${sid}; request.path=${path}`);

      return sid;
    },
    resave: false,
    saveUninitialized: false,
    secret: await getSessionSecret(),
    store: new SessionStore(),
  }))();
