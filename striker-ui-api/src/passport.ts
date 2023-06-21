import passport from 'passport';
import { Strategy as LocalStrategy } from 'passport-local';

import { DELETED } from './lib/consts';

import { query, sub } from './lib/accessModule';
import { sanitize } from './lib/sanitize';
import { stdout } from './lib/shell';

passport.use(
  'login',
  new LocalStrategy(async (username, password, done) => {
    stdout(`Attempting passport local strategy "login" for user [${username}]`);

    let rows: [
      userUuid: string,
      userName: string,
      userPasswordHash: string,
      userSalt: string,
      userAlgorithm: string,
      userHashCount: string,
    ][];

    try {
      rows = await query(
        `SELECT
          user_uuid,
          user_name,
          user_password_hash,
          user_salt,
          user_algorithm,
          user_hash_count
        FROM users
        WHERE user_algorithm != 'DELETED'
          AND user_name = '${username}'
        LIMIT 1;`,
      );
    } catch (queryError) {
      return done(queryError);
    }

    if (!rows.length) {
      return done(null, false);
    }

    const {
      0: [userUuid, , userPasswordHash, userSalt, userAlgorithm, userHashCount],
    } = rows;

    let encryptResult: {
      user_password_hash: string;
      user_salt: string;
      user_hash_count: number;
      user_algorithm: string;
    };

    try {
      [encryptResult] = await sub('encrypt_password', {
        params: [
          {
            algorithm: userAlgorithm,
            hash_count: userHashCount,
            password,
            salt: userSalt,
          },
        ],
        pre: ['Account'],
      });
    } catch (subError) {
      return done(subError);
    }

    const { user_password_hash: inputPasswordHash } = encryptResult;

    if (inputPasswordHash !== userPasswordHash) {
      return done(null, false);
    }

    const user: Express.User = {
      name: username,
      uuid: userUuid,
    };

    return done(null, user);
  }),
);

passport.serializeUser((user, done) => {
  const { name, uuid } = user;

  stdout(`Serialize user [${name}]`);

  return done(null, uuid);
});

passport.deserializeUser(async (id, done) => {
  const uuid = sanitize(id, 'string', { modifierType: 'sql' });

  stdout(`Deserialize user identified by ${uuid}`);

  let rows: [userName: string][];

  try {
    rows = await query(
      `SELECT user_name
        FROM users
        WHERE user_algorithm != '${DELETED}'
          AND user_uuid = '${uuid}';`,
    );
  } catch (error) {
    return done(error);
  }

  if (!rows.length) {
    return done(null, false);
  }

  const {
    0: [userName],
  } = rows;

  const user: Express.User = { name: userName, uuid };

  return done(null, user);
});

export default passport;
