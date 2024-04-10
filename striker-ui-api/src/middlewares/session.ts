import assert from 'assert';
import expressSession, {
  SessionData,
  Store as BaseSessionStore,
} from 'express-session';

import { COOKIE_ORIGINAL_MAX_AGE, DELETED } from '../lib/consts';

import { getLocalHostUUID, query, timestamp, write } from '../lib/accessModule';
import { cname } from '../lib/cname';
import { getSessionSecret } from '../lib/getSessionSecret';
import { perr, pout, poutvar, uuid } from '../lib/shell';

export class SessionStore extends BaseSessionStore {
  constructor(options = {}) {
    super(options);
  }

  public async destroy(
    sid: string,
    done?: ((err?: unknown) => void) | undefined,
  ): Promise<void> {
    pout(`Destroy session ${sid}`);

    try {
      const wcode = await write(
        `UPDATE sessions
          SET session_salt = '${DELETED}', modified_date = '${timestamp()}'
          WHERE session_uuid = '${sid}';`,
      );

      assert(wcode === 0, `Write exited with code ${wcode}`);
    } catch (error) {
      perr(
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
    pout(`Get session ${sid}`);

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
        originalMaxAge: COOKIE_ORIGINAL_MAX_AGE,
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
    poutvar({ session }, `Set session ${sid}: `);

    const { passport: { user: userUuid } = {} } = session;

    try {
      assert.ok(userUuid, 'Missing user identifier');

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
      perr(
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
    poutvar({ session }, `Touch session ${sid}: `);

    // The intent of updating the session modified date is to avoid expiring the
    // session when it's actively used by the user. But since the updates are
    // flooding the database's history table, disable it for now.

    // try {
    //   const wcode = await write(
    //     `UPDATE sessions
    //       SET modified_date = '${timestamp()}'
    //       WHERE session_uuid = '${sid}';`,
    //   );

    //   assert(wcode === 0, `Write exited with code ${wcode}`);
    // } catch (error) {
    //   perr(
    //     `Failed to complete DB write in touch session ${sid}; CAUSE: ${error}`,
    //   );

    //   return done?.call(null, error);
    // }

    return done?.call(null);
  }

  public static calculateCookieMaxAge(
    sessionModifiedDate: string,
    cookieOriginalMaxAge: number = COOKIE_ORIGINAL_MAX_AGE,
  ) {
    const sessionModifiedEpoch = Date.parse(sessionModifiedDate);
    const sessionDeadlineEpoch = sessionModifiedEpoch + cookieOriginalMaxAge;
    const cookieMaxAge = sessionDeadlineEpoch - Date.now();

    poutvar({ sessionModifiedDate, sessionDeadlineEpoch, cookieMaxAge });

    return cookieMaxAge;
  }
}

export default (async () =>
  expressSession({
    cookie: {
      httpOnly: true,
      maxAge: COOKIE_ORIGINAL_MAX_AGE,
      secure: false,
    },
    genid: ({ originalUrl }) => {
      const sid = uuid();

      pout(`Generated session identifier ${sid}; access to ${originalUrl}`);

      return sid;
    },
    name: cname('sid'),
    resave: false,
    saveUninitialized: false,
    secret: await getSessionSecret(),
    store: new SessionStore(),
  }))();
